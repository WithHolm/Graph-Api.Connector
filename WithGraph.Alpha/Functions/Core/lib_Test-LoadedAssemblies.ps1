function test-loadedAssembiles
{
    $test = [appdomain]::currentdomain.getassemblies()|where{$_.location -like '*Microsoft.Open.Azure.AD.CommonLibrary.dll'}
    
}