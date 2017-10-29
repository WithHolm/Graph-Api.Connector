<#
.Synopsis
    Invokes a async web request. When the request is completed, it fires off a event. 
.EXAMPLE
    Invoke-WebrequestAsync -method Get -uri www.withholm.com
.EXAMPLE
    Invoke-WebrequestAsync -method Get -uri www.withholm.com
.INPUTS
    Inputs to this cmdlet (if any)
.OUTPUTS
    Output from this cmdlet (if any)
.NOTES
    General notes
.COMPONENT
    The component this cmdlet belongs to
#>
Function Invoke-WebrequestAsync
{
    [cmdletbinding()]
    param(
    [Parameter(Mandatory=$true)]
        [uri]$URI = "https://withholm.com",

    [Parameter(Mandatory=$true)]
        [String]$Tag,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Get", "Post")]
        [String]$Method,

    [Parameter(Mandatory=$false)]
        [hashtable]$Header,

    [Parameter(Mandatory=$false)]
        [hashtable]$body,

    [Parameter(Mandatory=$false)]
        [switch]$passthruWebclient,

    [Parameter(Mandatory=$false)]
        [switch]$PassthruEventWatcher
    )

    Get-EventSubscriber |where{$_.SourceIdentifier -eq $tag}|unregister-event

    $web_client = New-Object System.Net.WebClient

    if($Header -ne $null)
    {
        foreach($head in $Header.GetEnumerator())
        {
            $web_client.Headers.Add($head.name,$head.value)
        }
    }

    Write-Verbose "Invoking $method to '$uri' with async tag '$tag'"

    if($Method -ieq "GET")
    {
        $data = $web_client.DownloadStringAsync($uri)
        #Register Event In Powershell, so it can be hooked onto later on
        Register-ObjectEvent -InputObject $web_client -EventName DownloadStringCompleted -SourceIdentifier "$Tag" -MessageData @{verbosepreference=$VerbosePreference} -Action {
            $VerbosePreference = $event.MessageData.verbosepreference
            Write-verbose "Async GET operation '$($event.SourceIdentifier)' finished" 
            $event.Sourceargs.result
        }|out-null
    }
    elseif($method -ieq "POST")
    {
        $UsingBody = [System.Collections.Specialized.NameValueCollection]::new()
        foreach($BodyToken in $body.GetEnumerator())
        {
            $UsingBody.Add($BodyToken.name,$BodyToken.value)
        }
        $web_client.UploadValuesAsync($URI,$Method,$body)
        Register-ObjectEvent -InputObject $web_client -EventName UploadValuesCompleted -SourceIdentifier "$Tag" -MessageData @{verbosepreference=$VerbosePreference} -Action {
            $VerbosePreference = $event.MessageData.verbosepreference
            Write-verbose "Async POST operation '$($event.SourceIdentifier)' finished" 
            ([System.Text.UTF8Encoding]::new()).GetString($event.Sourceargs.result)
        }|out-null
    }

    if($passthruWebclient)
    {
        $web_client
    }
    elseif ($PassthruEventWatcher) 
    {
        Get-EventSubscriber|where{$_.SourceIdentifier -eq "$Tag"}
    }

}