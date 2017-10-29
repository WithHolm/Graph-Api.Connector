function Get-GraphEndpoints
{
    [cmdletbinding()]
    param(
        $version
    )

    $odata = get-odata $version
    #Foreach Object in entitycontainer, Find Endpointname, Entity-FQN, Entity-Name, Navigation-Expansions(Path,Target)
    # IE "groups","microsoft.graph.group","group",@{path=members, target=directoryObjects}
    
    $odata.entitycontainer.GetEnumerator().foreach{
        $Odataname = $_.name
        $entityFQDN = ($_.attributes.'#text').where{$_ -ne $Odataname}|select -first 1
        write-verbose "$entityFQDN"
        [pscustomobject]@{
            OdataName = $_.name
            EntityFQN = $entityFQDN
            Entityname = $($entityFQDN.split('.')[-1])         
            Expands = if($_.haschildnodes){$_.childnodes.foreach{[pscustomobject]@{path=$_.path;target=$_.target}}}
        }
    
    }
}