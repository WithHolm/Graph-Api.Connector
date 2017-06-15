Function Get-OdataEntityType
{
    param(
        $version,
        $Name
        )
    
    (get-odata $version).EntityType#|where{$_.name -eq $Name}
}