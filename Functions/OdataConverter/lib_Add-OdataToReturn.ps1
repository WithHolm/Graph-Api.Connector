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
        $Version = ([uri]$OdataTag).AbsolutePath.Split('/')[0]
        $OdataEntityName = ([uri]$OdataTag).Fragment.replace
        $OdataType = if($OdataEntityName.EndsWith('/$entity')){}
    }
    process
    {    
        Write-Verbose "Object tag is $Tag"
        write-verbose "processing $($inndata.id)"
        #Get Entityset
        
        $ObjectDetails = Get-OdataEntityType -version $Version -Name $OdataEntityName
        
        $Inndata #.addpstypenames()
    }
    end
    {

    }
}

