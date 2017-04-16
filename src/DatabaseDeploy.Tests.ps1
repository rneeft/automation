$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
. "$here\$sut"

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
    #Making a failing test to test my build server
    It "Writes it in the colour Red"{
        Mock Write-Host {} -Verifiable -ParameterFilter {$ForegroundColor -eq "Red"}

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