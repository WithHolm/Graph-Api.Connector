InModuleScope $Global:modulename{
    Describe "Set-GraphVersion. All tests with -version to be noninteractive" -Tag "Core"{
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
}