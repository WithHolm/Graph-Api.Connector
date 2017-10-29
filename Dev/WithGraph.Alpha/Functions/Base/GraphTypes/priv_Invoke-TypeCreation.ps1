
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

    # if($Typedefinition.Abstract -eq $true)
    # {   $arr.add("$Tab $name ()")|out-null
    #     $arr.add("$Tab {")|out-null
    #     $arr.add("$Tab $Tab if ($('$this.GetType()') -eq [$name])")|out-null
    #     $arr.add("$Tab $Tab {")|out-null
    #     $arr.add("$Tab $Tab $tab $('throw("Class $($this.GetType()) must be inherited")')")|out-null
    #     $arr.add("$Tab $Tab }")|out-null
    #     $arr.add("$Tab }")|out-null
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
        "EntityType"{$out = $(New-GraphClass @splat)}
        "ComplexType"{$out = $(New-GraphClass @splat)}
        "EnumType"{$out = $(New-GraphEnum @splat)}
        default{Throw "Could not create a '$($Typedefinition.Localname)'. havent added code for that yet :("}
    }
    $ThisfileName = join-path "$script:GraphClassesRoot" "Class_$($Typedefinition.name)_$($version).ps1"
    [System.IO.File]::WriteAllText($ThisfileName,$($out -join "`r`n"))
}

Function New-GraphClasses
{
    get-childitem $PSScriptRoot -filter "lib"| Remove-Item -Recurse
    #[void](new-item "$PSScriptRoot\Lib" -ItemType Directory -ErrorAction SilentlyContinue)
    Write-host "Creating new classes from Graph Metadata (It may take a while..)"
    foreach ($version in (Get-GraphAPIConfigFile).graphversion.avalible)
    {
        write-host "Version: $version"
        $odata = get-odata $version
        $currentscriptpath = $myInvocation.MyCommand.Definition
        Write-host "    ComplexType $version"
        $usingversion = $version.replace('.','_')
        
        ($odata.ComplexType.GetEnumerator()).foreach{
            $param=@{
                Typedefinition = $_
                version = $usingversion
            }
            $(New-GraphType @param)
        }
        
        Write-host "    EntityType $version"
        ($odata.EntityType.GetEnumerator()).foreach{
            $param=@{
                Typedefinition = $_
                version = $usingversion
            }
            $(New-GraphType @param)
        }
        
        Write-host "    EnumType $version"
        ($odata.EnumType.GetEnumerator()).foreach{
            $param=@{
                Typedefinition = $_
                version = $usingversion
            }
            $(New-GraphType @param)
        }
    }

    Write-host "$((gci $script:GraphClassesRoot).count) Classes created"
}