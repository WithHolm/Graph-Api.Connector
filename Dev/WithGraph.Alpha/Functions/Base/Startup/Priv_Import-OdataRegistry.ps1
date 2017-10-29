Function Import-OdataRegistry
{
    [cmdletbinding()]
    param()
    $script:Odata_registry = $null
    $script:Odata_registry = new-object pscustomobject

    Write-verbose "Creating typedata sets with odata."
    $config = Get-GraphAPIConfigFile

    $OdataFileTemplate = "$script:GraphCacheRoot\$($config.Odata.Cache.ExpandCache)"

    foreach($version in (Get-GraphVersion).avalible)
    {       
        $OdataFile = $($OdataFileTemplate -f $version)
        if($config.Odata.Cache.Active -and (test-path $OdataFile))
        {
            write-verbose "Importing $version OdataReg directly from file"
            $OdataReg = get-content -raw $OdataFile|convertfrom-json
            #$script:Odata_registry|add-member -MemberType NoteProperty -Name $version -Value $OdataReg -Force # += [pscustomobject]@{$version = $OdataReg}
        }
        else
        {
            write-verbose "----Processing OdataReg for version $version"
            $odata = get-odata $version
            if($odata -eq $null)
            {
                throw "Could not create odata registry as script:odata is not filled. please use the command 'import-odata' to fix this"
            }
            $OdataReg = [pscustomobject]@{}
            $Expands = [pscustomobject]@{}

            $odataConverter = New-Object System.Collections.ArrayList

            #Foreach entitymember 
            foreach($entitymember in Get-GraphEndpoints -version $version)
            {
                #Add to OdataRegistry (List of endpoints)
                if($entitymember.expands -ne $null)
                {
                    $Expands | add-member -MemberType NoteProperty -Name $entitymember.odataname -Value @($entitymember.Expands) -Force
                }
                $entitymember.psobject.Properties.Remove("Expands")
                $odataConverter.add($entitymember)|out-null        
            }

            $Graphobjects = New-Object System.Collections.ArrayList
            @('ComplexType','EntityType','EnumType').foreach{
                Write-verbose $_
                ($odata.$_.GetEnumerator()).foreach{
                    if($_.basetype -ne $null)
                    {
                        # Write-verbose $_.BaseType
                        # Write-verbose (($_.BaseType.split(".")) -join ', ')
                        $Basetype = $_.BaseType.split(".")|select -last 1
                    }
                    else 
                    {
                        $Basetype = ""
                    }
                    [void]$Graphobjects.add(
                            [pscustomobject]@{
                                Name = $_.name
                                DependsOn = $Basetype
                            }
                        )
                }
            }

            $OdataReg = [pscustomobject]@{
                                OdataRegistry = $odataConverter
                                expands = $Expands
                                Objects = $Graphobjects
                        }
            if($config.Odata.Cache.Active)
            {
                new-item $OdataFile -ItemType File -Force | out-null
                $OdataReg | convertto-json -depth 99|out-file $OdataFile
            }
        }
        Write-verbose "Adding $version to registry"
        $script:Odata_registry | add-member -MemberType NoteProperty -Name $version -Value $OdataReg -Force
    }
}

