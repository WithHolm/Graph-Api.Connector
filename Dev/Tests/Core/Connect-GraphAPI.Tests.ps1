InModuleScope $Global:modulename{
    Describe "Connect-GraphAPI. Always using pscredentials" -Tag "Core"{
        $cred = $Global:PesterTestCred
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
                ,(Connect-GraphAPI -Credentials $cred)|should beoftype [Microsoft.Open.Azure.AD.CommonLibrary.PSAzureContext]
            }

            it "Can Create a new token"{
                {$endpoint = [Microsoft.Open.Azure.AD.CommonLibrary.AzureEnvironment+Endpoint]::MsGraphEndpointResourceId
                [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::GetAccessToken($endpoint)}|should not throw
            }
            
        }
    }
}