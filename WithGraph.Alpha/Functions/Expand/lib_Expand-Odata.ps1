Function Expand-Graphobject
{
    Param(
        [Parameter(Mandatory=$true, 
            ValueFromPipeline=$true,
            Position=0)]
        $Object
    )
    begin
    {
        $objects = @()
        
    }
    process
    {
        $objects += $Object
        $return += $object.pstypenames[0]
    }
    end
    { 
        $batchrequest = @{
                        Requests=New-Object System.Collections.ArrayList 
                        }
        $ID = 1
        Write-Verbose "expanding $(@($objects).Count) objects"
        foreach($obj in $objects)
        {
            #write-verbose $object.pstypenames[0]
            if($object.pstypenames[0].endswith('v1.0'))
            {
                $version = "v1.0"
            }
            else
            {
                $version = $object.pstypenames[0].split('.')[-1]
            }
            $ObjectType = $object.pstypenames[0].split('.')[2]


            if($version -ne "Expanded")
            {
                <#
                Create Batch request
                https://developer.microsoft.com/en-us/graph/docs/concepts/json_batching
                {
                    "requests": [
                        {
                        "id": "1",
                        "method": "GET",
                        "url": "/me/drive/root:/{file}:/content"
                        },
                        {
                        "id": "2",
                        "method": "GET",
                        "url": "/me/planner/tasks"
                        },
                        {
                        "id": "3",
                        "method": "GET",
                        "url": "/groups/{id}/events"
                        }
                    ]
                }
                #>

                $Expands = (Get-GraphExpandableObjects).$($version).expands.$ObjectType
                
                $baseurl = [String]::Format("{0}/{1}",`
                                        ((Get-GraphExpandableObjects).$($version).odataregistry.where{$_.Entityname -eq $ObjectType}).odataname,`
                                        $obj.id)
                foreach($expand in $expands)
                {
                    $batchrequest.requests.add(@{
                                                    ID = $id
                                                    Method = "GET"
                                                    url = [String]::Format("$baseurl/{0}",$expand)
                                                }
                                            )|out-null
                    
                    $ID++
                }
            }
        }
        #Can only do in batches of 5 for now.
        $Batchlimit = 5
        write-verbose "Calling graphapi with batchrequest of $($batchrequest.requests.count) items in batches of $batchlimit. ($($batchrequest.requests.count / 5)) requests"
        $lasti = 0
        $response = New-Object System.Collections.ArrayList 
        for($i=$Batchlimit-1;$i-le$batchrequest.requests.count;$i+=$Batchlimit)
        {
            Write-Progress -Activity "Getting Expands" -Status "$lasti to $i of $($batchrequest.requests.count)" -PercentComplete (($i/$batchrequest.requests.count)*100)
            write-verbose "handling $lasti to $i of $($batchrequest.requests.count)"
            $request = @{Requests=$batchrequest.requests[$lasti..$i]}
            $response += invoke-graphcall -Version $version -Method Post -Body (convertto-json $request) -Call '$batch' -async
            $lasti = $i +1
        }

        #Also include the last x amount of batches..
        # if($i -lt $batchrequest.requests.count-1)
        # {
        #     $i += (($batchrequest.requests.count-1)-$i)
        #     Write-Progress -Activity "Getting Expands" -Status "$lasti to $i of $($batchrequest.requests.count)" -PercentComplete (($i/$batchrequest.requests.count)*100)
        #     write-verbose "handling $lasti to $i of $($batchrequest.requests.count)"
        #     $request = @{Requests=$batchrequest.requests[$lasti..$i]}
        #     $response += invoke-graphcall -Version $version -Method Post -Body (convertto-json $request) -Call '$batch'
        # }
        #invoke-graphcall -Version $version -Method Post -Body $batchrequest -Call '$batch'
        #invoke-GraphBatch -BatchRequest $batchrequest -version $version
        $batchrequest
    }
}