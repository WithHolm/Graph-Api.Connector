function Get-AllExpandTypes
{
    [cmdletbinding()]
    param()

    $return = [System.Collections.ArrayList]::new()
    foreach($version in (Get-GraphAPIConfigFile).graphversion.avalible)
    {
        $Temps = $script:Odata_registry.$version.OdataRegistry
        foreach($temp in $temps)
        {
            $temp|add-member -MemberType NoteProperty -Name "Version" -Value $version -ErrorAction SilentlyContinue
            $return.Add($temp)|Out-Null
        }
    }
    $return
}