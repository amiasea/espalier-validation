function Validate-EspalierSubmoduleInitialization {
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

    # Inspect only the Cordon's direct submodules.
    # This command does not initialize or update submodules.
    $output = @(
        & git -C $repository submodule status 2>&1
    )
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $details = $output -join [Environment]::NewLine

        throw "Failed to inspect submodule initialization in repository '$repository'.`nGit exited with code $exitCode.`n$details"
    }

    # An uninitialized submodule is represented by a '-' prefix.
    # Git status format:
    #   <status><commit> <path>
    #
    # Commit hashes may be 40 characters (SHA-1) or 64 characters
    # (SHA-256).
    $uninitialized = @(
        foreach ($line in $output) {
            $match = [regex]::Match(
                [string] $line,
                '^-(?<commit>[0-9a-fA-F]{40}|[0-9a-fA-F]{64})\s+(?<path>.+)$'
            )

            if ($match.Success) {
                $match.Groups['path'].Value
            }
        }
    )

    if ($uninitialized.Count -gt 0) {
        $paths = $uninitialized |
            ForEach-Object { "  - $_" }

        throw "The following submodules are not initialized:`n$($paths -join [Environment]::NewLine)`n`nInitialize the submodules before running Espalier validation."
    }
}