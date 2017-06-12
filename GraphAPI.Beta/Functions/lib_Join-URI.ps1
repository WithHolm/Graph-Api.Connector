Function Join-URI
{
    [cmdletbinding()]
    param(
    [String]$Parent,
    [String]$child
    )

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