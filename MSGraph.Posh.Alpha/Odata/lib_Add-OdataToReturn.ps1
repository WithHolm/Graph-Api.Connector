function Add-OdataToReturn
{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   Position=0)]
        $Inndata,

        [String]$OdataTag
    )

    begin
    {
        #write-verbose ([uri]$OdataTag).AbsolutePath.split('/')[1]
        Write-Verbose "tag: $OdataTag"
        $Version = ([uri]$OdataTag).AbsolutePath.Split('/')[1]
        $OdataEntityName = ([uri]$OdataTag).Fragment.replace('#data','')   
        #write-verbose "$OdataEntityName"    
        $OdataType = $(if($OdataEntityName.EndsWith('/$entity')){$OdataEntityName.Split('/')[0]}else{$OdataEntityName}).replace('#','')
        Write-Verbose "Object tag is '$OdataType'"
        $Entityname = Get-OdataEntityType -version $Version -Name $OdataType
    }
    process
    {      
        write-verbose "processing $($Entityname): $($inndata.id)"
        $Inndata.pstypenames.insert(0,"$Entityname.$Version")
        $Inndata
    }
    end
    {

    }
}

