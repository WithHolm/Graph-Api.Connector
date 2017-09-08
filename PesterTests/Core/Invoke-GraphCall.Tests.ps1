InModuleScope $Global:modulename{
    Describe "Invoke-GraphCall" -Tag "Core"{
        Context "Normal Operation"{

            it "Should throw when method is wrong"{
                {invoke-graphcall -Call "test" -Method "Wrong"}|should throw
            }

            it "Should throw when i cant find the call"{
                {invoke-graphcall -Call "test" -Method "get" -ErrorAction Stop}|should throw
            }

            it "Standard call should return pscustomobject"{
                invoke-graphcall -Call "me" -Method "get"|should beoftype [PsCustomObject]
            }

            it "Can use config to get version (v1.0)"{
                set-graphversion -Version "v1.0"
                invoke-graphcall -Call "me" -Method "get" -ReturnCallURL |should belike "*Graph.Microsoft.com/v1.0/*"
            }

            it "Can use config to get version (beta)"{
                set-graphversion -Version "beta"
                invoke-graphcall -Call "me" -Method "get" -ReturnCallURL |should belike "*Graph.Microsoft.com/beta/*"
            }

            it "Manual version overrides the default value"{
                set-graphversion -Version "beta"
                invoke-graphcall -Call "me" -Method "get" -ReturnCallURL -Version "v1.0" |should belike "*Graph.Microsoft.com/v1.0/*"
            }

            it "Manual version fixes weird version input"{
                set-graphversion -Version "beta"
                invoke-graphcall -Call "me" -Method "get" -ReturnCallURL -Version "1" |should belike "*Graph.Microsoft.com/v1.0/*"
            }

            it "Adds a filter"{
                invoke-graphcall -Call "me" -Method "get" -ReturnCallURL -Version "v1.0" -filter "filter -eq true"|should belike '*$filter=filter -eq true'
            }

            it "Adds a filter. Accepts simple variables and converts it to string"{
                invoke-graphcall -Call "me" -Method "get" -ReturnCallURL -Version "v1.0" -filter "filter -eq $true"|should belike '*$filter=filter -eq true'
            }
            try
            {
                invoke-graphcall -Call "test" -Method "get" -ErrorAction Stop
            }
            catch 
            {
                
            }

        }

    }
}