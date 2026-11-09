BeforeAll {
    $validatorPath = Join-Path `
        $PSScriptRoot `
        '../../../../src/composition/leaf/Validate-EspalierRepositoryIdentity.ps1'

    $pomologyPath = Join-Path `
        $PSScriptRoot `
        '../../../fixtures/pomology/valid.json'

    . $validatorPath
}

Describe 'Leaf repository identity' {
    Context 'when the repository identifies exactly one Leaf in Pomology' {
        It 'accepts a repository whose name contains the Solution prefix and Leaf name' {
            {
                Validate-EspalierRepositoryIdentity `
                    -RepositoryName 'tannin-host-api' `
                    -PomologyPath $pomologyPath
            } | Should -Not -Throw
        }
    }

    Context 'when the repository does not identify a Leaf in Pomology' {
        It 'rejects an unknown Leaf name' {
            {
                Validate-EspalierRepositoryIdentity `
                    -RepositoryName 'tannin-unknown' `
                    -PomologyPath $pomologyPath
            } | Should -Throw '*does not identify a Leaf in Pomology*'
        }
    }

    Context 'when the repository name does not follow the Solution naming convention' {
        It 'rejects a repository name without a hyphen' {
            {
                Validate-EspalierRepositoryIdentity `
                    -RepositoryName 'tannin' `
                    -PomologyPath $pomologyPath
            } | Should -Throw "*does not follow the '<solution>-<leaf>' convention*"
        }

        It 'rejects a repository name with an empty Leaf name' {
            {
                Validate-EspalierRepositoryIdentity `
                    -RepositoryName 'tannin-' `
                    -PomologyPath $pomologyPath
            } | Should -Throw "*does not follow the '<solution>-<leaf>' convention*"
        }
    }

    Context 'when the Leaf identity is ambiguous in Pomology' {
        It 'rejects a Leaf name declared in more than one Cordon' {
            $pomology = Get-Content `
                -LiteralPath $pomologyPath `
                -Raw |
                ConvertFrom-Json -AsHashtable

            $pomology.cordons['secondary'] = @{
                tier   = $null
                leaves = @{
                    'host-api' = @{
                        options = @{
                            hermes = 'gamma'
                        }
                    }
                }
            }

            $ambiguousPomologyPath = Join-Path `
                $TestDrive `
                'ambiguous-pomology.json'

            $pomology |
                ConvertTo-Json -Depth 100 |
                Set-Content -LiteralPath $ambiguousPomologyPath

            {
                Validate-EspalierRepositoryIdentity `
                    -RepositoryName 'tannin-host-api' `
                    -PomologyPath $ambiguousPomologyPath
            } | Should -Throw '*identifies more than one Leaf in Pomology*'
        }
    }

    Context 'when the Pomology file is missing' {
        It 'rejects a nonexistent Pomology path' {
            {
                Validate-EspalierRepositoryIdentity `
                    -RepositoryName 'tannin-host-api' `
                    -PomologyPath (Join-Path $TestDrive 'missing.json')
            } | Should -Throw '*Pomology file does not exist*'
        }
    }
}