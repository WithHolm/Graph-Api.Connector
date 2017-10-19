Function Get-GadUser
{
    [cmdletbinding()]
    param(
        [String]$ID,
        [String]$Search,
        [String]$Filter,
        [Switch]$Detailed
        )
    
    $Query = "Users"

    if(!([String]::IsNullOrEmpty($ID)))
    {
        $Query += "\$ID"
    }

    if(!([String]::IsNullOrEmpty($Filter)))
    {
        $return = Invoke-GraphCall -Call "users" -Method Get -filter $Filter
    }
    else
    {
        $return = Invoke-GraphCall -Call "users" -Method Get
    }  


    return $return
}