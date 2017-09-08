InModuleScope $Global:modulename{
    Describe "Import-OdataRegistry. Creates a more nimble version of script:odata" -Tag "Odata","Integration"{
        
        #Imports odata from file or internet to $script:odata.
        import-odata
        context "Normal Operation"{
            $config = get-GraphAPIConfigFile
         
            Import-OdataRegistry
            it "script:Odata_registry should have the correct amount of main properties (2:beta+v1.0)"{               
                @((Get-OdataRegistry)|gm|where{$_.membertype -eq "Noteproperty"}).count|should be ($config.graphversion.avalible).count
            }

            foreach($version in ($config.graphversion.avalible))
            {
                describe $version{
                    import-odata
                    $odata = get-odata $version
                    it "script:Odata_registry.$version Should have 2 sub properties"{
                        ((Get-OdataRegistry).$version|gm|where{$_.membertype -eq "Noteproperty"}).count|should be 2
                    }

                    it "script:Odata_registry.$($version).odataregistry should have all odata entitysets"{
                        ((Get-OdataRegistry).$version.odataregistry).count | should be $odata.entitycontainer.entityset.count
                    }

                    # it "script:Odata_registry.$($version).expands Should have all expandable objects in it"{
                    #     $answer = $((get-odata $version).entitycontainer.entityset|where{$_.NavigationPropertyBinding -ne $null}).count
                    #     ((get-odataregistry).$version.expands|gm|where{$_.membertype -eq "noteproperty"}).count | should be $answer
                    # }

                    describe "Test 3 random objects from $version odataregistry"{
                        for($i=0; $i -lt 3;$i++)
                        {
                            $entityset = (get-odata $version).entitycontainer.entityset|get-random
                            $entityname = $($entityset.entitytype.split('.')[-1])
                            $entityobject = $odata.entitytype|Where-Object{$_.name -eq $entityname}
                            $originodata = [pscustomobject]@{
                                                            OdataName = $($entityset.name)
                                                            Entityname = $entityname
                                                            EntityFQN = $entityset.entitytype
                                                        }
                            $odatareg = (get-odataregistry).beta.odataregistry|where{$_.OdataName -eq $entityset.name}
                            # write-host ($($originodata|gm|where{$_.membertype -eq "noteproperty"}).Name)
                            foreach($testing in ($($originodata|gm|where{$_.membertype -eq "noteproperty"}).Name))
                            {
                                it "$($entityname): $testing is the same"{
                                    $originodata.$testing | should be $odatareg.$testing
                                }
                            }
                        }
                    }
                }
            }

            Mock get-GraphAPIConfigFile {
                $config = (get-content $Script:GraphAPIConfigFile -raw | convertfrom-json)
                $config.Odata.Cache.Active = $false
                return $config
            }

            it "Should throw when script:odata is empty"{
                $script:odata = $null
                {Import-OdataRegistry}|should throw
            }

        }


        context "Caching"{
            #Set CahceFolder
            import-odata
            $config = get-GraphAPIConfigFile
            #$CacheFolder = join-path $global:modulerootfolder "cache"
            $CacheFolder = join-path $global:modulerootfolder $config.odata.Cache.CacheFolder
            $CacheTemplate = $config.Odata.Cache.ExpandCache
            Mock get-GraphAPIConfigFile {
                $config = (get-content $Script:GraphAPIConfigFile -raw | convertfrom-json)
                $config.Odata.Cache.Active = $true
                return $config
            }

            #Remove Cahcefiles if present
            #write-host $CacheFolder
            $config.graphversion.avalible|%{remove-item (join-path $CacheFolder $($CacheTemplate -f $_)) -ErrorAction SilentlyContinue}

            it "Precheck: Chachefolder should not have expandtype files in it"{
                $cachefiles = $config.graphversion.avalible|%{get-childitem -path $CacheFolder -Filter $($CacheTemplate -f $_)}
                @($cachefiles).count|should be 0
            }


            It "Should Create CacheFiles when config.cache is enabled"{
                Import-OdataRegistry
                $cachefiles = $config.graphversion.avalible|%{get-childitem -path $CacheFolder -Filter $($CacheTemplate -f $_)}
                @($cachefiles).count|should be ($config.graphversion.avalible).count
            }
        }

        context "Get-OdataRegistry"{
            import-odata
            import-odataregistry
            it "Will return the script:odataregistry"{
                Get-OdataRegistry | should be $script:Odata_registry
            }
        }
    }
}