BeforeAll {
    . "$PSScriptRoot/../../../helpers/TestHelpers.ps1"

    . "$PSScriptRoot/../../../../src/composition/cordon/Validate-EspalierUnexpectedSubmodule.ps1"

    $pomologyPath = "$PSScriptRoot/../../../fixtures/pomology/valid.json"

    $pomology = Get-Content -LiteralPath $pomologyPath -Raw |
        ConvertFrom-Json -AsHashtable
}

Describe 'Validate-EspalierUnexpectedSubmodule' {
    It 'accepts a Cordon containing only Leaves declared in Pomology' {
        $composition = New-TestComposition `
            -Path (Join-Path $TestDrive ([guid]::NewGuid().ToString())) `
            -Leaves @(
                @{
                    Name = 'host-api'
                    Path = 'host-api'
                }
            )

        {
            Validate-EspalierUnexpectedSubmodule `
                -RepositoryName 'tannin-enterprise' `
                -RepositoryPath $composition.CordonPath `
                -Pomology $pomology
        } | Should -Not -Throw
    }

    It 'rejects a Cordon containing a submodule not declared in Pomology' {
        $composition = New-TestComposition `
            -Path (Join-Path $TestDrive ([guid]::NewGuid().ToString())) `
            -Leaves @(
                @{
                    Name = 'host-api'
                    Path = 'host-api'
                },
                @{
                    Name = 'worker'
                    Path = 'worker'
                }
            )

        {
            Validate-EspalierUnexpectedSubmodule `
                -RepositoryName 'tannin-enterprise' `
                -RepositoryPath $composition.CordonPath `
                -Pomology $pomology
        } | Should -Throw
    }
}