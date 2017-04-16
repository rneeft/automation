function Test-SQLConnectionString{    
	<#
	.LINK
	Source of this method: http://stackoverflow.com/questions/29229109/test-database-connectivity [Martin Brandl]
	#>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true, Position=0)]
        $ConnectionString
    )
    try
    {
        $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $ConnectionString;
        $sqlConnection.Open();
        $sqlConnection.Close();

        return $true;
    }
    catch
    {
        return $false;
    }
}

function Get-DbUp {
	<#
	.SYNOPSIS
	Downloads the DbUp binary
	.DESCRIPTION
	The Get-DbUp function downloads and extract a DbUp package specified URL. It is extracted to the local temp directory. The location of the DbUp.dll is returned. 
	.PARAMETER url
	URL that contains the location of the online DbUp zip/nupkg file. Default: https://www.nuget.org/api/v2/package/dbup/
	.OUTPUTS 
	System.string containing the location of the DbUp.dll binary
	.EXAMPLE
	Get-DbUp
	Downloads the package https://www.nuget.org/api/v2/package/dbup/ and returns the location of the DbUp.dll location
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
		$Url="https://www.nuget.org/api/v2/package/dbup/"
	)

	$dbUpTempPath ="$env:TEMP\dbup"
	$dbUpZipLocation = "$env:TEMP\DbUp.zip"

	try{
		Write-Status "Deleting old packages... "
		Remove-Item $dbUpZipLocation -Force -ErrorAction SilentlyContinue
		Remove-Item $dbUpTempPath -Force -Recurse -ErrorAction SilentlyContinue
		Write-Succeed

		Write-Status "Downloading package... "
		Invoke-WebRequest $url -OutFile $dbUpZipLocation
		Write-Succeed
		
		Write-Status "Expand archive... " 
		Expand-Archive $dbUpZipLocation -DestinationPath $dbUpTempPath
		Write-Succeed

		Write-Status "Locating DbUp... "
		$dbupPath = Get-ChildItem -Path $dbUpTempPath -Filter "DbUp.dll" -Recurse -ErrorAction SilentlyContinue -Force |
					Select-Object -First 1  | 
					ForEach-Object { $_.FullName }
		if (!$dbupPath) {
			throw [System.IO.FileNotFoundException] "DbUp.dll location cannot be found"
		}
		Write-Succeed
		
		return $dbupPath;
	}
	Catch {
		Write-Fail
		throw
	}
}

function Write-Status{
	[cmdletbinding()]
	param (
		[Parameter(Mandatory=$true)]
		[Object]$message
	)
	Write-Host "$message... " -NoNewline
}

function Write-Succeed{
	Write-Host "[Succeed]" -ForegroundColor Green
}

function Write-Fail{
	Write-Host "[Fail]" -ForegroundColor Red
}