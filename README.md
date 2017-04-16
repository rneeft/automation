# Automation
Provide scripts for (deployment) automation

![Build Status](https://chr.visualstudio.com/_apis/public/build/definitions/2d33193a-77fd-4ddc-be87-12c73bc5ff99/17/badge)

Usage
===
Loading the functions
```powershell
C:\PS>. .\DatabaseDeploy.ps1
```

Get-DbUp
-------------
The Get-DbUp function downloads and extract a DbUp package specified URL. It is extracted to the local temp directory. The location of the DbUp.dll is returned. 

```powershell
C:\PS> Get-DbUp
```
Downloads the latest DbUp package and returns the binary location

```powershell
C:\PS> Get-DbUp -Url https://www.nuget.org/api/v2/package/dbup/3.3.5
```
Downloads the specified package and return the binary location
