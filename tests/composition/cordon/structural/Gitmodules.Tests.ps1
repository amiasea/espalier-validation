BeforeAll {
    . "$PSScriptRoot/../../../helpers/TestHelpers.ps1"
    . "$PSScriptRoot/../../../../src/composition/cordon/Validate-EspalierGitmodules.ps1"
}

Describe '.gitmodules' {
    BeforeEach {
        $compositionPath = Join-Path $TestDrive ([guid]::NewGuid().ToString())

        $composition = New-TestComposition `
            -Path $compositionPath `
            -Leaves @(
                @{
                    Name = 'leaf-alpha'
                    Path = 'leaf-alpha'
                }
            )
    }

    Context 'When .gitmodules is valid' {
        It 'accepts the composition' {
            {
                Validate-EspalierGitmodules `
                    -RepositoryPath $composition.CordonPath
            } | Should -Not -Throw
        }
    }

    Context 'When .gitmodules is missing from the committed tree' {
        BeforeEach {
            Invoke-TestGit `
                -RepositoryPath $composition.CordonPath `
                -Arguments @(
                    'rm',
                    '--cached',
                    '--',
                    '.gitmodules'
                ) | Out-Null

            Invoke-TestGit `
                -RepositoryPath $composition.CordonPath `
                -Arguments @(
                    'commit',
                    '-m',
                    'Remove .gitmodules'
                ) | Out-Null
        }

        It 'rejects the composition' {
            {
                Validate-EspalierGitmodules `
                    -RepositoryPath $composition.CordonPath
            } | Should -Throw '*does not contain a .gitmodules file*'
        }
    }

    Context 'When .gitmodules contains malformed configuration' {
        BeforeEach {
            Add-TestGitFile `
                -RepositoryPath $composition.CordonPath `
                -RelativePath '.gitmodules' `
                -Content @'
[submodule "leaf-alpha"
    path = leaf-alpha
    url = ../leaf-alpha
'@

            Invoke-TestGit `
                -RepositoryPath $composition.CordonPath `
                -Arguments @(
                    'add',
                    '--',
                    '.gitmodules'
                ) | Out-Null

            Invoke-TestGit `
                -RepositoryPath $composition.CordonPath `
                -Arguments @(
                    'commit',
                    '-m',
                    'Write malformed .gitmodules'
                ) | Out-Null
        }

        It 'rejects the composition' {
            {
                Validate-EspalierGitmodules `
                    -RepositoryPath $composition.CordonPath
            } | Should -Throw
        }
    }
}