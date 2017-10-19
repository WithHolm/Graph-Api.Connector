Function Get-IncomingOdataType
{
    param($string)

    [regex]::Match($string,'(.*)(\$metadata#)(.*)\/(\$.*)').groups[3].value
}