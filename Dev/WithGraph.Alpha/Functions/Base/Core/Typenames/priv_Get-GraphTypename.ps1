Function Get-GraphTypename
{
    param(
        [Parameter(Mandatory = $true, 
            ValueFromPipeline = $true,
            Position = 0)]
        $Object
    )
    $Expands = Get-AllExpandTypes
    foreach($pstypename in $Object.pstypenames)
    {               
        foreach($expand in $Expands)
        {
            if($pstypename.startswith($expand.Entityfqn))
            {
                write-verbose "$pstypename"
                $process = $false
                return $expand
            }
        }
    }
    

}