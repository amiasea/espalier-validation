function Invoke-TestGit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [string[]] $Arguments
    )

    if (-not (Test-Path -LiteralPath $RepositoryPath -PathType Container)) {
        throw "Git repository directory does not exist: $RepositoryPath"
    }

    $output = @(& git -C $RepositoryPath @Arguments 2>&1)
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $command = 'git -C "{0}" {1}' -f $RepositoryPath, ($Arguments -join ' ')
        $details = $output -join [Environment]::NewLine

        throw "Git command failed (exit code $exitCode): $command`n$details"
    }

    return $output
}

function New-TestGitRepository {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [string] $InitialBranch = 'main'
    )

    $parent = Split-Path -Parent $Path

    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (Test-Path -LiteralPath $Path) {
        throw "Repository path already exists: $Path"
    }

    New-Item -ItemType Directory -Path $Path -Force | Out-Null

    & git init --initial-branch=$InitialBranch $Path 2>&1 | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "Failed to initialize Git repository: $Path"
    }

    Invoke-TestGit -RepositoryPath $Path -Arguments @(
        'config', 'user.name', 'Espalier Tests'
    ) | Out-Null

    Invoke-TestGit -RepositoryPath $Path -Arguments @(
        'config', 'user.email', 'espalier-tests@example.invalid'
    ) | Out-Null

    return (Get-Item -LiteralPath $Path).FullName
}

function Add-TestGitCommit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [string] $Message
    )

    Invoke-TestGit -RepositoryPath $RepositoryPath -Arguments @(
        'add', '--all'
    ) | Out-Null

    Invoke-TestGit -RepositoryPath $RepositoryPath -Arguments @(
        'commit', '--message', $Message
    ) | Out-Null

    return (Invoke-TestGit -RepositoryPath $RepositoryPath -Arguments @(
        'rev-parse', 'HEAD'
    ) | Select-Object -Last 1).ToString().Trim()
}

function Add-TestGitFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [string] $RelativePath,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string] $Content
    )

    $filePath = Join-Path $RepositoryPath $RelativePath
    $directory = Split-Path -Parent $filePath

    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force |
            Out-Null
    }

    Set-Content -LiteralPath $filePath -Value $Content -NoNewline
}

function New-TestGitBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [string] $Branch,

        [string] $StartPoint = 'HEAD'
    )

    Invoke-TestGit -RepositoryPath $RepositoryPath -Arguments @(
        'branch', $Branch, $StartPoint
    ) | Out-Null

    return (Get-TestGitBranchCommit `
        -RepositoryPath $RepositoryPath `
        -Branch $Branch)
}

function Set-TestGitBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [string] $Branch
    )

    Invoke-TestGit -RepositoryPath $RepositoryPath -Arguments @(
        'switch', $Branch
    ) | Out-Null
}

function Get-TestGitBranchCommit {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [string] $Branch
    )

    return (Invoke-TestGit -RepositoryPath $RepositoryPath -Arguments @(
        'rev-parse', "$Branch^{commit}"
    ) | Select-Object -Last 1).ToString().Trim()
}

function Merge-TestGitBranch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [string] $Branch,

        [Parameter(Mandatory)]
        [string] $Message
    )

    Invoke-TestGit -RepositoryPath $RepositoryPath -Arguments @(
        'merge',
        '--no-ff',
        '--no-edit',
        '--message', $Message,
        $Branch
    ) | Out-Null

    return (Invoke-TestGit -RepositoryPath $RepositoryPath -Arguments @(
        'rev-parse', 'HEAD'
    ) | Select-Object -Last 1).ToString().Trim()
}

function Test-TestGitAncestor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [string] $Ancestor,

        [Parameter(Mandatory)]
        [string] $Descendant
    )

    & git -C $RepositoryPath merge-base `
        --is-ancestor $Ancestor $Descendant 2>&1 | Out-Null

    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        return $true
    }

    if ($exitCode -eq 1) {
        return $false
    }

    throw "Failed to inspect Git ancestry in repository '$RepositoryPath'. Git exited with code $exitCode."
}