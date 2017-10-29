<#
.SYNOPSIS
Joins two different url parts to one properly formatted part. 
Like join-path just for urls

.DESCRIPTION
Long description

.PARAMETER Parent
Parameter description

.PARAMETER child
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
Function Join-URI
{
    [cmdletbinding()]
    param(
        [ValidateNotNullOrEmpty()]
    [String]$Parent,
        [ValidateNotNullOrEmpty()]
    [String]$child
    )

    if([String]::IsNullOrEmpty($Parent) -or [String]::IsNullOrEmpty($child))
    {
        Throw "Need both parent and child to be able to join them"
    }
    if($Parent.EndsWith('/'))
    {
        $Parent = $Parent.Substring(0,$Parent.Length-1)
    }
    
    if($child.StartsWith('/'))
    {
        $child = $child.Substring(1,$child.Length-1)
    }
    $Return = [String]::Format("{0}/{1}",$Parent,$child)
    #write-verbose "returning '$return'"
    $return
}