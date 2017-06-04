
$CredentialsFile = "AzureCred.xml"
$modulename = 'Graphapi.beta'
$ModuleRootFolder = $(split-path $PSScriptRoot)
get-module $modulename | Remove-Module -Force

Describe "Module Startup"{
    Context "First time"{
        #Remove config file for test
        get-item "$ModuleRootFolder\config.json" -ErrorAction SilentlyContinue| remove-item -force -ErrorAction SilentlyContinue

        it "Test that Config.json is gone"{
            {get-item "$ModuleRootFolder\config.json" -ErrorAction Stop}|should throw
        }

        it "Creates new config.json"{
            import-module "$(split-path $PSScriptRoot)\graphapi.beta.psd1" -Force
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
    Describe "Get-GraphVersion"{
        Context "Without Switches"{
            it "returns string"{
                get-graphversion|should beoftype [String]
            }

            it "Returns what is active by default"{
                get-graphversion|should be $Script:GraphVersion
            }
        }

        Context "-selectall" {
            it "Should return a PsCustomObject"{
                get-graphversion -ShowAll | should beoftype [PsCustomObject]
            }

            it "Should return 3 fields"{
                (get-graphversion -ShowAll|gm|where{$_.membertype -eq "Noteproperty"}).count | should be 3
            }

            it "return.Active should be $script:graphversion"{
                (get-graphversion -ShowAll).active | should be $script:graphversion
            }

            it "return.Persistent should be whatever is in the config"{
                #Get Config value
                $Config = get-GraphAPIConfigFile
                (get-graphversion -ShowAll).Persistent | should be $config.GraphVersion.Selected
            }

            it "return.avalible should return a array"{
                ,(get-graphversion -ShowAll).Avalible | should beoftype [array]
            }

            it "return.avalible should return whatever array is in the config"{
                #Get Config value
                $Config = get-GraphAPIConfigFile
                (get-graphversion -ShowAll).Avalible | should be $Config.GraphVersion.Avalible
            }
        }
    }

    Describe "Set-GraphVersion. All tests with -version to be noninteractive"{

        #Get av version, not active
        $oldversion = (get-GraphAPIConfigFile).GraphVersion.selected
        $TestVersion = (get-GraphAPIConfigFile).GraphVersion.avalible|where{$_ -ne (Get-GraphAPIConfigFile).GraphVersion.Selected}|select -first 1
        Context "No switches. TestVersion: '$testversion'"{
            it 'Should set $script:GraphVersion'{
                set-GraphVersion -Version $TestVersion
                $Script:GraphVersion | should be $TestVersion 
            }

            it "Should throw if given the wrong version"{
                {set-graphversion -Version 'Wrong'}|should throw
            }

            it "Should not define the config value"{
                set-GraphVersion -Version $TestVersion
                (get-GraphAPIConfigFile).GraphVersion.Selected | should not be $TestVersion
            }
        }

        Context "-Persist TestVersion: '$testversion'"{
            it "Should define the config version"{
                set-GraphVersion -Version $TestVersion -Persist
                (get-GraphAPIConfigFile).GraphVersion.Selected | should be $TestVersion
            }

            set-graphversion -Version $oldversion
        }
    }

    Describe "Connect-GraphAPI. Always using pscredentials"{
        $CredPath = (join-path $PSScriptRoot $CredentialsFile) 
        if(!(test-path $CredPath))
        {
            $cred = Get-Credential -Message "Azure AD Admin User"
            $cred | export-clixml -Path $CredPath
        }
        $cred = import-clixml $CredPath

        Context "-Credentials"{
            it "Should not throw"{
                {Connect-GraphAPI -Credentials $cred}|should not throw
            }

            it "Should throw if wrong credentials are provided"{
                $secpasswd = ConvertTo-SecureString '“PlainTextPassword”' -AsPlainText -Force
                $wrongcred = New-Object System.Management.Automation.PSCredential ('Notauser@whatevercompany.com', $secpasswd)
                {Connect-GraphAPI -Credentials $wrongcred}|should throw
            }

            it "Should return array"{
                ,(Connect-GraphAPI -Credentials $cred)|should beoftype [array]
            }

            it "Can Create a new token"{
                {$endpoint = [Microsoft.Open.Azure.AD.CommonLibrary.AzureEnvironment+Endpoint]::MsGraphEndpointResourceId
                [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::GetAccessToken($endpoint)}|should not throw
            }
            
        }
    }

    Describe "Invoke-GraphCall"
    {
        Context "Normal Operation"{
            invoke-graphcall 
        }
    }
}