Function Invoke-GraphCall
{
    [cmdletbinding(PositionalBinding=$false)]
    param(
        # [Parameter(Mandatory=$false)]
        #     [String]$Version,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Get", "Post")]
        [String]$Method = "Get",

        [Parameter(Mandatory = $false)]
        $Body,

        # [Parameter(Mandatory=$true)]
        #     [String]$Call,

        [Parameter(Mandatory = $false)]
        [String]$filter,

        [Parameter(Mandatory = $false)]
        [String]$Expand,

        [Parameter(Mandatory = $false)]
        [Switch]$ReturnCallURL,

        [Parameter(Mandatory = $false)]
        [Switch]$async,

        [String]$baseURL
    )

    DynamicParam    
    {          
        #Add version
        $ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttrib.Mandatory = $false
        $AttribColl = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribColl.Add($ParamAttrib)
        $AttribColl.Add((New-Object  System.Management.Automation.ValidateSetAttribute($(get-graphversion).avalible)))
        $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Version', [string], $AttribColl)
        $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add('Version', $RuntimeParam)

        #Add Call
        if([String]::IsNullOrEmpty($PSBoundParameters.version))
        {
            $tempver = $(get-graphversion).active
        }
        else {
            $tempver = $PSBoundParameters.version
        }
        $ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttrib.Position = 1
        $ParamAttrib.Mandatory = $true
        $AttribColl = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribColl.Add($ParamAttrib)
        #$AttribColl.Add((New-Object  System.Management.Automation.ValidateSetAttribute((Get-AllExpandTypes|select -Unique OdataName).OdataName)))
        $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Call', [string], $AttribColl)
        $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add('Call', $RuntimeParam)
        return  $RuntimeParamDic
    }
    process
    {
        $version = $PSBoundParameters.version
        $call = $PSBoundParameters.call
        if ([String]::IsNullOrEmpty($version))
        {
            $version = (get-graphversion).active
        }
        else 
        {
            #Fix Version
            foreach ($ConfigVersion in (Get-GraphAPIConfigFile).GraphVersion.avalible)
            {
                Write-verbose "Test $version against $ConfigVersion"
                if ($ConfigVersion -like "*$version*")
                {
                    $version = $ConfigVersion
                    break
                }
            }
        }
        $OdataTag = ""
        write-verbose "version $version, call $call"
        $query = join-uri -Parent $Version -child $Call
    
        #If filter is defined
        $customresponsearray = @()
        if (![String]::IsNullOrEmpty($filter))
        {
            $customresponsearray += '$filter=' + $filter
        }
    
        #If expand is defined
        if (![String]::IsNullOrEmpty($Expand))
        {
            $customresponsearray += '$expand=' + $Expand
        }
    
        if ($customresponsearray.count -gt 0)
        {
            $query += "?$($customresponsearray -join '?')" 
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
            if ([String]::IsNullOrEmpty($auth))
            {
                Throw "The authkey was empty!"
            }
        }
        catch
        {
            throw "Unable to create authentication token. Have you logged on? Error: $_"
        }
        
        $CallURI = Join-URI -Parent $resource -child $query
        if ($ReturnCallURL)
        {
            return $CallURI
        }
    
        $authHeader = @{
            'odata.metadata' = 'full'
            'Content-Type'  = 'application\json'
            'Authorization' = $Auth
        }
    
        if ($Method -eq "Get")
        {
            if ($async)
            {
                return $(Invoke-WebrequestAsync -URI $CallURI -Header $authHeader -Tag $query -PassthruEventWatcher)
            }
            try
            {
                $return = Invoke-RestMethod -Method Get -Uri $CallURI -Headers $authHeader
            }
            catch 
            {
                throw $_
            }
        }
        # if ($Method -eq "Post")
        # {        
        #     try
        #     {
        #         if ($async)
        #         {
        #             Write-verbose "Invoking async rest with body" 
        #             $return = start-job -ScriptBlock {param($URI, $Header, $body) Invoke-RestMethod -Method post -Uri $URI -Headers $Header -Body $Body} -ArgumentList $CallURI, $authHeader, $Body
        #         }
        #         else
        #         {
        #             if ($Body -ne $null)
        #             {
        #                 Write-verbose "Invoking rest with body"                
        #                 $return = Invoke-RestMethod -Method post -Uri $CallURI -Headers $authHeader -Body $Body #-ContentType 'application/json'
        #                 #return $return
        #             }
        #             else
        #             {
        #                 Write-verbose "Invoking rest w/o body"
        #                 $return = Invoke-RestMethod -Method post -Uri $CallURI -Headers $authHeader
                        
        #             }
        #         }
    
        #         write-verbose "$CallURI"
        #         if ($CallURI -like '*$batch*')
        #         {
        #             return $return
        #         }
    
        #         $OdataTag = $($return."@odata.context")
        #         if ($return.value -ne $null)
        #         {
        #             $return = $return.value
        #         }
        #     }
        #     catch 
        #     {
        #         throw $_
        #     }
        # }
    
        if ($return -ne $null)
        {           
            $return = $($return|Set-GraphTypename)
            return $return
        }
    }

}