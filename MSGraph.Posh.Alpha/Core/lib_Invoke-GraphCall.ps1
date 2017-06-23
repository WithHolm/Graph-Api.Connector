Function Invoke-GraphCall
{
    [cmdletbinding()]
    param(
        [String]$Version = (Get-GraphAPIConfigFile).GraphVersion.Selected,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Get", "Post")]
        [String]$Method,

        [Object]$Body,

        [Parameter(Mandatory=$true)]
        [String]$Call,

        [String]$filter,

        [String]$Expand,

        [Switch]$ReturnCallURL
    )

    $OdataTag = ""

    #Test Version
    #Write-Verbose "Version: $version"
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
    #testing if DLLs are loaded
    try
    {
        $endpoint = [Microsoft.Open.Azure.AD.CommonLibrary.AzureEnvironment+Endpoint]::MsGraphEndpointResourceId
        $resource = [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AzureEnvironment.GetResource($endpoint)
        [Microsoft.Open.Azure.AD.CommonLibrary.IAccessToken]$Accesstoken = [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::GetAccessToken($endpoint)
        $Auth = $Accesstoken.AuthorizeRequest($endpoint)
        $TenantID = $Accesstoken.TenantId
        if([String]::IsNullOrEmpty($auth))
        {
            Throw "The authkey was empty!"
        }
    }
    catch
    {
        throw "Unable to create authentication token. Have you logged on? Error: $_"
    }
    
    $CallURI = Join-URI -Parent $resource -child $query
    #$CallURI +='$select=passwordPolicies'
    if($ReturnCallURL)
    {
        return $CallURI
    }
    
    if($Method -eq "Get")
    {
        #Write-Verbose "Getting data from $calluri"
        $authHeader = @{
            'Content-Type'='application\json'
            'Authorization'=$Auth
        }
        
        try
        {
            $return = Invoke-RestMethod -Method Get -Uri $CallURI -Headers $authHeader
            $OdataTag = $($return."@odata.context")
            if($return.value -ne $null)
            {
                $return = $return.value
            }
        }
        catch 
        {
            $_.exeption
        }
    }
    if($Method -eq "Post")
    {
        #Write-Verbose "Posting data"
        $authHeader = @{
            'Content-Type' ='application\json'
            'Authorization'=$Auth
        }
        
        try
        {
            if($Body -ne $null)
            {
                Invoke-RestMethod -Method post -Uri $CallURI -Headers $authHeader -Body $Body
            }
            Invoke-RestMethod -Method post -Uri $CallURI -Headers $authHeader
            $OdataTag = $($return."@odata.context")
            if($return.value -ne $null)
            {
                $return = $return.value
            }
        }
        catch 
        {
            $_.exeption
        }
    }

    return $return|Add-OdataToReturn -odatatag $OdataTag
}