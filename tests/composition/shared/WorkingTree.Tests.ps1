BeforeAll {
    . "$PSScriptRoot/../../helpers/TestHelpers.ps1"
    . "$PSScriptRoot/../../../src/composition/shared/Validate-EspalierWorkingTree.ps1"
}

Describe 'Working tree' {
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

    Context 'When the working tree is clean' {
        It 'accepts the composition' {
            {
                Validate-EspalierWorkingTree `
                    -RepositoryPath $composition.CordonPath
            } | Should -Not -Throw
        }
    }

    Context 'When a tracked file has unstaged changes' {
        BeforeEach {
            Add-TestGitFile `
                -RepositoryPath $composition.CordonPath `
                -RelativePath 'README.md' `
                -Content 'Modified working tree content'
        }

        It 'rejects the composition' {
            {
                Validate-EspalierWorkingTree `
                    -RepositoryPath $composition.CordonPath
            } | Should -Throw '*pending changes*'
        }
    }

    Context 'When a tracked file has staged changes' {
        BeforeEach {
            Add-TestGitFile `
                -RepositoryPath $composition.CordonPath `
                -RelativePath 'README.md' `
                -Content 'Modified staged content'

            Invoke-TestGit `
                -RepositoryPath $composition.CordonPath `
                -Arguments @(
                    'add',
                    '--',
                    'README.md'
                ) | Out-Null
        }

        It 'rejects the composition' {
            {
                Validate-EspalierWorkingTree `
                    -RepositoryPath $composition.CordonPath
            } | Should -Throw '*pending changes*'
        }
    }

    Context 'When an untracked file exists' {
        BeforeEach {
            Add-TestGitFile `
                -RepositoryPath $composition.CordonPath `
                -RelativePath 'untracked.txt' `
                -Content 'Untracked content'
        }

        It 'rejects the composition' {
            {
                Validate-EspalierWorkingTree `
                    -RepositoryPath $composition.CordonPath
            } | Should -Throw '*pending changes*'
        }
    }
}