InModuleScope $Global:modulename{
    Describe "Join-URI" -Tag "Core" {
        Context "Normal Operation"{
            it "returns correct returnstring"{
                join-uri -Parent 1 -child 2 | should be "1/2"
            }

            it "returns correct returnstring when child starts with '/'"{
                join-uri -Parent 1 -child "/2" | should be "1/2"
            }

            it "returns correct returnstring when parent ends with '/'"{
                join-uri -Parent "1/" -child "2" | should be "1/2"
            }

            it "returns correct returnstring when parent and child ends and starts with '/'"{
                join-uri -Parent "1/" -child "/2" | should be "1/2"
            }

            it "can be called on without defined parameters"{
                join-uri 1 2 | should be "1/2"
            }
        }
        Context "ErrorHandling"{
            it "Should throw when it only have one param"{
                {join-uri -Parent 1} | should throw
            }

        }

    }
}