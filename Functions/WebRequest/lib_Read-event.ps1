function Read-Event
{
    param(
        #Output from Get-EventSubscriber
        [parameter(
            ValueFromPipeline=$true,
            ParameterSetName='EventsubPipeline')]
        [System.Management.Automation.PSEventSubscriber]$Eventsub,

        #manual search for EventSubscriber
        [parameter(
            mandatory=$true,
            ParameterSetName='Manual')]
        [String]$name
        )

    begin
    {
        if($PsCmdlet.ParameterSetName -eq "Manual")
        {
            return $(Get-EventSubscriber|where{$_.Action.name -like "$name"}|Read-Event)
        }
    }
    process
    {
        foreach($event in $Eventsub)
        {
            if($event.Action.State -eq "NotStarted")
            {
                throw "The operation tied to this event ('$($event.Action.Name)') havent finished yet."
            }
            [pscustomobject]@{
                Tag = $event.Action.Name
                Result =  $event.Action.Output
            }
        }
    }
}