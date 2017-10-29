function import-GraphClass
{
    [cmdletbinding()]
    param(
        [String]$name,
        [Switch]$dependency
    )

    #$odata = Get-Odata
    # write-verbose "Loading $classname from $script:GraphClassesRoot"
    # get-childitem $script:GraphClassesRoot -Filter "class_$classname*"|%{. $_.FullName}
    # return $(Convertto-GraphClass -classname $classname -data $data -classarray $classarray)
    #write-verbose $script:importedclasses.count
    if($name -notin $script:importedclasses)
    {
        Write-Verbose "Loading '$name' for the first time"
        $version = $((Get-GraphVersion).avalible -like "*$($name.split('_')[1])*")
        $usingversion = $version.replace('.','_')
        $object = (Get-GraphobjectNames -Version $version).where{
            $_.name -eq $($name.split('_')[0])
        }

        if(!([String]::IsNullOrEmpty($object.DependsOn)))
        {
            Write-Verbose "Loading dependency '$($object.DependsOn)_$usingversion'"
            $(import-GraphClass -name "$($object.DependsOn)_$usingversion" -dependency)
        }

        $void = get-childitem $script:GraphClassesRoot -Filter "class_$name*"|%{
            Write-verbose "Found $($_.name)"
            . $_.FullName
            #[void]$([scriptblock]::Create("[$name]::new()")).invoke()
            $script:importedclasses += $_
            if($dependency)
            {
                return $null
            }
        }
    }

    #$([scriptblock]::Create("[$name]::new()")).invoke()
}