Function Import-Odata
{
    $config = Get-Graphapiconfigfile
    $downloadmetadata = $false
    if($config.Odata.Cache.Active)
    {
        #Incase something goes wrong, download the metadata instead
        try
        {
            #If odata-cache is set to active, get this instead of from the webstream
            foreach($version in $config.GraphVersion.Avalible)
            {
                Get-Item $("$script:GraphConfigRoot\$($config.Odata.Cache.Odataxml)" -f $version) -ErrorAction Stop
            }
        }
        catch
        {
            $downloadmetadata = $true
        }
    }
    else
    {
        $downloadmetadata = $true
    }

    if($downloadmetadata)
    {
        foreach($version in $config.GraphVersion.Avalible)
        {
            $Script:Odata += @{$version=[xml](Invoke-WebRequest -Method Get -Uri $([String]::format('https://graph.microsoft.com/{0}/$metadata',$version)) -UseBasicParsing).content}
        }
    }
}