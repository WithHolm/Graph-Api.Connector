Function Invoke-Credential
{
    param(
        [parameter(mandatory=$true)]
        $name
    )

    $credpath = (join-path $PSScriptRoot "$name.clixml")
    if(test-path $credpath)
    {
        Import-Clixml -Path $credpath
    }
    else 
    {
        $Cred = get-credential -Message "GraphAPI Credentials"
        if($Cred -ne $null)
        {
            $cred | Export-Clixml -Path $credpath
            Invoke-Credential $path
        }
    }
}



##Start 
try {
    #$VerbosePreference = "continue"
    gci $PSScriptRoot\logging -Filter "*.ps1"|%{. $_.FullName}
    New-Log ".\Build.log" -Append 
    
    $Global:PesterTestCred = Invoke-Credential -name "GraphAPI"
    $Global:ModuleRootFolder = (Gci (split-path $PSScriptRoot) -Directory|?{(gci $_.FullName -Filter "*psm1") -ne $null}|select -First 1).FullName
    $Global:modulename = split-path $Global:ModuleRootFolder -Leaf
    $Testpath = join-path (Split-Path $PSScriptRoot) "Tests"
    write-log "## Starting Build $(get-date -f "yyyy/MM/dd hh:mm"). Module: $Global:modulename ##" -PassThru
    Write-Log "## $Global:ModuleRootFolder ##" -PassThru
    Write-Log "## Testphase ##" -PassThru
    import-module $Global:ModuleRootFolder -Force
    $tests = @()
    $tests += invoke-pester -path $Testpath -PassThru
    if($tests.totalcount -eq $tests.passedcount)
    {
        Write-Log "All tests ($($tests.count)) passed!" -PassThru
    }
    else 
    {
        Write-Log "$($tests.failedcount) tests failed" -PassThru
        # $tests.TestResult.where{
        #     $_.passed -eq $false
        # }|select describe,Context,FailureMessage,name|fl
    }
}
catch {
    throw $_
}
finally{
    #Get-Module $Global:modulename | Remove-Module
    $VerbosePreference = "Silentlycontinue"
}


#$Global:ModuleRootFolder = "$(split-path $PSScriptRoot)\$modulename"

# get-module $global:modulename | Remove-Module -Force
# import-module (join-path $ModuleRootFolder "$global:modulename.psd1") -Force