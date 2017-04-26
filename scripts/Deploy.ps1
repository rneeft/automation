param(
    [Parameter(Mandatory=$true)]
    $ApiKey,
    $NuGetVersion = "2.8.5.208",
    $NugetUrl = "https://dist.nuget.org/win-x86-commandline/latest/nuget.exe"
)

$nuGetProvider = Find-PackageProvider -Name "NuGet" -MinimumVersion $NuGetVersion
if ($nuGetProvider.Count > 0){
    Write-Verbose "Package Available."
} else {
    Write-Verbose "Package not available."
    Write-Host "Installing PackageProvider 'NuGet'..." -NoNewline
    Install-PackageProvider -Name "NuGet" -MinimumVersion $NuGetVersion -Scope CurrentUser -Force
    Write-Host "[OK]"
}

Write-Host "Downloading NuGet..." -NoNewline
Invoke-WebRequest $NugetUrl -OutFile "$PSScriptRoot\Nuget.exe"
$env:Path += ";$PSScriptRoot"
Write-Host "[OK]"

Publish-Script -Path DatabaseAutomation.ps1 -NuGetApiKey $ApiKey