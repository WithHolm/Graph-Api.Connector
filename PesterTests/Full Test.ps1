$CredentialsFile = "AzureCred.xml"
$Global:modulename = 'WithGraph.Alpha'
$Global:ModuleRootFolder = "$(split-path $PSScriptRoot)\$modulename"
get-module $global:modulename | Remove-Module -Force
import-module (join-path $ModuleRootFolder "$global:modulename.psd1") -Force

$tests = @()
foreach($TestDir in get-childitem $PSScriptRoot -Directory)
{
    Write-host -ForegroundColor "green" -Object "TESTING $($testdir.name.ToUpper())"
    $tests += invoke-pester -path $TestDir.FullName -PassThru
}

if($tests.foreach{$_.totalcount -eq $_.passedcount} -eq $tests.foreach{$true})
{
    Write-output "All tests ($($tests.count)) passed!"
}
else 
{
    Write-output "$(@($tests.where{$_.totalcount -ne $_.passedcount}).Count) tests failed:"
}
#invoke-pester -path "$PSScriptRoot\users"