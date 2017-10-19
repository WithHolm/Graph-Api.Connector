
function Findtype
{
    [cmdletbinding()]
    param(
        $Typestring,
        $version
        )
    begin{
        write-verbose "Processing $typestring"
        $return = "["
    }
    process{
        Switch -wildcard ($Typestring){
            "Edm.*"{
                $Type = ""
                switch($_)
                {
                    "Edm.String"{$Type = "String"}
                    "Edm.Binary"{$type = "String"}
                    "Edm.Date"{$type = "DateTime"}
                    "Edm.DateTimeOffset"{$type = "DateTime"}
                    "Edm.Duration"{$type = "TimeSpan"}#
                    "Edm.TimeOfDay"{$type = "TimeSpan"}
                    "Edm.Stream"{$type = "String"}#
                    default {$Type = $_.replace("Edm.","")}
                }
                #Trying to invoke the type just to see if it finds it. If not, throw       
                try
                {
                    $sb = [scriptblock]::Create("[$type]")
                    $sb.Invoke()|out-null
                }
                catch
                {
                    Throw "Could not create clr type from Edm type '$Typestring'"
                }
                $return += $Type
            }
            "Collection(*"{
                $InnerObject = Findtype -typestring $([regex]::Match("$_",'(\((.*)\))').groups[2].value) -version $version
                $return += "System.Collections.ObjectModel.Collection$InnerObject" }
            "microsoft.graph.*"{$return += "$($typestring.split('.')[-1])_$version"}
        }
    }
    end{
        $return += "]"
        $return
    }
}

Function New-GraphClass
{
    [cmdletbinding()]
    param(
        $Typedefinition,
        $version
    )

    $Tab = "   "
    $arr = [System.Collections.ArrayList]::new()
    $name = "$($Typedefinition.name)_$($version)"
    $Title = [String]::Format("Class {0}{1}",
                    $name,
                    $(if($Typedefinition.basetype -ne $null)
                    {
                        ":$($Typedefinition.basetype.split('.')[-1])_$version"
                    }
                    else
                    {''}))

    $arr.add($title)|Out-Null
    $arr.add("{")|Out-Null
    foreach($property in $Typedefinition.property)
    {
        #$property
        $type = Findtype -typestring $property.type -version $version
        $arr.add("    {0} {1}{2}" -f @($type,'$', $property.Name))|out-null
    }

    if($Typedefinition.Abstract -eq $true)
    {   $arr.add("$Tab $name ()")|out-null
        $arr.add("$Tab {")|out-null
        $arr.add("$Tab $Tab if ($('$this.GetType()') -eq [$name])")|out-null
        $arr.add("$Tab $Tab {")|out-null
        $arr.add("$Tab $Tab $tab $('throw("Class $($this.GetType()) must be inherited")')")|out-null
        $arr.add("$Tab $Tab }")|out-null
        $arr.add("$Tab }")|out-null
    }
    # else{
    #     $arr.add("$Tab $name()")|Out-Null
    #     $arr.add("$Tab {}")|Out-Null
    #     $arr.add("")|Out-Null
    #     $arr.add("$Tab $name([pscustomobject]$('$')psobject)")|Out-Null
    #     $arr.add("$Tab {")|Out-Null
    #     $arr.add("$Tab $Tab $('$psobject.psobject.properties.where{$_.value -ne $null}.foreach{')")|Out-Null
    #     $arr.add("$Tab $Tab $('$this.$($_.name) = $_.value')")|Out-Null
    #     $arr.add("$Tab $Tab }")|Out-Null
    #     $arr.add("$Tab }")|Out-Null
        
    # }
    $arr.add("")|Out-Null
    $arr.add("}")|Out-Null
    $arr
}

Function New-GraphEnum
{
    [cmdletbinding()]
    param(
        $Typedefinition,
        $version
    )

    $arr = [System.Collections.ArrayList]::new()
    $name = "$($Typedefinition.name)_$($version)"
    $arr.add("enum $name")|Out-Null
    $arr.add("{")|Out-Null
    foreach($member in $Typedefinition.Member)
    {
        $arr.add("    $($member.name) = $($member.value)")|Out-Null
    }
    $arr.add("}")|Out-Null
    $arr
}
Function New-GraphType
{    
    [cmdletbinding()]
    param(
        $Typedefinition,
        $version
    )
    $splat=@{
        Typedefinition = $Typedefinition
        Version = $version
    }
    Switch($Typedefinition.Localname)
    {
        "EntityType"{$(New-GraphClass @splat)}
        "ComplexType"{$(New-GraphClass @splat)}
        "EnumType"{$(New-GraphEnum @splat)}
        default{Throw "Could not create a '$($Typedefinition.Localname)'. havent added code for that yet :("}
    }

}

get-childitem $PSScriptRoot -Filter "class_*" | Remove-Item
$version = "beta"
$filename = "$PSScriptRoot\Class_$version.ps1"
$odata = get-odata $version
$ClassArr = [System.Collections.ArrayList]::new()

Write-output "ComplexType"
($odata.ComplexType.GetEnumerator()).foreach{
    $param=@{
        Typedefinition = $_
        version = $version
    }
    $ClassArr.AddRange($(New-GraphType @param))
}

Write-output "EntityType"
($odata.EntityType.GetEnumerator()).foreach{
    $param=@{
        Typedefinition = $_
        version = $version
    }
    $ClassArr.AddRange($(New-GraphType @param))
}

Write-output "EnumType"
($odata.EnumType.GetEnumerator()).foreach{
    $param=@{
        Typedefinition = $_
        version = $version
    }
    $ClassArr.AddRange($(New-GraphType @param))
}

Write-output "To file"
$ClassArr | out-file $filename -Append

Write-output "Load File"
. $filename

#[user_beta]::new(((invoke-graphcall -Call users).value|select -First 1))|gm