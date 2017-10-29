Function Expand-GraphObject
{
    param(
        [Parameter(Mandatory=$true, 
        ValueFromPipeline=$true,
        Position=0)]
        $Object
    )

    begin
    {
        $objects = @()
        $GraphExpands = @()
        $GraphCall = ""
    }
    process
    {
        if($objects.Count -eq 0)
        {
            $GraphExpands = Get-GraphExpands $object.pstypenames[0]
            Write-Verbose "$(@($GraphExpands).count)  objects"
            foreach($expand in $GraphExpands)
            {
                Invoke-GraphCall -Method get -Call
            }
        }

        Invoke-GraphCall -Method get -Call 
    }
}