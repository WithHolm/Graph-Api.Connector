Function Import-OdataRegistry
{
    [cmdletbinding()]
    param()

    $script:Odata_registry = $null
    $script:Odata_registry = new-object pscustomobject

    Write-verbose "Creating typedata sets with odata."
    $config = Get-GraphAPIConfigFile

    $OdataFileTemplate = "$script:GraphCacheRoot\$($config.Odata.Cache.ExpandCache)"

    foreach($version in $config.graphversion.avalible)
    {       
        $OdataFile = $($OdataFileTemplate -f $version)
        if($config.Odata.Cache.Active -and (test-path $OdataFile))
        {
            write-verbose "Importing $version OdataReg directly from file"
            $OdataReg = get-content -raw $OdataFile|convertfrom-json
            $script:Odata_registry|add-member -MemberType NoteProperty -Name $version -Value $OdataReg -Force # += [pscustomobject]@{$version = $OdataReg}
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
            foreach($entityset in $odata.entitycontainer.entityset|sort-object name)
            {
                $entityname = $($entityset.entitytype.split('.')[-1])
                $entityobject = $odata.entitytype|Where-Object{$_.name -eq $entityname}
                write-verbose "name: $($entityset.name), Entitytype: $entityname"
                #Add OdataRegistry. converter from Odata to actual type
                $odataConverter.Add([pscustomobject]@{
                                                OdataName = $($entityset.name)
                                                Entityname = $entityname
                                                EntityFQN = $entityset.entitytype
                                            })|out-null
                #Checks if the entityset has navigationproperties. Meaning the defined odata object has Expandable objects. writes this to the odata "registry"
                $entitynavigations = @($entityobject.NavigationProperty)
                if($entitynavigations -ne $null)
                {               
                    Write-verbose "    Added $(@($entitynavigations).count) navigations to expand registry"
                    $Expands | add-member -MemberType NoteProperty -Name $entityname -Value @($entitynavigations.name) -Force
                }            
            }
            $OdataReg = [pscustomobject]@{
                                OdataRegistry = $odataConverter
                                expands = $Expands
                        }
            if($config.Odata.Cache.Active)
            {
                new-item $OdataFile -ItemType File -Force | out-null
                $OdataReg | convertto-json -depth 999|out-file $OdataFile
            }
        }
        Write-verbose "Adding $version to registry"
        
        $script:Odata_registry | add-member -MemberType NoteProperty -Name $version -Value $OdataReg -Force  # += [pscustomobject]@{$version = $OdataReg}
        #write-verbose ($script:Odata_registry|gm).count
    }
    



}