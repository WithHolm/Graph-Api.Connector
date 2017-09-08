
Function Connect-GraphAPI
{
    [CmdletBinding(DefaultParameterSetName="All")]
    param
    (
        [Parameter(ParameterSetName='UserCredentials')]
                [PSCredential]$Credentials,

        [Parameter(Mandatory = $true, ParameterSetName='CertificateThumbprint')]
                [String]$CertificateThumbprint,

        [Parameter(Mandatory = $true, ParameterSetName='CertificateThumbprint')]
                [String]$ApplicationId,
        
        [Parameter(Mandatory = $false, ParameterSetName='all')]
        [Parameter(Mandatory = $false, ParameterSetName='UserCredentials')]
        [Parameter(Mandatory = $true, ParameterSetName='CertificateThumbprint')]
                [String]$TenantId
    )

    ##LOAD DLL
    $AADCommonDLLName = "Microsoft.Open.Azure.AD.CommonLibrary.dll"

    #Get Azure Module path
    $AzurePath = split-path (get-module -ListAvailable Azuread|select -First 1).path -Parent
    if([String]::IsNullOrEmpty($AzurePath))
    {
        Throw "The Azure Module is not avalible. Please make sure this is installed. If you are running this as a Azure Automation, go to the modules gallery on the Automation account to install azure account"
    }

    #Get First instance of ADAL DLLs
    $AAD_common_Assembly = (get-childitem -Recurse -Path $AzurePath -Filter $AADCommonDLLName | select -First 1).fullname
    $ADAL_Assembly = (get-childitem -Recurse -Path $AzurePath -Filter $AdalDLLName | select -First 1).fullname
    $ADAL_WindowsForms_Assembly = (get-childitem -Recurse -Path $AzurePath -Filter $AdalFormsDLLName | select -First 1).fullname
    write-host "$AAD_common_Assembly"
    [System.Reflection.Assembly]::LoadFrom($AAD_common_Assembly) | out-null    


    ##INIT ENVIORMENT
    #Get Default Enviorment name. Will provide a Way to change This later on to support Goverments, PPE, Germany and China
    $AzureEnviormentName = ([Microsoft.Open.Azure.AD.CommonLibrary.AzureEnvironment]::new()).Name

    #Loads in the enviormant by name if it is avalible in azure RM profiling service (basially builds up all endpoints you need to login and so forth)
    if([Microsoft.Open.Azure.AD.CommonLibrary.AzureRmProfileProvider]::Instance.Profile.Environments.ContainsKey($AzureEnviormentName))
    {
        #Gets all Porfileinfo you need to connect to 
        $AzureEnviorment = [Microsoft.Open.Azure.AD.CommonLibrary.AzureRmProfileProvider]::Instance.Profile.Environments[$AzureEnviormentName]
        $Script:_AzureEnviorment = $AzureEnviorment
        #Removes all current tokens++ if its already loded in the current PS session
        [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::NewSessionstate()
        #Builds up the new enviorment
        [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AzureEnvironment = $AzureEnviorment
    }
    else
    {
        Throw "Could not find the environment '$AzureEnviormentName' in the AzureRMProfile environment list"
    }


    ##PROCESSING
    $azureaccount = [Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount]::new()
    [System.Security.SecureString]$password = [System.Security.SecureString]$null
    if($PsCmdlet.ParameterSetName -eq "UserCredentials")
    {
        $azureaccount.Id = $Credentials.UserName
        $password = $Credentials.Password
        $azureaccount.Type = [Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount+AccountType]::User
    }
    elseif($PsCmdlet.ParameterSetName -eq "CertificateThumbprint")
    {
        $azureaccount.Type = [Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount+AccountType]::ServicePrincipal
        $azureaccount.id = $ApplicationId
        $azureaccount.SetProperty([Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount+property]::CertificateThumbprint,$CertificateThumbprint)
    }
    else
    {
        $azureaccount.Type = [Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount+AccountType]::User
    }

    if([Microsoft.Open.Azure.AD.CommonLibrary.AzureRmProfileProvider]::Instance.Profile -eq $null)
    {
        [Microsoft.Open.Azure.AD.CommonLibrary.AzureRmProfileProvider]::Instance.Profile = [Microsoft.Open.Azure.AD.CommonLibrary.RMProfileClient]::new()
    }
    
    $AzureRMProfile = `
                [Microsoft.Open.Azure.AD.CommonLibrary.RMProfileClient]::new([Microsoft.Open.Azure.AD.CommonLibrary.AzureRmProfileProvider]::Instance.Profile)
    try
    {
        $return = $AzureRMProfile.Login($azureaccount,$AzureEnviorment,$TenantId,$password)
        [Microsoft.Open.Azure.AD.CommonLibrary.PSAzureContext]$return.context
        Write-verbose "Logged in. Account: '$($return.context.Account.Id)', environment: '$($return.context.Environment.Name)', tenant: '$($return.context.Tenant.Id)', domian name: '$($return.context.Tenant.Domain)'"
        $return
    }
    catch
    {
        throw $_
    }
}

Function Disconnect-GraphAPI
{

    try
    {
        [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::ClearSessionState()
        write-verbose "Cleared Azure Sessionstate"
    }
    catch
    {
        Write-error "Could not disconnect graph: $_"
    }

}

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

Function Call-GraphAPI
{
    [cmdletbinding()]
    param(
        [String]$Version = "v1.0",
        [String]$Call,
        [String]$filter
    )

    #Test Version
    if($Version -notlike "beta")
    {
        try
        {
            $pattern = '[a-zA-Z]'
            $version = $($version -replace $pattern, ' ').Trim().Replace('.',',')
            $temp = [double]::Parse($Version)
            $Version = $('{0:N1}' -f $temp).Replace(',','.')
            $Version = "v$version"
        }
        catch
        {
            Throw "There was an error reading the -Version format: $_"
        }
    }
    else
    {
        $Version = $Version.ToLower()
    }
    
    $query = join-uri -Parent $Version -child $Call

    #If filter is defined
    if(![String]::IsNullOrEmpty($filter))
    {
        $filter = '?$filter='+$filter
        $query = "$query$filter"
    }

    Write-verbose "Query: $query"

    $endpoint = [Microsoft.Open.Azure.AD.CommonLibrary.AzureEnvironment+Endpoint]::MsGraphEndpointResourceId
    $resource = [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AzureEnvironment.GetResource($endpoint)
    [Microsoft.Open.Azure.AD.CommonLibrary.IAccessToken]$Accesstoken = [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::GetAccessToken($endpoint)
    $Auth = $Accesstoken.AuthorizeRequest($endpoint)
    $TenantID = $Accesstoken.TenantId
    
    

    $CallURI = Join-URI -Parent $resource -child $query
    
    $authHeader = @{
        'Content-Type'='application\json'
        'Authorization'=$Auth
    }
    
    try
    {
        $return = Invoke-RestMethod -Method Get -Uri $CallURI -Headers $authHeader
        if($return.value -eq $null)
        {
            return $return
        }
        return $return.value
    }
    catch 
    {
        $response = $_.Exception.Response.StatusCode.value__
        $reponsestring = $_.Exception.Response.StatusCode
        switch ($response)
        {
            404{Write-error "The query '$query' cannot be found at '$resource': $_"}
            default{write-error "error with '$CallURI': $reponsestring ($response)"}
        }
    }
}

#https://graph.windows.net/myorganization/users/user@contoso.com/manager
#Call-GraphAPI -Version 1 -Call "users/assignedlicences" -Verbose -ErrorAction Stop #-filter "emailAddresses/any(a:a/address eq '@crayon.com')"
#$users = Call-GraphAPI -Version beta -Call "users"
#
#foreach ($user in $users)
#{
#    #$($user.userPrincipalName)
#    Call-GraphAPI -Version beta -Call "users/$($user.userPrincipalName)/ownedDevices"
#    #if($user.manager -ne "")
#    #{
#    #Call-GraphAPI -Version 1 -Call "users/$Currentuser/Manager"
#    #}
#}