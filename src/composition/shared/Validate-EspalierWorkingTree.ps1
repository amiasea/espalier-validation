function Validate-EspalierWorkingTree {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string] $RepositoryPath
    )

    if (-not (Test-Path -LiteralPath $RepositoryPath -PathType Container)) {
        throw "Repository directory does not exist: $RepositoryPath"
    }

    $repository = (Resolve-Path -LiteralPath $RepositoryPath).Path

    # Inspect staged, unstaged, and untracked changes.
    # Ignored files are excluded.
    $output = @(
        & git -C $repository status --porcelain --untracked-files=all 2>&1
    )
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $details = $output -join [Environment]::NewLine

        throw "Failed to inspect working tree in repository '$repository'.`nGit exited with code $exitCode.`n$details"
    }

    if ($output.Count -gt 0) {
        $changes = $output |
            ForEach-Object { "  $_" }

        throw "The repository contains pending changes:`n$($changes -join [Environment]::NewLine)"
    }
}