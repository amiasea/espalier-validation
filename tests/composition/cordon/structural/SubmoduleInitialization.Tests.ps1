BeforeAll {
    . "$PSScriptRoot/../../../helpers/TestHelpers.ps1"

    # Load the actual validation implementation here.
    # This must be the same implementation invoked by action.yml.
}

BeforeAll {
    . "$PSScriptRoot/../../../helpers/TestHelpers.ps1"
    . "$PSScriptRoot/../../../../src/composition/cordon/Validate-EspalierSubmoduleInitialization.ps1"
}

Describe 'Submodule initialization' {
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

    Context 'When all declared submodules are initialized' {
        It 'accepts the composition' {
            {
                Validate-EspalierSubmoduleInitialization `
                    -RepositoryPath $composition.CordonPath
            } | Should -Not -Throw
        }
    }

    Context 'When a declared submodule is not initialized' {
        BeforeEach {
            Invoke-TestGit `
                -RepositoryPath $composition.CordonPath `
                -Arguments @(
                    'submodule',
                    'deinit',
                    '--force',
                    '--',
                    'leaf-alpha'
                ) | Out-Null
        }

        It 'rejects the composition' {
            {
                Validate-EspalierSubmoduleInitialization `
                    -RepositoryPath $composition.CordonPath
            } | Should -Throw '*not initialized*'
        }
    }
}