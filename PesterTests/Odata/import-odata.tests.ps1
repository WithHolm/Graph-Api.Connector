inmodulescope $Global:modulename{

    Describe "Normal operations"{
        $script:odata = $null
        it "Pretest: Odata sould be empty"{
            $script:odata | should be $null
        }

        it "Should fill script:odata"{
            import-odata
            $script:odata|should not be $null
        }

        it "Should have the same amount of childitems as there is api versions"{
            $script:odata.count|should be ($config.graphversion.avalible).count
        }
    }

    Describe "Caching"{
        $config = get-GraphAPIConfigFile
        $CacheFolder = join-path $global:modulerootfolder $config.odata.Cache.CacheFolder
        $CacheTemplate = $config.Odata.Cache.Odataxml

        Mock get-GraphAPIConfigFile {
            $config = (get-content $Script:GraphAPIConfigFile -raw | convertfrom-json)
            $config.Odata.Cache.Active = $true
            return $config
        }

        $config.graphversion.avalible|%{remove-item (join-path $CacheFolder $($CacheTemplate -f $_)) -ErrorAction SilentlyContinue}
        it "Precheck: Chachefolder should not have the odata xml files in it"{
            $cachefiles = $config.graphversion.avalible|%{get-childitem -path $CacheFolder -Filter $($CacheTemplate -f $_)}
            @($cachefiles).count|should be 0
        }
        It "Should Create CacheFiles when config.cache is enabled"{
            Import-Odata
            $cachefiles = $config.graphversion.avalible|%{get-childitem -path $CacheFolder -Filter $($CacheTemplate -f $_)}
            @($cachefiles).count|should be ($config.graphversion.avalible).count
        }

    }
}