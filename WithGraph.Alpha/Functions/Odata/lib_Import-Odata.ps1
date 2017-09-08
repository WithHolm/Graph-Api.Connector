function Import-Odata
{
    [cmdletbinding()]
    param()
    $script:odata = @()
    $config = Get-GraphAPIConfigFile
    $download = $true
    $odataxmlFile = "$script:GraphCacheRoot\$($config.Odata.Cache.Odataxml)"
    
    #Test if i should download first
    if($config.Odata.Cache.Active)
    {
        Write-verbose "odata cache is active. checking if files is present"
        #Check that the actual cachefile is present. if its not, set download to true and break out of the foreach loop
        foreach($version in $(Get-GraphAPIConfigFile).graphversion.avalible)
        {
            $odataversionxml = $($odataxmlFile -f $version)
            if(!(test-path $odataversionxml))
            {
                $download = $true
                break
            }
            else
            {
                $download = $false
                write-verbose "Found $version on disk"
            }

            
        }       
    }

    foreach($version in $(Get-GraphAPIConfigFile).graphversion.avalible)
    {
        $odataversionxml = $($odataxmlFile -f $version)
        if($download)
        {    
            Write-verbose "Downloading odata for version: $version"
            $odata =  [pscustomobject]@{$version = [xml] (Invoke-WebRequest -uri $([String]::format('https://graph.microsoft.com/{0}/$metadata',$version))).content}
            if($config.Odata.Cache.Active)
            {
                new-item -Path $odataversionxml -ItemType file -Force
                $odata.$version.Save($odataversionxml)
            }           
        }
        else
        {
            Write-verbose "Reading data from disk. Version $version"
            $odata =  [pscustomobject]@{$version = [xml] (get-content $odataversionxml)}
        }

        $script:odata += $odata
    }
}