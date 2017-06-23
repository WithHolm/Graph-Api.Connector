Function Set-GraphVersion
{
    [cmdletbinding()]
    param(
        [Switch]$Persist,
        [String]$Version
    )
    
    $AllVersions = Get-GraphVersion -ShowAll

    #If Version is not selected, show a selection screen
    if([String]::IsNullOrEmpty($Version))
    {
        Write-Verbose "Currently selected '$script:GraphVersion'"
        $answer = $arr.Count +1
        do
        {
            for($i=0;$i -lt $arr.Count;$i++)
            {
                write-host "$($i): $($AllVersions.Avalible[$i])"
            }
            $answer = [int](read-host "Select number")
        }while($answer -gt $AllVersions.Avalible.Count)
        $version = $($AllVersions.Avalible[$answer])
    }
    else
    {
        if($Version -in $AllVersions.Avalible)
        {
            $script:GraphVersion = $Version
        }
        else
        {
            throw "$version"
        }        
    }

    if($Persist)
    {
        $config = get-GraphAPIConfigFile
        $config.GraphVersion.Selected = $Version
        $Config|convertto-json |out-file $Script:GraphAPIConfigFile -Force
    }
    
    Write-verbose "Currently selected '$version', old '$script:GraphVersion'"

}