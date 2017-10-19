Function Wait-Event
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
    [String]$name,

    [int]$WaitMaxSec = 8 
    )

    begin
    {
        $SW = [System.Diagnostics.Stopwatch]::new()
        
        if($PsCmdlet.ParameterSetName -eq "Manual")
        {
            return $(Get-EventSubscriber|where{$_.Action.name -like "$name"}|Wait-Event)
        }
    }
    process
    {
        $SW.Start()
        foreach($event in $Eventsub)
        {
            #$event.Action.Name
            Write-verbose "Waiting for event '$($event.Action.Name)' to finish"
            while((Get-EventSubscriber|where{$_.SourceIdentifier -like $event.SourceIdentifier}).Action.State -eq "NotStarted" )
            {       
                Start-Sleep -Milliseconds 10
                if($SW.ElapsedMilliseconds -gt ($WaitMaxSec * 1000))
                {
                    throw "waiting for $($event.name) timed out after $maxwaitsec seconds"
                }
            }
            (Get-EventSubscriber|where{$_.SourceIdentifier -like $event.name})
        }
    }
}