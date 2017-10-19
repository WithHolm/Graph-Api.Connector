Function Get-Odata
{
    param($version)

    $script:odata."$version".edmx.dataservices.Schema
}