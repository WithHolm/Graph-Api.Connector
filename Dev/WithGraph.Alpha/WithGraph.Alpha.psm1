New-Variable GraphSavePath -Scope Script -Value (join-path $env:appdata "WithGraph") -Force
New-Variable GraphModuleroot -Scope Script -Value $PSScriptRoot
New-Variable GraphConfigRoot -Scope Script -Value "$script:GraphSavePath\config"
New-Variable GraphCacheRoot -Scope Script -Value "$script:GraphSavePath\cache"
New-Variable GraphClassesRoot -Scope Script -Value "$script:GraphSavePath\Classes"
New-Variable GraphAPIConfigFile -Scope Script -Value (join-path $script:GraphConfigRoot "Config.json") -Force
new-variable ImportedClasses -scope script -Value @()

New-Item -Path $script:GraphSavePath -ItemType Directory -ErrorAction SilentlyContinue
New-Item -Path $script:GraphConfigRoot -ItemType Directory -ErrorAction SilentlyContinue
New-Item -Path $script:GraphCacheRoot -ItemType Directory -ErrorAction SilentlyContinue
New-Item -Path $script:GraphClassesRoot -ItemType Directory -ErrorAction SilentlyContinue

Function New-GraphAPIConfigFile
{
@'   
{
    "Odata":{
                "UseClasses":true,
                "GraphTypenameRegex":"(.*).com\\/(?'Version'.*)\\/\\$metadata\\#(?'Odata'\\w*)(?'Entity'.*)",
                "Cache":{
                            "Active":true,
                            "CacheFolder":"Cache",
                            "Odataxml":"Odata.{0}.cache.xml",
                            "ExpandCache":"ExpandTypes.{0}.Cache.Json"
                        }
            },
    "Logging":{
                "Info":"not yet enabled",
                "Activated":true,
                "LogFolder":"Logs"
            },
    "GraphVersion":  {
                         "Selected":  "beta",
                         "Avalible":  [
                                          "Beta",
                                          "v1.0"
                                      ]
                     }
    
}
'@|out-file $Script:GraphAPIConfigFile -Force
}

Function Get-GraphAPIConfigFile
{
    if(!(test-path $Script:GraphAPIConfigFile))
    {
        New-GraphAPIConfigFile
    }

    return (get-content $Script:GraphAPIConfigFile -raw | convertfrom-json)
}

New-Variable odata -Scope Script -Value @() -Force
New-Variable AadAccessToken -Scope Script -Value $null -Force
New-Variable OdataRegistry -Scope Script -value $null
New-Variable GraphVersion -Scope Script -Value (Get-GraphAPIConfigFile).GraphVersion.Selected -Force
New-Variable Odata_registry -Scope Script -Value @() -Force
New-Variable Odata_Objects -Scope Script -Value $null -Force
$script:Odata_Objects = [System.Collections.ArrayList]::new()

#load Files
$(get-childitem "$psscriptroot\Functions" -Recurse -Include "lib_*.ps1","priv_*.ps1","pub_*.ps1").foreach{. $_.FullName}

import-odata
Import-OdataRegistry
Test-GraphClassUsage

$(get-childitem "$script:GraphClassesRoot" -Recurse -Include "class_*.ps1").foreach{. $_.FullName}