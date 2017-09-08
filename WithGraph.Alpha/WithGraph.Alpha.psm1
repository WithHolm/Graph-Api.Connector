New-Variable GraphModuleroot -Scope Script -Value $PSScriptRoot
New-Variable GraphConfigRoot -Scope Script -Value "$PSScriptRoot\config"
New-Variable GraphCacheRoot -Scope Script -Value "$PSScriptRoot\cache"
New-Variable GraphAPIConfigFile -Scope Script -Value (join-path "$PSScriptRoot\Config" "Config.json") -Force

#import Logger
#import-module "$Script:graphmoduleroot\Modules\Communary.Logger\communary.logger.psd1" -Force

Function New-GraphAPIConfigFile
{
@'   
{
    "Odata":{
                "Cache":{
                            "Active":true,
                            "CacheFolder":"Cache",
                            "Odataxml":"Odata.{0}.cache.xml",
                            "ExpandCache":"ExpandTypes.{0}.Cache.Json"
                        }
            },
    "Logging":{
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
    if((get-item $Script:GraphAPIConfigFile -ErrorAction SilentlyContinue) -eq $null)
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

#load Files
get-childitem "$psscriptroot\Functions" -Filter "lib_*.ps1" -Recurse | ForEach-Object{. $_.FullName}

#Import Odata
import-odata
Import-OdataRegistry