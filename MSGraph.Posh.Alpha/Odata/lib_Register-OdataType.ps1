[cmdletbinding()]
param()
Foreach($file in (get-childitem $PSScriptRoot -filter "odata_*.ps1"))
{
    . $file.fullname
}