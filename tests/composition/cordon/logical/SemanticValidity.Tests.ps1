BeforeAll {
    . "$PSScriptRoot/../../../helpers/TestHelpers.ps1"
    . "$PSScriptRoot/../../../../src/composition/cordon/Validate-EspalierSemanticValidity.ps1"

    $pomologyPath = "$PSScriptRoot/../../../fixtures/pomology/valid.json"

    $pomology = Get-Content -LiteralPath $pomologyPath -Raw |
        ConvertFrom-Json -AsHashtable

    function New-TestPomology {
        param(
            [Parameter(Mandatory)]
            [scriptblock] $Modify
        )

        $testPomology = $pomology | ConvertTo-Json -Depth 100 |
            ConvertFrom-Json -AsHashtable

        & $Modify $testPomology

        return $testPomology
    }

    function New-TestCordon {
        $path = Join-Path $TestDrive ([guid]::NewGuid().ToString())

        return New-TestComposition `
            -Path $path `
            -Leaves @(
                @{
                    Name = 'host-api'
                    Path = 'host-api'
                }
            )
    }
}

Describe 'Validate-EspalierSemanticValidity' {
    BeforeEach {
        $env:ESPALIER_TARGET_BRANCH = 'development'
    }

    AfterAll {
        Remove-Item Env:ESPALIER_TARGET_BRANCH -ErrorAction SilentlyContinue
    }

    It 'accepts a Cordon whose Leaves have valid assignments for the selected variety' {
        $composition = New-TestCordon

        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-enterprise' `
                -Pomology $pomology `
                -Variety 'hermes'
        } | Should -Not -Throw
    }

    It 'rejects a variety that is not declared in Pomology' {
        $composition = New-TestCordon

        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-enterprise' `
                -Pomology $pomology `
                -Variety 'unknown'
        } | Should -Throw
    }

    It 'rejects a Leaf without an aspect-option assignment for the selected variety' {
        $composition = New-TestCordon

        $testPomology = New-TestPomology {
            param($definition)
            $definition.cordons.enterprise.leaves.'host-api'.options.Remove('hermes')
        }

        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-enterprise' `
                -Pomology $testPomology `
                -Variety 'hermes'
        } | Should -Throw
    }

    It 'rejects an aspect-option assignment that is not declared in Pomology' {
        $composition = New-TestCordon

        $testPomology = New-TestPomology {
            param($definition)
            $definition.cordons.enterprise.leaves.'host-api'.options.hermes = 'delta'
        }

        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-enterprise' `
                -Pomology $testPomology `
                -Variety 'hermes'
        } | Should -Throw
    }
}