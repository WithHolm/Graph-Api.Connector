<#
.SYNOPSIS
adds the data you choose to a class you choose. the class itself must be imported to the current session
.DESCRIPTION
Long description
.PARAMETER classname
the name of the class you want to assign to the $data. the class must be in the current session before you run this command. 
the classname is derived from the odata string in the graph-call
.PARAMETER data
data in the graphcall
.PARAMETER classarray
this is a array to distinct if the properties in the chosen classname is a custom class or .net class. 
if this is not given in the code that calls this function, it will call upon this itself, but it will hurt executiontime badly 
adds about 12ms for each round, and a graphuser this is loaded 4-5 times = about 60ms per user added execution time. 
.EXAMPLE
An example
.NOTES
General notes
#>
Function Set-GraphClassData
{
    [cmdletbinding()]
    param(
        [string]$classname,
        [psobject]$data,
        [array]$classarray
    )
    write-verbose "processing data with class '$classname'"
    $returnobject = $([scriptblock]::Create("[$classname]::new()")).invoke()|Select-Object -first 1

    if ($classarray -eq $null)
    {
        $classarray = (get-GraphobjectNames).foreach{"$($_.name)_$($_.version)"}
    }
    #$returnobject.psobject.properties
    @($data.psobject.properties|where {$_.value -ne $null}).foreach{
        $thisprop = $_
        #write-verbose $("adding '{0}' to {1}" -f $_.name,$returnobject.gettype().name)
        $thistype = $returnobject.psobject.properties.where{$_.name -eq $thisprop.name}
        if ($thistype.TypeNameOfValue.StartsWith("System.Collections.ObjectModel.Collection"))
        {
            $Subclass = $([regex]::match($thistype.TypeNameOfValue, '\[\[(.+?),')).groups[1].value
            @($thisprop.value).foreach{
                #write-verbose "Class: $Subclass, is in classarray: $($Subclass -in $classarray)"
                if ($Subclass -in $classarray)
                {
                    $d = Set-GraphClassData -classname $Subclass -data $_ -classarray $classarray
                }
                else 
                {
                    $d = $_
                }
                $propname = $($thisprop.name)
                $returnobject."$propname".add($d)
            }
        }
        else
        {
            $returnobject.$($thisprop.name) = $thisprop.value
        }

        # switch -wildcard ($thistype.TypeNameOfValue)
        # {
        #     "System.Collections.ObjectModel.Collection*"
        #     {                       
        #         $Subclass = $([regex]::match($_, '\[\[(.+?),')).groups[1].value
        #         @($thisprop.value).foreach{
        #             #write-verbose "Class: $Subclass, is in classarray: $($Subclass -in $classarray)"
        #             if ($Subclass -in $classarray)
        #             {
        #                 $d = Set-GraphClassData -classname $Subclass -data $_
        #             }
        #             else 
        #             {
        #                 $d = $_
        #             }
        #             $propname = $($thisprop.name)
        #             $returnobject."$propname".add($d)
        #         }
        #     }
        #     default
        #     {
        #         $returnobject.$($thisprop.name) = $thisprop.value
        #     }
        # }
    }
    $returnobject
}