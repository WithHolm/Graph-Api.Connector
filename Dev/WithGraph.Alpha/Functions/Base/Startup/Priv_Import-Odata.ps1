function Import-Odata
{
    [cmdletbinding()]
    param()
    $script:odata = @()
    $config = Get-GraphAPIConfigFile
    $download = $true
    $odataxmlFile = "$script:GraphCacheRoot\$($config.Odata.Cache.Odataxml)"
    
    #Test if i should download first
    if ($config.Odata.Cache.Active)
    {
        Write-verbose "odata cache is active. checking if files is present"
        #Check that the actual cachefile is present. if its not, set download to true and break out of the foreach loop
        foreach ($version in $(Get-GraphAPIConfigFile).graphversion.avalible)
        {
            $odataversionxml = $($odataxmlFile -f $version)
            if (!(test-path $odataversionxml))
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

    if ($download)
    {
        $(Get-GraphAPIConfigFile).graphversion.avalible.foreach{
            Write-verbose "Adding Metadata for graph version: $_"
            Invoke-WebRequestasync -URI "https://graph.microsoft.com/$_/$('$metadata')" -Tag $_ -Method Get
        }
    }
    #Starting import of odata
    foreach ($version in $((Get-GraphAPIConfigFile).GraphVersion.Avalible))
    {
        $odataversionxml = $($odataxmlFile -f $version)
        if ($download)
        {
            Wait-Event -name $version            
            $temp = Read-Event -name $version
            $odata = [pscustomobject]@{$temp.tag = [xml] ($temp.result)}
            if ($config.Odata.Cache.Active)
            {
                new-item -Path $odataversionxml -ItemType file -Force
                $odata.$version.Save($odataversionxml)
            }  
        }
        else
        {
            Write-verbose "Reading data from disk. Version $version"
            #15 ms (.net) vs 600 ms (gci) for a read of a file...
            $odata = [pscustomobject]@{$version = [xml][System.IO.File]::OpenText($odataversionxml).readtoend()}
        }
        $script:odata += $odata
    }
}