BeforeAll {
    . "$PSScriptRoot/../../../helpers/TestHelpers.ps1"
    . "$PSScriptRoot/../../../../src/composition/cordon/Validate-EspalierGitlinks.ps1"
}

Describe 'Gitlinks' {
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

    Context 'When every declared submodule has a Gitlink' {
        It 'accepts the composition' {
            {
                Validate-EspalierGitlinks `
                    -RepositoryPath $composition.CordonPath
            } | Should -Not -Throw
        }
    }

    Context 'When a declared submodule has no Gitlink' {
        BeforeEach {
            # Remove the Gitlink from the index while retaining
            # the .gitmodules declaration.
            Invoke-TestGit `
                -RepositoryPath $composition.CordonPath `
                -Arguments @(
                    'update-index',
                    '--force-remove',
                    '--',
                    'leaf-alpha'
                ) | Out-Null

            Invoke-TestGit `
                -RepositoryPath $composition.CordonPath `
                -Arguments @(
                    'commit',
                    '-m',
                    'Remove submodule Gitlink'
                ) | Out-Null
        }

        It 'rejects the composition' {
            {
                Validate-EspalierGitlinks `
                    -RepositoryPath $composition.CordonPath
            } | Should -Throw '*Gitlink*'
        }
    }
}