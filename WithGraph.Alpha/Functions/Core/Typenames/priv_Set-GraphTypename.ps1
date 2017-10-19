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
function Set-GraphTypename
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            Position = 0)]
        $Inndata,

        [String]$OdataTag
    )
    Write-Verbose "Processing Odata: $($Inndata."@odata.context")"
    $Regex = [regex]::Match($($Inndata."@odata.context"), (Get-GraphAPIConfigFile).odata.GraphTypenameRegex).groups
    #write-verbose "Regex data: $($Regex.groups.value -join ', ')"

    #Set if its entity (one object return) or not (Collection of objects)
    $version = $Regex['Version'].value
    $Entity = (!([String]::IsNullOrEmpty($Regex['Entity'].value)))
    $OdataTag = $Regex['Odata'].value
    Write-verbose "odatatag: $OdataTag, Entity: $entity, Version: $version"

    if ($Entity)
    {
        $Inndata.psobject.properties.remove("@odata.context")
        $process = @($Inndata)
    }
    else 
    {
        
        $process = @($Inndata.value)
    }

    $CA = (get-GraphobjectNames -Version $version).foreach{"$($_.name)_$($_.version)"}
    $odataInfo = (Get-AllExpandTypes).where{($_.odataname -eq $odatatag) -and ($_.version -eq $version)}
    $process.foreach{
        Write-verbose "Processing object $($_.id)"
        Set-GraphClassData -data $_ -classname "$($odataInfo.Entityname)_$version" -classarray $CA
    }
}

