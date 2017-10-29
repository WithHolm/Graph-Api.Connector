InModuleScope $Global:modulename{
    Describe "Get-GraphVersion" -Tag "Core"{
        Context "Without Switches"{
            it "returns psobject"{
                get-graphversion|should beoftype [pscustomobject]
            }

            it "Returns active correctly"{
                (get-graphversion).active|should be $Script:GraphVersion
            }

            it "Returns persistent correctly"{
                (get-graphversion).persistent|should be (Get-GraphAPIConfigFile).graphversion.Selected
            }

            it "Returns avalible correctly"{
                (get-graphversion).persistent|should be (Get-GraphAPIConfigFile).graphversion.Avalible
            }
        }
    }
}