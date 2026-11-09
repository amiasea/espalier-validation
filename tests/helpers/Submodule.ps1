function Add-TestGitSubmodule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $CordonPath,

        [Parameter(Mandatory)]
        [string] $LeafPath,

        [Parameter(Mandatory)]
        [string] $SubmodulePath
    )

    if (-not (Test-Path -LiteralPath $LeafPath -PathType Container)) {
        throw "Leaf repository does not exist: $LeafPath"
    }

    Invoke-TestGit -RepositoryPath $CordonPath -Arguments @(
        '-c',
        'protocol.file.allow=always',
        'submodule',
        'add',
        $LeafPath,
        $SubmodulePath
    ) | Out-Null
}

function Initialize-TestGitSubmodules {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    Invoke-TestGit -RepositoryPath $RepositoryPath -Arguments @(
        '-c',
        'protocol.file.allow=always',
        'submodule',
        'update',
        '--init',
        '--recursive'
    ) | Out-Null
}

function Get-TestGitSubmoduleStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    return Invoke-TestGit -RepositoryPath $RepositoryPath -Arguments @(
        'submodule', 'status', '--recursive'
    )
}