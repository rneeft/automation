
function Get-DbUp {
	<#
	.SYNOPSIS
	Downloads the DbUp binary
	.DESCRIPTION
	The Get-DbUp function downloads and extract a DbUp package specified URL. It is extracted to the local temp directory. The location of the DbUp.dll is returned. 
	.PARAMETER url
	URL that contains the location of the online DbUp zip/nupkg file. Default: https://www.nuget.org/api/v2/package/dbup/3.3.5
	.OUTPUTS 
	System.string containing the location of the DbUp.dll binary
	.EXAMPLE
	Get-DbUp
	Downloads the package https://www.nuget.org/api/v2/package/dbup/3.3.5 and returns the location of the DbUp.dll location
	.EXAMPLE
	Get-DbUp -URL https://custom.location.com/package/myDbUp/1.0.0
	Downloads the package from the custom location
	.LINK
	DbUp docs: https://dbup.readthedocs.io/
	Questions about this script: rick@chroomsoft.nl
	#>
	[CmdletBinding()]
	param
	(
		$Url="https://www.nuget.org/api/v2/package/dbup/3.3.5"
	)

	$dbUpTempPath ="$env:TEMP\dbup"
	$dbUpZipLocation = "$env:TEMP\DbUp.zip"

	try{
		Write-Host "Deleting old packages... " -NoNewline
		Remove-Item $dbUpZipLocation -Force -ErrorAction SilentlyContinue
		Remove-Item $dbUpTempPath -Force -Recurse -ErrorAction SilentlyContinue
		Write-Host "[Succeed]" -ForegroundColor Green

		Write-Host "Downloading package... " -NoNewline
		Invoke-WebRequest $Url -OutFile $dbUpZipLocation
		Write-Host "[Succeed]" -ForegroundColor Green

		Write-Host "Expand archive... " -NoNewline
		Expand-Archive $dbUpZipLocation -DestinationPath $dbUpTempPath
		Write-Host "[Succeed]" -ForegroundColor Green

		Write-Host "Locating DbUp... " -NoNewline
		$dbupPath = Get-ChildItem -Path $dbUpTempPath -Filter "DbUp.dll" -Recurse -ErrorAction SilentlyContinue -Force |
					Select-Object -First 1 | 
					ForEach-Object { $_.FullName }
		if (!$dbupPath) {
			throw [System.IO.FileNotFoundException] "DbUp.dll location cannot be found"
		}

		Write-Host "[Succeed]" -ForegroundColor Green 
		return $dbupPath
	}
	Catch {
		Write-Host "[Failed]" -ForegroundColor Red
		throw
	}
}