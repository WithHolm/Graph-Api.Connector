function Set-GraphClassUsage
{
    param(
        [ValidateSet("true", "false", "null")]
        [String]$enabled = "null"
    )

    if($enabled -eq "null")
    {
        Write-host "You have the option to use classes for your incoming graph data."
        Write-host "there is some setup however to enable this and its currently just a preview"
        Write-host "It enables you to more easily manipulate data and expect certain kinds of data when dealing with a web-api"
        $a = Read-Host "Do you want to enable this? (y/n)"
    }
    else {
        switch($enabled)
        {
            "true"{$a = "y"}
            "false"{$a = "n"}
        }
    }

    if($a -match "Y")
    {
        Write-host "Saving 'Yes' to config. you can change this with the command 'Set-GraphClassUsage'"
        $config = (Get-GraphAPIConfigFile)
        $config.odata.UseClasses = $true
        $config|convertto-json -Depth 99|out-file $Script:GraphAPIConfigFile -Force
    }
    else 
    {
        Write-host "Saving 'No' to config. you can change this with the command 'Set-GraphClassUsage'"
        $config = (Get-GraphAPIConfigFile)
        $config.odata.UseClasses = $false
        $config|convertto-json -Depth 99|out-file $Script:GraphAPIConfigFile -Force
    }
    
    Test-GraphClassUsage
}