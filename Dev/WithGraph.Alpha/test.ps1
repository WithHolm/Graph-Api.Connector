#$PSScriptRoot.Replace('\','⧹')



# $loadedassembly = (([Threading.Thread]::GetDomain().GetAssemblies()).where{$_.ManifestModule -like "*Class_beta.ps1"})
# ($loadedassembly.DefinedTypes).count
# # ⧹C։⧹git⧹MSGraph.Posh.Alpha⧹Dev⧹WithGraph.Alpha⧹Functions⧹Classes⧹Class_beta.ps1

# # [byte][char]'⧹'
([Threading.Thread]::GetDomain().GetAssemblies()).where{$_.ManifestModule -like "*Class_beta.ps1"}|fl