function Get-OdataObjectType
{
    param(
        [String]$typename
    )

    Switch($typename)
    {
        "Edm.Int32"{"Int"}
    }
}