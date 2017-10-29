Function Get-Typedataname
{
    param(
        [String]$Version,
        [String]$OdataType
    )
    $odata = get-Odata $version
    $OdataEset = $odata.EntityContainer.EntitySet|where{$_.name -eq $OdataType}
    #$odata
    $OdataEset
}