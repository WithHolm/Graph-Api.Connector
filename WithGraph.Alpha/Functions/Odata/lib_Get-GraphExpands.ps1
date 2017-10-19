Function Get-GraphExpands
{
    param(
        [String]$ObjectTag
    )

    $usingversion = ""
    foreach($version in (Get-Graphapiconfigfile).GraphVersion.Avalible)
    {
        if($ObjectTag.EndsWith($version))
        {
            $usingversion = $version 
        }

    }

    return $($script:Odata_registry.$usingversion.expands.$($ObjectTag.Split('.')[2]))
}