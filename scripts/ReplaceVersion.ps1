param(
    [Parameter(Mandatory=$true)]
    $Version
)

Write-Verbose "Version is: $Version"

$files = Get-ChildItem *.psm1
foreach ($file in $files) {
    Write-Verbose "Writing version to file: $file"
    
    Update-ScriptFileInfo $file -Version $Version
}