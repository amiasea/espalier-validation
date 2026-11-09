function Validate-EspalierGitlinks {
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

    # Read submodule paths from the committed .gitmodules file.
    $declaredPaths = @(
        & git -C $repository config `
            --blob HEAD:.gitmodules `
            --get-regexp '^submodule\..*\.path$' 2>&1
    )
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0 -and $exitCode -ne 1) {
        $details = $declaredPaths -join [Environment]::NewLine

        throw "Failed to read submodule declarations in repository '$repository'.`nGit exited with code $exitCode.`n$details"
    }

    $declaredPaths = @(
        foreach ($line in $declaredPaths) {
            $parts = ([string] $line) -split '\s+', 2

            if ($parts.Count -eq 2) {
                $parts[1]
            }
        }
    )

    # Read Gitlink paths from the committed tree.
    $treeEntries = @(
        & git -C $repository ls-tree -r HEAD 2>&1
    )
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $details = $treeEntries -join [Environment]::NewLine

        throw "Failed to inspect Gitlinks in repository '$repository'.`nGit exited with code $exitCode.`n$details"
    }

    $gitlinkPaths = @(
        foreach ($line in $treeEntries) {
            $match = [regex]::Match(
                [string] $line,
                '^160000\s+commit\s+[0-9a-fA-F]{40,64}\s+(?<path>.+)$'
            )

            if ($match.Success) {
                $match.Groups['path'].Value
            }
        }
    )

    # Every declared submodule must have a corresponding Gitlink.
    $missingGitlinks = @(
        foreach ($path in $declaredPaths) {
            if ($path -notin $gitlinkPaths) {
                $path
            }
        }
    )

    if ($missingGitlinks.Count -gt 0) {
        $paths = $missingGitlinks |
            ForEach-Object { "  - $_" }

        throw "The following declared submodules do not have Gitlinks:`n$($paths -join [Environment]::NewLine)"
    }
}