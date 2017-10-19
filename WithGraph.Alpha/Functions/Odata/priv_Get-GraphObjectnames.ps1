<#
.SYNOPSIS
Returns all of the objects avalible in the current graphapi. if called upon w/o -version, it returns all objects for all avalible versions.
#>
function get-GraphobjectNames
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
        foreach ($thisver in $versions)
        {
            @($script:Odata_registry.$thisver.objects).foreach{
                [pscustomobject]@{
                    Name    = $_
                    version = $thisver
                }
            }
        }
    }

}