<#
.SYNOPSIS
Create a new database
.DESCRIPTION
Create a new Local DB database on the connectionString
.PARAMETER ConnectionString
SQL Connection String pointing to the master database
.PARAMETER DatabaseName
The name of the database to create
.EXAMPLE
New-LocalDbDatabase -DatabaseName "MyDb" -ConnectionString "servername='server'"
Creates the databse 'MyDb' on the specified connection string
.LINK
Questions about this script: rick@chroomsoft.nl
#>
function New-Database {
	[CmdletBinding()]
    param(
		[Parameter(Mandatory=$true)]
		$DatabaseName,
		[Parameter(Mandatory=$true)]
		$ConnectionString
	)

	Invoke-LocalDbSqlcmd -Command "create database $DatabaseName" -ConnectionString $ConnectionString
}

<#
.SYNOPSIS
Publish the scripts to the Database
.DESCRIPTION
Using DbUp to publish the scripts to database. DbUp keeps track of which scripts it needs to run.
.PARAMETER ConnectionString
SQL Connection String pointing to a existing database
.PARAMETER DbUpPath
Path pointing to the location of the DbUp.dll binary
.PARAMETER DbScripts
Path pointing oo the location of the SQL scripts. The folder must contain SQL scripts
.EXAMPLE
Publish-DbUpScripts -ConnectionString "Server=(localdb)\\mssqllocaldb;Database=Test" -DbUpPath "lib\dbup.dll" -DbScripts "\sql\"
Publish the scripts in folder sql\ to the specified connection string.	
.LINK
DbUp docs: https://dbup.readthedocs.io/
Questions about this script: rick@chroomsoft.nl
.LINK
Get-DbUp
#>
function Publish-DbUpScripts {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true)]
		$ConnectionString,
		[Parameter(Mandatory=$true)]
		$DbUpPath,
		[Parameter(Mandatory=$true)]
		$DbScripts
	)
	If (!(Test-SQLConnectionString($ConnectionString))) {
		throw "ConnectionString wrongly formatted";
	}
	if (!(Test-DbUplocation($DbUpPath))) {
		throw [System.IO.FileNotFoundException] "DbUp.dll location cannot be found"
	}
	if (!(Test-DbScriptsPath($DbScripts))) {
		throw [System.IO.FileNotFoundException] "Scripts path cannot be found or does not contain sql scripts"
	}

	Add-Type -Path $DbUpPath

	$dbUp = [DbUp.DeployChanges]::To
	$dbUp = [SqlServerExtensions]::SqlDatabase($dbUp, $ConnectionString)
 	$dbUp = [StandardExtensions]::WithScriptsFromFileSystem($dbUp, $scriptPath)
	$dbUp = [SqlServerExtensions]::JournalToSqlTable($dbUp, 'dbo', 'SchemaVersions')
	$dbUp = [StandardExtensions]::LogToConsole($dbUp)

	Start-DbUp($dbUp);
}

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
function Get-DbUp {
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
		Expand-Archive $dbUpZipLocation -DestinationPath $dbUpTempPath -Force
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

<#
.SYNOPSIS
Determines whether the database exist.
.DESCRIPTION
The Test-Database function determines whether the specified database exist.
.PARAMETER ConnectionString
SQL Connection String pointing to the master database
.PARAMETER DatabaseName
The name of the database to check
.OUTPUTS 
System.Boolean, true when database exist otherwise false
.EXAMPLE
Test-Database -ConnectionString "servername='server'" -DatabaseName "MyDb"
Test whether the database MyDb exist
.LINK
Questions about this script: rick@chroomsoft.nl
#>
function Test-Database() {
	[OutputType([Boolean])]
	[CmdletBinding()]
    param(
		[Parameter(Mandatory=$true)]
		$ConnectionString,
		[Parameter(Mandatory=$true)]
		$DatabaseName
	)

	$allDatabases = Invoke-LocalDbSqlcmd -Command "sp_databases" -ConnectionString $ConnectionString

	return $allDatabases.Contains($DatabaseName);
}

<#
.SYNOPSIS
Gets the connection string from of the LocalDB instance
.DESCRIPTION
The Get-LocalDbConnectionString returns the connection string to connect to a local Db instance. It defaults retrieves the connection string from the instance mssqllocaldb. If the instance is not running the function will starts the instance.
.PARAMETER InstanceName
The instance from which the connection string must be retrieved. Default: mssqllocaldb
.OUTPUTS 
System.string containing the connection string
.EXAMPLE
Get-LocalDbConnectionString
Returns the connection string from the instance mssqllocaldb
.EXAMPLE
Get-LocalDbConnectionString -InstanceName "MyInstance"
Returns the connection string from the instance MyInstance
.LINK
Questions about this script: rick@chroomsoft.nl
#>
function Get-LocalDbConnectionString() {
	[OutputType([String])]
	[CmdletBinding()]
    param(
		$InstanceName = "mssqllocaldb"
	)

    sqllocaldb start $InstanceName | Out-Null
	$instanceInfo = sqllocaldb info $InstanceName | Out-String
	return (($instanceInfo).split(" ")[-1]).Trim()
}

function Invoke-LocalDbSqlcmd{
	[OutputType([String])]
	[CmdletBinding()]
    param(
		[Parameter(Mandatory=$true)]
		$Command,
		[Parameter(Mandatory=$true)]
		$ConnectionString
	)

	$databases = sqlcmd -E -S $ConnectionString -Q $Command | Out-String

	return $database;
}

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

function Start-DbUp($dbUp){
	return $dbUp.Build().PerformUpgrade()
}

function Test-DbUplocation($location){
	return Test-Path $location
}

function Test-DbScriptsPath($location){
	if (!(Test-Path $location)){
		return $false;
	}

 	$items = Get-ChildItem -Path $location -Filter "*.sql" | Measure-Object
	return !($items.Count -eq 0)
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
