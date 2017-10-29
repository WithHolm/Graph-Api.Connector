Function Convertto-GraphCall{
    param(
        [Parameter(Mandatory=$true, 
        ValueFromPipeline=$true,
        Position=0)]
        $Object
    )
    begin{

    }
    process{
        $ObjectType = $Object.pstypenames[0]
        $reg = $(get-odataregistry).OdataRegistry
        $reg 
        #$test = $reg |where{$_.EntityFQN.StartsWith($ObjectType)}
        #$test
    }
}
#Invoke-GraphCall -Method get -Call users|select -first 1|convertto-graphcall