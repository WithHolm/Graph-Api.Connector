
New-Variable Moduleroot -Scope Script -Value $PSScriptRoot
New-Variable GraphAPIConfigFile -Scope Script -Value (join-path $PSScriptRoot "Config.json") -Force

Function New-GraphAPIConfigFile
{
@'   
{
    "GraphVersion":{
        "Selected":"Beta",
        "Avalible":["Beta","v1.0"]
    }
}
'@|out-file $Script:GraphAPIConfigFile -Force
}

Function Get-GraphAPIConfigFile
{
    if((get-item $Script:GraphAPIConfigFile -ErrorAction SilentlyContinue) -eq $null)
    {
        New-GraphAPIConfigFile
    }

    return (get-content $Script:GraphAPIConfigFile -raw | convertfrom-json)
}

New-Variable AadAccessToken -Scope Script -Value $null -Force
New-Variable OdataRegistry -Scope Script -value $null
#New-Variable _AzureEnviorment -Scope Script -Value $null -Force
New-Variable GraphVersion -Scope Script -Value (Get-GraphAPIConfigFile).GraphVersion.Selected -Force

#write-host "$script:Graphversion"
#Import Odata
New-Variable Odata_ExpandableObjects -Scope Script -Value @() -Force
foreach($version in $((Get-GraphAPIConfigFile).GraphVersion.Avalible))
{
    if(!$((Get-GraphAPIConfigFile).DisableLoadMessage))
    {
        Write-host "Adding Metadata for graph version: $version"
    }
    #[String]::format('https://graph.microsoft.com/{0}/$metadata',$version)
    $Script:Odata += @{$version=[xml](Invoke-WebRequest -Method Get -Uri $([String]::format('https://graph.microsoft.com/{0}/$metadata',$version)) -UseBasicParsing).content}
}

#load Files
get-childitem $Moduleroot -Filter "lib_*.ps1" -Recurse | ForEach-Object{. $_.FullName}

#Import Odata
Import-OdataEntity