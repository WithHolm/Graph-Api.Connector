<#
.SYNOPSIS
Returns all of the objects avalible in the current graphapi. if called upon w/o -version, it returns all objects for all avalible versions.
#>
function Get-GraphobjectNames
{
    [cmdletbinding()]
    param()
    DynamicParam
    {
        if ($PSBoundParameters.version -eq $null)
        {
            $ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
            $ParamAttrib.Mandatory = $false
            $AttribColl = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
            $AttribColl.Add($ParamAttrib)
            $AttribColl.Add((New-Object  System.Management.Automation.ValidateSetAttribute($(get-graphversion).avalible)))
            $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('Version', [string], $AttribColl)
            $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $RuntimeParamDic.Add('Version', $RuntimeParam)
            return $RuntimeParamDic
        }
    }
    process
    {
        if ($PSBoundParameters.version -eq $null)
        {
            $versions = (Get-GraphAPIConfigFile).graphversion.avalible
        }
        else
        {
            $versions = @($PSBoundParameters.version)
        }
    }
    end
    {
        if($script:Odata_Objects.count -eq 0) 
        {     
            Write-verbose "Creating scriptvariable"
            
            foreach($Version in (Get-GraphAPIConfigFile).graphversion.avalible){
                @($(Get-OdataRegistry).$Version.objects).foreach{
                    
                    [void]$script:Odata_Objects.add($_)

                    $script:Odata_Objects[-1].psobject.properties.Add(
                                [psnoteproperty]::new('version',$version)
                    )      
                }
            }
            Write-Verbose "$($script:Odata_Objects.count) members"
        }
        
        @($versions).foreach{
            $Thisversion = $_
            $script:Odata_Objects.where{
                    $_.version -eq $Thisversion
            }
        }

    }

}