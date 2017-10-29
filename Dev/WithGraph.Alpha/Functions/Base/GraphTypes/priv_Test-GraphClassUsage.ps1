Function Test-GraphClassUsage
{
    $create = $false

    if((Get-GraphAPIConfigFile).odata.UseClasses -eq $null)
    {
        Set-GraphClassUsage
    }

    if((Get-GraphAPIConfigFile).odata.UseClasses -eq $true)
    {
        $Importedclasses = get-childitem $script:GraphClassesRoot
        #(Get-GraphobjectNames).psobject.properties
        if((Get-GraphobjectNames).count -ne (@($Importedclasses).count))
        {
            New-GraphClasses
        }    
    }
}