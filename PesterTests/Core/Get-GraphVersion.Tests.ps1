InModuleScope $Global:modulename{
    Describe "Get-GraphVersion" -Tag "Core"{
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
}