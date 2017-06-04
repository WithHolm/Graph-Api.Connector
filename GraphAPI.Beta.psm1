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

New-Variable Moduleroot -Scope Script -Value $PSScriptRoot
New-Variable GraphAPIConfigFile -Scope Script -Value (join-path $Script:Moduleroot "Config.json") -Force

New-Variable AadAccessToken -Scope Script -Value $null -Force
New-Variable _AzureEnviorment -Scope Script -Value $null -Force

New-Variable GraphVersion -Scope Script -Value (Get-GraphAPIConfigFile).GraphVersion.Selected -Force

#load Files
get-childitem $Moduleroot -Filter "lib_*.ps1" -Recurse | ForEach-Object{. $_.FullName}
