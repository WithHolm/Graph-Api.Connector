Function Disconnect-GraphAPI
{
    [cmdletbinding()]
    param()
    try
    {
        [Microsoft.Open.Azure.AD.CommonLibrary.AzureSession]::ClearSessionState()
        write-verbose "Cleared Azure Sessionstate"
    }
    catch
    {
        Write-error "Could not disconnect graph: $_"
    }
}