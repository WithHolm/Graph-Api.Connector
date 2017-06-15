Function Get-GadUser
{
    [cmdletbinding()]
    param(
        [String]$upn,
        [String]$Search,
        [String]$Filter,
        [Switch]$Detailed
        )
    
    $Query = "Users"

    if(!([String]::IsNullOrEmpty($upn)))
    {
        $Query += "\$upn"
    }

    if(!([String]::IsNullOrEmpty($Filter)))
    {
        $return = Invoke-GraphCall -Call "users" -Method Get -filter $Filter
    }
    else
    {
        $return = Invoke-GraphCall -Call "users" -Method Get
    }  
}