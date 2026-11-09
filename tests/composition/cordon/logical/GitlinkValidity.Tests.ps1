BeforeAll {
    . "$PSScriptRoot/../../../helpers/TestHelpers.ps1"

    $validatorPath = "$PSScriptRoot/../../../../src/composition/cordon/Validate-EspalierGitlinkValidity.ps1"
    . $validatorPath

    function New-TestCordon {
        $path = Join-Path $TestDrive ([guid]::NewGuid().ToString())

        New-TestComposition `
            -Path $path `
            -Leaves @(
                @{
                    Name = 'host-api'
                    Path = 'host-api'
                }
            )
    }

    function Set-TestGitlinkCommit {
        param(
            [Parameter(Mandatory)]
            [string] $CordonPath,

            [Parameter(Mandatory)]
            [string] $SubmodulePath
        )

        Invoke-TestGit `
            -RepositoryPath $CordonPath `
            -Arguments @('add', '--', $SubmodulePath)

        Add-TestGitCommit `
            -RepositoryPath $CordonPath `
            -Message 'Update Leaf Gitlink'
    }
}

Describe 'Validate-EspalierGitlinkValidity' {
    It 'accepts a Gitlink pointing to the Leaf main branch commit' {
        $composition = New-TestCordon

        {
            Validate-EspalierGitlinkValidity `
                -RepositoryPath $composition.CordonPath
        } | Should -Not -Throw
    }

    It 'accepts a Gitlink pointing to an earlier commit contained in the Leaf main branch' {
        $composition = New-TestCordon
        $leafPath = Join-Path $composition.CordonPath 'host-api'

        Set-TestGitBranch `
            -RepositoryPath $leafPath `
            -Branch 'main'

        Add-TestGitFile `
            -RepositoryPath $leafPath `
            -RelativePath 'later.txt' `
            -Content 'A later main-branch commit'

        Add-TestGitCommit `
            -RepositoryPath $leafPath `
            -Message 'Advance Leaf main'

        {
            Validate-EspalierGitlinkValidity `
                -RepositoryPath $composition.CordonPath
        } | Should -Not -Throw
    }

    It 'rejects a Gitlink pointing to a commit that exists only on another Leaf branch' {
        $composition = New-TestCordon
        $leafPath = Join-Path $composition.CordonPath 'host-api'

        New-TestGitBranch `
            -RepositoryPath $leafPath `
            -Branch 'development'

        Set-TestGitBranch `
            -RepositoryPath $leafPath `
            -Branch 'development'

        Add-TestGitFile `
            -RepositoryPath $leafPath `
            -RelativePath 'development.txt' `
            -Content 'A development-only commit'

        Add-TestGitCommit `
            -RepositoryPath $leafPath `
            -Message 'Development-only commit'

        Set-TestGitlinkCommit `
            -CordonPath $composition.CordonPath `
            -SubmodulePath 'host-api'

        {
            Validate-EspalierGitlinkValidity `
                -RepositoryPath $composition.CordonPath
        } | Should -Throw
    }
}