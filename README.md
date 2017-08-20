# Automation
Provide scripts for (deployment) automation. It uses [DbUp](http://dbup.github.io) to publish the database scripts. 
>DbUp is a .NET library that helps you to deploy changes to SQL Server databases. It tracks which SQL scripts have been run already, and runs the change scripts that are needed to get your database up to date. [[DbUp](http://dbup.github.io)]

![Build Status](https://chr.visualstudio.com/_apis/public/build/definitions/2d33193a-77fd-4ddc-be87-12c73bc5ff99/17/badge)


# Usage & Examples
The script can be found in the [PowerShell Gallery](https://www.powershellgallery.com/packages/Automation.Database/). To install the script use the following instruction:
```powershell
C:\PS> Install-Module -Name Automation.Database 
```
Or use the following instruction which does not require administrative privileges
```powershell
C:\PS> Install-Module -Name Automation.Database -Scope CurrentUser -Force
```
 
## Get-DbUp
The Get-DbUp function downloads and extract a DbUp package specified URL. It is extracted to the local temp directory. The location of the DbUp.dll is returned. 

```powershell
C:\PS> Get-DbUp
```
Downloads the latest DbUp package and returns the binary location

```powershell
C:\PS> Get-DbUp -Url https://www.nuget.org/api/v2/package/dbup/3.3.5
```
Downloads the specified package and return the binary location

## Publish-DbUpScripts
Using DbUp to publish the scripts to database. DbUp keeps track of which scripts it needs to run.

```powershell
C:\PS> Publish-DbUpScripts -ConnectionString "Server=(localdb)\\mssqllocaldb;Database=Test" 
                           -DbUpPath "lib\dbup.dll" -DbScripts "\sql\"
```

Publish the scripts in folder sql\ to the specified connection string.

## New-Database
The ```New-Database``` function lets you create a new database within the specified connection string.
```powershell
C:\PS> New-Database -ConncetionString "Server=(localdb)\\mssqllocaldb" -DatabaseName  "MyDatabase"
```
This will create a database named: 'MyDatabase'.

## Test-Database
This function lets you check whether the specified databse already exist. 
```powershell
C:\PS> $databaseExist = Test-Database -ConnectionString "Server=(localdb)\\mssqllocaldb" -DatabaseName  "MyDatabase"
```
Checks whether the 'MyDatabase' database already exist

## Get-LocalDbConnectionString
Retrieves the connection string for the localDB instance. When the instance is not started, it will be started automatically. 
```powershell
C:\PS> $connectionString = Get-LocalDbConnectionString
```
Returns the connection string of the default Local DB instance 'mssqllocaldb'.

```powershell
C:\PS> sqllocaldb create "MyTestInstance"
C:\PS> $connectionString = Get-LocalDbConnectionString -InstanceName "MyTestInstance"
```
Returns the connection string of the just created local DB instance
