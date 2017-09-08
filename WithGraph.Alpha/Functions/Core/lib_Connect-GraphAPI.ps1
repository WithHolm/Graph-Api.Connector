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
    $AzurePath = split-path (get-module -ListAvailable Azuread|Select-Object -First 1).path -Parent
    if([String]::IsNullOrEmpty($AzurePath))
    {
        Throw "The Azure Module is not avalible. Please make sure this is installed. If you are running this as a Azure Automation, go to the modules gallery on the Automation account to install azure account"
    }

    #Get First instance of ADAL DLLs
    $AAD_common_Assembly = (get-childitem -Recurse -Path $AzurePath -Filter $AADCommonDLLName | Select-Object -First 1).fullname
    write-Verbose "Found '$AADCommonDLLName' at path '$AAD_common_Assembly'. Loading this."
    [System.Reflection.Assembly]::LoadFrom($AAD_common_Assembly) | out-null    


    ##INIT ENVIORMENT
    Write-verbose "Initialising new enviorment"
    #Get Default Enviorment name. Will provide a Way to change This later on to support Goverments, PPE, Germany and China
    $AzureEnviormentName = ([Microsoft.Open.Azure.AD.CommonLibrary.AzureEnvironment]::new()).Name

    #Loads in the enviormant by name if it is avalible in azure RM profiling service (basially builds up all endpoints you need to login and so forth)
    if([Microsoft.Open.Azure.AD.CommonLibrary.AzureRmProfileProvider]::Instance.Profile.Environments.ContainsKey($AzureEnviormentName))
    {
        #Gets all Porfileinfo you need to connect to 
        $AzureEnviorment = [Microsoft.Open.Azure.AD.CommonLibrary.AzureRmProfileProvider]::Instance.Profile.Environments[$AzureEnviormentName]
        $Script:_AzureEnviorment = $AzureEnviorment
        Write-verbose "Current Azure Enviorment: $script:_AzureEnviorment"
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
    Write-verbose "Creating new session-azureaccount"
    $azureaccount = [Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount]::new()
    [System.Security.SecureString]$password = [System.Security.SecureString]$null
    if($PsCmdlet.ParameterSetName -eq "UserCredentials")
    {
        $azureaccount.Id = $Credentials.UserName
        $password = $Credentials.Password
        $azureaccount.Type = [Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount+AccountType]::User
        Write-verbose "Logging in with ID:'$( $azureaccount.id)', Type:'$($azureaccount.Type)'"
    }
    elseif($PsCmdlet.ParameterSetName -eq "CertificateThumbprint")
    {
        $azureaccount.Type = [Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount+AccountType]::ServicePrincipal
        $azureaccount.id = $ApplicationId
        $azureaccount.SetProperty([Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount+property]::CertificateThumbprint,$CertificateThumbprint)
        Write-verbose "Logging in with ID:'$( $azureaccount.id)', Type:'$($azureaccount.Type)'"
    }
    else
    {
        if($Host.name -like "*Visual studio*")
        {
            Throw 'Cannot load adal window with vscode. please use -credentials $(get-credential) or cert thumbprint'
        }
        $azureaccount.Type = [Microsoft.Open.Azure.AD.CommonLibrary.AzureAccount+AccountType]::User
        Write-verbose "Logging in with ID:'$( $azureaccount.id)', Type:'$($azureaccount.Type)'"
    }

    if([Microsoft.Open.Azure.AD.CommonLibrary.AzureRmProfileProvider]::Instance.Profile -eq $null)
    {
        [Microsoft.Open.Azure.AD.CommonLibrary.AzureRmProfileProvider]::Instance.Profile = [Microsoft.Open.Azure.AD.CommonLibrary.RMProfileClient]::new()
    }
    
    write-verbose "Creating a new RMProfileClient"
    $AzureRMProfile = `
                [Microsoft.Open.Azure.AD.CommonLibrary.RMProfileClient]::new([Microsoft.Open.Azure.AD.CommonLibrary.AzureRmProfileProvider]::Instance.Profile)
    try
    {
        
        $return = $AzureRMProfile.Login($azureaccount,$AzureEnviorment,$TenantId,$password)
        [Microsoft.Open.Azure.AD.CommonLibrary.PSAzureContext]$return.context
        Write-verbose "Logged in. Account:'$($return.context.Account.Id)', Environment:'$($return.context.Environment.Name)', Tenant:'$($return.context.Tenant.Id)', domian name: '$($return.context.Tenant.Domain)'"
        #$return
    }
    catch
    {
        throw $_
    }
}
