$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

Describe "Test-DbScriptPath"{
    It "Returns False when directory does not contains SQL scripts"{
        New-Item "db" -ItemType Directory -Force
        Test-DbScriptsPath "db" | Should Be $false
        Remove-Item "db"
    }
    It "Returns False when path does not exist"{
        Test-DbScriptsPath "db" | Should Be $false
    }
}

Describe "Test-SQLConnectionString"{
    It "Returns False when connection string is incorrect"{
        $connectionString = "server=(localdb)\mssqllocaldb;database=master;Trusted_Connection=Yes;Connection Timeout=120;"

        Test-SQLConnectionString $connectionString | Should Be $true
    }
    It "Returns True when connection string is correct"{
        $connectionString = "blah"
        
        Test-SQLConnectionString $connectionString | Should Be $false
    }
}

Describe "Write-Status"{
    It "Writes the text without a new line"{
        Mock Write-Host -Verifiable -ParameterFilter {$NoNewline -eq $true}

        Write-Status "Hello World"

        Assert-VerifiableMocks
    }

    It "Writes the message with at the end ...<space>"{
        Mock Write-Host -Verifiable -ParameterFilter {$Object -eq "Hello World... "}

        Write-Status "Hello World"
        
        Assert-VerifiableMocks
    }
}

Describe "Write-Succeed"{
    It "Writes [Succeed] to the host"{
        Mock Write-Host {} -Verifiable -ParameterFilter {$Object -eq "[Succeed]"}

        Write-Succeed

        Assert-VerifiableMocks
    }
    It "Writes it in the colour Green"{
        Mock Write-Host {} -Verifiable -ParameterFilter {$ForegroundColor -eq "Green"}

         Write-Succeed

        Assert-VerifiableMocks
    }
}

Describe "Write-Fail"{
    It "Writes [Fail] to the host"{
        Mock Write-Host {} -Verifiable -ParameterFilter {$Object -eq "[Fail]"}

        Write-Fail

        Assert-VerifiableMocks
    }
    It "Writes it in the colour Red"{
        Mock Write-Host {} -Verifiable -ParameterFilter {$ForegroundColor -eq "Red"}

        Write-Fail

        Assert-VerifiableMocks
    }
}

Describe "Get-DbUp" {
    Mock Write-Status {}
    Mock Write-Succeed {}
    
    $dbUpTempPath ="$env:TEMP\dbup"
	$dbUpZipLocation = "$env:TEMP\DbUp.zip"

    Context "Get-DbUp is called with the default setting"{
        Mock Invoke-WebRequest -ParameterFilter {$uri -eq "https://www.nuget.org/api/v2/package/dbup/", $OutFile -eq $zipLocation}

        $result = Get-DbUp

        It "Downloads the default location"{
            Assert-VerifiableMocks
        }

        It "Returns the DbUp binary location" {
            $result | Should Be "$env:TEMP\dbup\lib\NET35\dbup.dll"
        }
    }

    Context "Get-DbUp is called with different url"{
        $myUrl = "https://www.nuget.org/api/v2/package/dbup/1.0.8"
        Mock Invoke-WebRequest -ParameterFilter {$uri -eq $myUrl, $OutFile -eq $zipLocation}

        $result = Get-DbUp $myUrl

        It "Donwloads the specified location"{
            Assert-VerifiableMocks
        }
    }

    Context "Get-DbUp is called with an invalid url" {
        $myUrl = "https://www.google.com"
        Mock Write-Fail {}
        try {
                $result = Get-DbUp $myUrl
        }
        catch {
        }

         It "Shows the [Fail] message" {
             Assert-MockCalled Write-Fail  
         }
    }
}

Describe "Publish-DbUpScripts"{
    Mock Write-Status {}
    Mock Write-Succeed {}

    Context "Wrong paramters"{
        It "Throws exception when connection string is empty" {
            Mock Test-SQLConnectionString {return $false}
            { Publish-DbUpScripts -ConnectionString "blah" "C:\dbup.dll" -DbScripts "C:\db\" } | Should Throw
        }
        It "Throws exception when DbUp Path not exist" {
            Mock Test-SQLConnectionString { return $true}
            Mock Test-DbUplocation  { return $false }
            { Publish-DbUpScripts -ConnectionString "blah" -DbUpPath "C:\dbup.dll" -DbScripts "C:\db\" } | Should Throw "DbUp.dll location cannot be found"
        }
        It "Throws exception when Scripts Path does not exists" {
            Mock Test-SQLConnectionString { return $true}
            Mock Test-DbUplocation  { return $true }
            Mock Test-DbScriptsPath { return $false } 
            { Publish-DbUpScripts -ConnectionString "blah" -DbUpPath "C:\dbup.dll"  -DbScripts "C:\db\" } | Should Throw "Scripts path cannot be found or does not contain sql scripts"
        }
    }

    Context "Correct parameters"{
        $dbUp = "$PSScriptRoot\DbUp.dll"
        $connectionString = "Server=(localdb)\\mssqllocaldb;Database=Pester"
        $dbScripts = "db"

        Copy-Item "$PSScriptRoot\..\test\dbup.dll" -Destination $dbUp

        Mock Start-DbUp
        Mock Test-DbScriptsPath { return $true }
        Mock Test-SQLConnectionString { return $true}

        $result = Publish-DbUpScripts -ConnectionString $connectionString -DbUpPath $dbUp -DbScripts $dbScripts
        
        It "Create an dbup object and sends it to the builder" {
            Assert-MockCalled Start-DbUp
        }
        It "Does not lock the DbUp binary"{
           Remove-Item $dbUp
        }
    }
}