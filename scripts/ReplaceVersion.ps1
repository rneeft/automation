param(
    [Parameter(Mandatory=$true)]
    $Version
)

Write-Verbose "Version is: $Version"

$files = Get-ChildItem *.psd1
foreach ($file in $files) {
    Write-Verbose "Writing version to file: $file"
    
    update-ModuleManifest -Path $file -ModuleVersion $Version
}