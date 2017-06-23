Function Get-GraphVersion
{
    [cmdletbinding()]
    param(
        [Switch]$ShowAll
    )

    
    $Config = Get-GraphAPIConfigFile
    
    $return = [pscustomobject]@{
                                    Active = $script:GraphVersion
                                    Persistent = $Config.graphversion.selected
                                    Avalible = $Config.graphversion.Avalible
                                }
    
    if(!$ShowAll)
    {
        return $return.Active
    }
    else
    {
        return $return
    }
}