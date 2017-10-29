Function Get-OdataEntityType
{
    param(
        $version,
        $Name
        )
    
    Write-verbose "Getting entity: '$name' from version '$version'"
    $return = (get-odata $version).entitycontainer.entityset|where{$_.name -like $Name}
    write-verbose "Returned $(@($return).count)"
    $return.entitytype
}