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
#New-Variable _AzureEnviorment -Scope Script -Value $null -Force

New-Variable GraphVersion -Scope Script -Value (Get-GraphAPIConfigFile).GraphVersion.Selected -Force

#Import Odata
New-Variable Odata -Scope Script -Value @() -Force
foreach($version in $((Get-GraphAPIConfigFile).GraphVersion.Avalible))
{
    Write-host "Adding Metadata for graph version: $version"
    $web_client = New-Object System.Net.WebClient
    $Job = Register-ObjectEvent -InputObject $web_client -EventName DownloadStringCompleted -Action {
        Write-Host 'Download completed'
        $EventArgs.Result
    }
    $Script:Odata += $web_client.OpenReadAsync('https://graph.microsoft.com/'+$version+'/$metadata')
    #$Script:Odata += @{"$version"=[xml](Invoke-WebRequest -Method Get -Uri 'https://graph.microsoft.com/beta/$metadata' -UseBasicParsing).content}
}


# Measure-Command -Expression {
# New-Variable Odata -Scope Script -Value @() -Force
# $ver = @('v1.0','beta')
# foreach($version in $ver)
# {
#     #Write-host "Adding Metadata for graph version: $version"
#     Start-Job -Name $version -ScriptBlock {
#         param($version)
#         @{$version = ([xml](Invoke-WebRequest -Method Get -Uri $([String]::Format('https://graph.microsoft.com/{0}/$metadata',$version)) -UseBasicParsing).content)}
#     } -ArgumentList $version|out-null
#     #$Script:Odata += $web_client.OpenReadAsync('https://graph.microsoft.com/'+$version+'/$metadata')
#     #$Script:Odata += @{"$version"=[xml](Invoke-WebRequest -Method Get -Uri 'https://graph.microsoft.com/beta/$metadata' -UseBasicParsing).content}
# }
# while (Get-Job -State Running){}
# $script:odata = $ver|%{Receive-Job -Name $_}

# $script:odata.beta.edmx.DataServices
# }


#     New-Variable Odata -Scope Script -Value @() -Force
#     $ver = @('v1.0','beta')
#     foreach($version in $ver)
#     {
#          $script:odata += @{$version = ([xml](Invoke-WebRequest -Method Get -Uri $([String]::Format('https://graph.microsoft.com/{0}/$metadata',$version)) -UseBasicParsing -Verbose).content)}
#     }

#     $script:odata.beta.edmx.DataServices



#load Files
get-childitem $Moduleroot -Filter "lib_*.ps1" -Recurse | ForEach-Object{. $_.FullName}