$CredentialsFile = "AzureCred.xml"
$Global:modulename = 'WithGraph.Alpha'
$Global:ModuleRootFolder = "$(split-path $PSScriptRoot)\$modulename"
get-module $global:modulename | Remove-Module -Force

get-module $global:modulename  | Remove-Module -Force
import-module (join-path $ModuleRootFolder "$global:modulename.psd1") -Force


invoke-pester -path "$PSScriptRoot\module"
invoke-pester -path "$PSScriptRoot\core"
invoke-pester -path "$PSScriptRoot\odata"
invoke-pester -path "$PSScriptRoot\users"