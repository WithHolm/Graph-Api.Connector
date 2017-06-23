Function Import-OdataEntity
{
    [cmdletbinding()]
    param()
    Write-verbose "Creating typedata sets with odata."
    foreach($version in "beta")
    {
        Write-Verbose "$version"
        $odata = get-odata $version

        foreach($entityset in $odata.entitycontainer.entityset)
        {
            $entityname = $($entityset.entitytype.split('.')[-1])
            $entityobject = $odata.entitytype|Where-Object{$_.name -eq $entityname}
            write-verbose "name: $($entityset.name), Entitytype: $entityname"

            #Checks if the entityset has navigationproperties. Meaning the defined odata object has Expandable objects. writes this to the odata "registry"
            $entitynavigations = @(($odata.entitytype|Where-Object{$_.name -eq $entityname}).NavigationProperty)
            if($entitynavigations -ne $null)
            {
                Write-verbose "Added $($entitynavigations.count) navigations to internal registry"

                $script:Odata_ExpandableObjects += [pscustomobject]@{
                                                                        Name=$entityname
                                                                        Expandableprops=@($entitynavigations.name)
                                                                    }
            }            
        }
    }
    

}