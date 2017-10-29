<#
.SYNOPSIS
takes the inndata and finds the suiting psclass for the current data with the help of odatatag 

.DESCRIPTION
Long description

.PARAMETER Inndata
Parameter description

.PARAMETER OdataTag
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function Get-CallOdata
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            Position = 0)]
        $Inndata
    )
    Write-Verbose "Processing Odata: $($Inndata."@odata.context")"
    <#
    saving regex here just in case i f it up again in tests and delete jeg config json file
    regex:
        (.*).com\/(?'Version'.*)\/\$metadata\#(?'Odata'\w*)(?'entity'.*)
    json verison of this:
        (.*).com\\/(?'Version'.*)\\/\\$metadata\\#(?'Odata'\\w*)(?'entity'.*)
    #>
    $Regex = [regex]::Match($($Inndata."@odata.context"), (Get-GraphAPIConfigFile).odata.GraphTypenameRegex).groups
    write-verbose "Regex data: $($Regex.groups.value -join ', ')"

    #Set if its entity (one object return) or not (Collection of objects)
    [pscustomobject]@{
        version = $Regex['Version'].value
        Entity = (!([String]::IsNullOrEmpty($Regex['Entity'].value)))
        OdataTag = $Regex['Odata'].value
    }
}

