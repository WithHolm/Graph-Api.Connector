#region Script variables
#Token Documentation: https://msdn.microsoft.com/en-us/library/microsoft.identitymodel.clients.activedirectory.authenticationresult.aspx
if($Script:_token -eq $null)
{
    New-Variable _token -Scope script -Value $null -Force
}

#Static. Could be changed to use some other webapp, but shouldn't
$Script:_ClientID = "1950a258-227b-4e31-a9cf-717495945fc2" 

#Used when calling the ADAL authentication
$Script:_RedirectUri = "urn:ietf:wg:oauth:2.0:oob"

#Where to Call to get data. Can be: 'https://graph.microsoft.com','https://graph.windows.net','https://graph.chinacloudapi.cn/'
#$Script:_RecAppIdURI = "https://graph.microsoft.com"
$Script:_RecAppIdURI = "https://graph.microsoft.com"


#Use Azure module ADAL DLL's for authentication or download its own ADAL DLL's in runtime? If you set this to true, you can run this in Azure Automation
$Script:_UseAzureModule = $false
#endregion

#region ADAL Function 
Function Find-AndLoadAdalDll
{
    $AdalFormsDLLName = "Microsoft.IdentityModel.Clients.ActiveDirectory.WindowsForms.dll"
    $AdalDLLName = "Microsoft.IdentityModel.Clients.ActiveDirectory.dll"

    if($Script:_UseAzureModule)
    {
        #Get Azure Module path
        $AzurePath = split-path (get-module -ListAvailable Azure|select -First 1).path -Parent
        if([String]::IsNullOrEmpty($AzurePath))
        {
            Throw "The Azure Module is not avalible. Please make sure this is installed. If you are running this as a Azure Automation, go to the modules gallery on the Automation account to install azure account"
        }

        #Get First instance if ADAL DLLs
        $ADAL_Assembly = (get-childitem -Recurse -Path $AzurePath -Filter $AdalDLLName | select -First 1).fullname
        $ADAL_WindowsForms_Assembly = (get-childitem -Recurse -Path $AzurePath -Filter $AdalFormsDLLName | select -First 1).fullname        
    }
    else
    {
        #Create fullpath string for nugets in local Powershell folder
        $BasePath = (join-path $([Environment]::GetFolderPath("MyDocuments")) "WindowsPowerShell\Modules\AADGraph")
        $NugetPath = join-path $BasePath "Nugets"

        if(-not (test-path $NugetPath)) 
        {
            New-Item -Path $NugetPath -ItemType "Directory" | out-null
        }

        #
        $adalPackageDirectories = (Get-ChildItem -Path $NugetPath -Filter "Microsoft.IdentityModel.Clients.ActiveDirectory*" -Directory | select -Last 1)

        if($adalPackageDirectories -eq $null)
        {       
            #No ADAL dlls was found. downloading them
            Write-Warning "Active Directory Authentication Library Nuget doesn't exist. Downloading now ..."
            if(-not(Test-Path ($NugetPath + "\nuget.exe")))
            {
                Write-Warning "nuget.exe not found. Downloading from http://www.nuget.org/nuget.exe ..."
                $wc = New-Object System.Net.WebClient
                $wc.DownloadFile("http://www.nuget.org/nuget.exe",$NugetPath+"\nuget.exe");
            }

            #Set Nuget to selfUpdate and install ADAL dlls
            Invoke-Expression $($NugetPath+"\nuget.exe update -self")
            Invoke-Expression $($NugetPath+"\nuget.exe install Microsoft.IdentityModel.Clients.ActiveDirectory -Version 2.14.201151115 -OutputDirectory " + $NugetPath + " | out-null")
        }

        #Get First instance if ADAL DLLs
        $ADAL_Assembly = (Get-ChildItem $AdalDLLName -Path $NugetPath -Recurse|select -First 1).fullname
        $ADAL_WindowsForms_Assembly = (Get-ChildItem $AdalFormsDLLName  -Path $NugetPath -Recurse|select -First 1).fullname
    }


    if($ADAL_Assembly -ne $null -and $ADAL_WindowsForms_Assembly -ne $null)
    {        
        Write-Verbose "Loading ADAL Assemblies ..."
        [System.Reflection.Assembly]::LoadFrom($ADAL_Assembly) | out-null
        [System.Reflection.Assembly]::LoadFrom($ADAL_WindowsForms_Assembly) | out-null            
        return $true
    }
    else
    {
        Write-warning "ADAL_Assembly:'$ADAL_Assembly'"
        Write-warning "ADAL_WindowsForms_Assembly:'$ADAL_WindowsForms_Assembly'" 
        Throw ("Not able to load ADAL assembly...")
        return $false
    }
}
#endregion

