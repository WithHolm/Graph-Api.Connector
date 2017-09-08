Describe "Module Startup"{
    Context "First time"{
        #Remove config file for test
        $configfile = "$ModuleRootFolder\config\config.json"
        get-item $configfile -ErrorAction SilentlyContinue| remove-item -force -ErrorAction SilentlyContinue

        it "Test that Config.json is gone before we start test"{
            {get-item $configfile -ErrorAction Stop}|should throw
        }

        it "Creates new config.json"{
            import-module "$ModuleRootFolder\$modulename.psd1" -Force
            {get-item $configfile -ErrorAction Stop}|should not throw
        }
    }
}