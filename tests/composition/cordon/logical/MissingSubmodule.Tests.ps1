BeforeAll {
    . "$PSScriptRoot/../../../helpers/TestHelpers.ps1"

    . "$PSScriptRoot/../../../../src/composition/cordon/Validate-EspalierMissingSubmodule.ps1"

    $pomologyPath = "$PSScriptRoot/../../../fixtures/pomology/valid.json"

    $pomology = Get-Content -LiteralPath $pomologyPath -Raw |
        ConvertFrom-Json -AsHashtable

    function New-TestPomology {
        param(
            [Parameter(Mandatory)]
            [scriptblock] $Modify
        )

        $testPomology = $pomology |
            ConvertTo-Json -Depth 100 |
            ConvertFrom-Json -AsHashtable

        & $Modify $testPomology

        return $testPomology
    }

    function New-TestCordon {
        param(
            [Parameter(Mandatory)]
            [string[]] $Leaves
        )

        $path = Join-Path $TestDrive ([guid]::NewGuid().ToString())

        New-TestComposition `
            -Path $path `
            -Leaves @(
                foreach ($leaf in $Leaves) {
                    @{
                        Name = $leaf
                        Path = $leaf
                    }
                }
            )
    }
}

Describe 'Validate-EspalierMissingSubmodule' {
    It 'accepts a Cordon containing every Leaf declared in Pomology' {
        $testPomology = New-TestPomology {
            param($definition)

            $definition.cordons.enterprise.leaves['worker'] = @{
                options = @{
                    hermes = 'gamma'
                }
            }
        }

        $composition = New-TestCordon -Leaves @('host-api', 'worker')

        {
            Validate-EspalierMissingSubmodule `
                -RepositoryName 'tannin-enterprise' `
                -RepositoryPath $composition.CordonPath `
                -Pomology $testPomology
        } | Should -Not -Throw
    }

    It 'rejects a Cordon missing a Leaf declared in Pomology' {
        $testPomology = New-TestPomology {
            param($definition)

            $definition.cordons.enterprise.leaves['worker'] = @{
                options = @{
                    hermes = 'gamma'
                }
            }
        }

        $composition = New-TestCordon -Leaves @('host-api')

        {
            Validate-EspalierMissingSubmodule `
                -RepositoryName 'tannin-enterprise' `
                -RepositoryPath $composition.CordonPath `
                -Pomology $testPomology
        } | Should -Throw
    }
}