#region Connect to Graph and handle tokenstuffs
function Connect-AzureGraph
{
        [CmdletBinding(DefaultParameterSetName="All")]
        param
        (
            [Parameter(
                ParameterSetName='UserCredentials')]
                    [PSCredential]$Credentials,

            [Parameter(
                ParameterSetName='CertificateThumbprint')]
                    [String]$CertificateThumbprint,
            [Parameter(
                ParameterSetName='CertificateThumbprint')]
                    [String]$ApplicationId,
            [Parameter(
                ParameterSetName='CertificateThumbprint')]
                    [String]$TenantId            
        )

        #CertificateThumbprint+AppID+TenantID
        if(Find-AndLoadAdalDll)
        #Loads the Correct dlls. returns false if it failed on loading
        {      
            Write-verbose "Connecting to endpoint '$script:_RecAppIdURI' using '$($PsCmdlet.ParameterSetName)'"  
            $authority = "https://login.windows.net/common"
            $authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authority,$false)   
            #[Microsoft.IdentityModel.Clients.ActiveDirectory.
            if($PsCmdlet.ParameterSetName -eq "UserCredentials")
            {
                #$authority = "https://login.windows.net/$($Credentials.UserName.Split('@')[-1])"
                #$authContext = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authority)
                $AADCred = [Microsoft.IdentityModel.Clients.ActiveDirectory.UserCredential]::new($Credentials.UserName,$Credentials.Password)
                $authResult = $authContext.AcquireToken($Script:_RecAppIdURI, $Script:_ClientID , $AADCred)
                $Script:_token = $authResult
                Write-verbose "Connected to graph as '$($Script:_token.UserInfo.DisplayableId)'"
            }
            elseif($PsCmdlet.ParameterSetName -eq "CertificateThumbprint")
            {
                #https://msdn.microsoft.com/en-us/library/mt459145.aspx
                #[Microsoft.IdentityModel.Clients.ActiveDirectory.ClientAssertionCertificate]::new(
                #$authContext.AcquireToken(
            }
            else
            {
                try
                {
                    $authResult = $authContext.AcquireToken($Script:_RecAppIdURI, $Script:_ClientID , $Script:_RedirectUri,[Microsoft.IdentityModel.Clients.ActiveDirectory.PromptBehavior]::Always)                
                    $Script:_token = $authResult
                    Write-verbose "Connected to graph as '$($Script:_token.UserInfo.DisplayableId)'"
                }
                catch
                {
                    Write-error "The user cancelled: $_"
                }
            }          
        }
}

Function Invoke-GraphRefreshToken
{
    $authority = "https://login.windows.net/$(($Script:_token.UserInfo.DisplayableId).Split('@')[-1])"
    $Authentication = [Microsoft.IdentityModel.Clients.ActiveDirectory.AuthenticationContext]::new($authority)
    $script:_token = $Authentication.AcquireTokenByRefreshToken($Script:_token.RefreshToken,$Script:_ClientID)
}

Function Test-GraphToken
{
    if($Script:_token -ne $null)
    {
        return $true
    }
    else
    {
        return $false
    }
}

Function Test-GraphTokenValidity
{
    if(!(Test-GraphToken))
    {
        Throw "I cannot find a token to log you in to Graph. Please use 'Connect-AzureGraph' to continue"
    }
    else
    {       
        if($Script:_token.ExpiresOn.UtcDateTime -gt [datetime]::UtcNow)
        #If the token expiration is older than now
        {
            #Token works as is. no need to ask for new token.
            return $true
        }
        else
        {
            #New token needs to be asked for
            return $false
        }
    }
}
#endregion

#region CallHelpers
Function Join-URI
{
    [cmdletbinding()]
    param(
    [String]$Parent,
    [String]$child
    )

    if($Parent.EndsWith('/'))
    {
        $Parent = $Parent.Substring(0,$Parent.Length-1)
    }
    if($child.StartsWith('/'))
    {
        $child = $Parent.Substring(1,$Parent.Length-1)
    }
    $Return = [String]::Format("{0}/{1}",$Parent,$child)
    write-verbose "returning '$return'"
    $return
}

Function Invoke-GraphCall
{
    [cmdletbinding()]
    param(
        [String]$Call 
    )
    if(!(Test-GraphTokenValidity))
    {
        Invoke-GraphRefreshToken
    }

    $authHeader = @{
        'Content-Type'='application\json'
        'Authorization'=$script:_token.CreateAuthorizationHeader()
    }

    $CallURI = Join-URI -Parent $Script:_RecAppIdURI -child $Call

    $return = Invoke-RestMethod -Method Get -Uri $CallURI -Headers $authHeader
    if($return.value -eq $null)
    {
        return $return
    }
    else
    {
        return $return.value
    }
}
#endregion

Function Get-GraphMe
{
    [cmdletbinding()]
    param()
    $APIVersion = "v1.0"
    $APICall = "me"

    #You dont need the baseurl, So "https://graph.microsoft.com/v1.0/me" would only be "v1.0/me"
    Invoke-GraphCall -Call "$APIVersion/$apicall"
}

<#
//Todo. Support Azure Automation For real. CertificateThumbprint+AppID+TenantID

1. Start by doing Connect-AzureGraph (-Credentials is optional)
2. Invoke-GraphCall -call "v1.0/users"
Invoke-GraphCall -call "v1.0/users"
#>
