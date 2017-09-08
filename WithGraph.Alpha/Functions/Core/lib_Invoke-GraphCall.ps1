Function Invoke-GraphCall
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$false)]
            [String]$Version,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Get", "Post")]
            [String]$Method,

        [Parameter(Mandatory=$false)]
            $Body,

        [Parameter(Mandatory=$true)]
            [String]$Call,

        [Parameter(Mandatory=$false)]
            [String]$filter,

        [Parameter(Mandatory=$false)]
            [String]$Expand,

        [Parameter(Mandatory=$false)]
            [Switch]$ReturnCallURL,

        [Parameter(Mandatory=$false)]
            [Switch]$async,

            [String]$baseURL
    )

    if([String]::IsNullOrEmpty($version))
    {
        $version = get-graphversion
    }
    $OdataTag = ""

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
        if($async)
        {
            Throw "Async is not supported with get request atm.."
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
            'Content-Type' ='application/json'
            'Authorization'=$Auth
        }
        
        try
        {
            if($async)
            {
                Write-verbose "Invoking async rest with body" 
                $return = start-job -ScriptBlock {param($URI,$Header,$body) Invoke-RestMethod -Method post -Uri $URI -Headers $Header -Body $Body} -ArgumentList $CallURI,$authHeader,$Body
            }
            else
            {
                if($Body -ne $null)
                {
                    Write-verbose "Invoking rest with body"                
                    $return = Invoke-RestMethod -Method post -Uri $CallURI -Headers $authHeader -Body $Body #-ContentType 'application/json'
                    #return $return
                }
                else
                {
                    Write-verbose "Invoking rest w/o body"
                    $return = Invoke-RestMethod -Method post -Uri $CallURI -Headers $authHeader
                }
            }

            
            write-verbose "$CallURI"
            if($CallURI -like '*$batch*')
            {
                return $return
            }

            $OdataTag = $($return."@odata.context")
            if($return.value -ne $null)
            {
                $return = $return.value
            }
        }
        catch 
        {
            throw $_
        }
    }

    if($return -ne $null)
    {
        return $return|Add-OdataToReturn -odatatag $OdataTag
    }
}