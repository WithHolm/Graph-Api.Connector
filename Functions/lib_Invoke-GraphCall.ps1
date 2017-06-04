Function Invoke-GraphCall
{
    [cmdletbinding()]
    param(
        [String]$Version = $Script:GraphVersion,

        [Parameter(Mandatory=$true)]
        [ValidateSet("Get")]
        [String]$Method,

        [Parameter(Mandatory=$true)]
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
    try
    {
        $endpoint = [Microsoft.Open.Azure.AD.CommonLibrary.AzureEnvironment+Endpoint]::MsGraphEndpointResourceId
        $resource = [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::AzureEnvironment.GetResource($endpoint)
        [Microsoft.Open.Azure.AD.CommonLibrary.IAccessToken]$Accesstoken = [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::GetAccessToken($endpoint)
        $Auth = $Accesstoken.AuthorizeRequest($endpoint)
        $TenantID = $Accesstoken.TenantId
    }
    catch
    {
        throw "Error creating the Accesstoken: $_"
    }
    

    $CallURI = Join-URI -Parent $resource -child $query
    
    if($Method -eq "Get")
    {
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
}