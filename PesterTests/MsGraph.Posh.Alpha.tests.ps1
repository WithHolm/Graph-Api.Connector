
$CredentialsFile = "AzureCred.xml"
$modulename = 'MSGraph.Posh.Alpha'
$ModuleRootFolder = "$(split-path $PSScriptRoot)\$modulename"
get-module $modulename | Remove-Module -Force

Describe "Module Startup"{
    Context "First time"{
        #Remove config file for test
        get-item "$ModuleRootFolder\config.json" -ErrorAction SilentlyContinue| remove-item -force -ErrorAction SilentlyContinue

        it "Test that Config.json is gone before we start test"{
            {get-item "$ModuleRootFolder\config.json" -ErrorAction Stop}|should throw
        }

        it "Creates new config.json"{
            import-module "$ModuleRootFolder\$modulename.psd1" -Force
            {get-item "$ModuleRootFolder\config.json" -ErrorAction Stop}|should not throw
        }

        it "Creates new config.json"{
            import-module "$ModuleRootFolder\$modulename.psd1" -Force
            {get-item "$ModuleRootFolder\config.json" -ErrorAction Stop}|should not throw
        }
    }
}

get-module $modulename | Remove-Module -Force
import-module (join-path $ModuleRootFolder "$modulename.psd1") -Force

InModuleScope $modulename{
    foreach($folder in (get-childitem $psscriptroot -Directory))
    {
        Describe "Testing $($folder.name)"{
            get-childitem $folder.fullname -filter "*.Tests.ps1"|%{. $_.FullName}
            #Invoke-Pester $folder.fullname -Tag $folder.name
        } 
    }
}