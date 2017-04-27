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
    Write-Status "Installing PackageProvider 'NuGet'"
    Install-PackageProvider -Name "NuGet" -MinimumVersion $NuGetVersion -Scope CurrentUser -Force
    Write-Succeed
}

Write-Status "Downloading NuGet"
Invoke-WebRequest $NugetUrl -OutFile "$PSScriptRoot\Nuget.exe"
$env:Path += ";$PSScriptRoot"
Write-Succeed

Write-Status "Publishing module: 'DatabaseAutomation'"
Publish-Module -Path DatabaseAutomation.psm1 -NuGetApiKey $ApiKey
Write-Succeed

function Write-Succeed{
	Write-Host "[Succeed]" -ForegroundColor Green
}

function Write-Status{
	[cmdletbinding()]
	param (
		[Parameter(Mandatory=$true)]
		[Object]$message
	)
	Write-Host "$message... " -NoNewline
}