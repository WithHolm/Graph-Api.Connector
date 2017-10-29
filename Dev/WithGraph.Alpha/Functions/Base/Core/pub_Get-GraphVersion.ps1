Function Get-GraphVersion
{
    [cmdletbinding()]
    param(
        #[Switch]$ShowAll
    )

    
    $Config = Get-GraphAPIConfigFile
    
    [pscustomobject]@{
                            Active = $script:GraphVersion
                            Persistent = $Config.graphversion.selected
                            Avalible = $Config.graphversion.Avalible
                        }
                              
    # if(!$ShowAll)
    # {
    #     return Active = $script:GraphVersion
    # }
    # else
    # {
    #     return $return
    # }
}