function Validate-EspalierGitmodules {
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

    # Verify that .gitmodules exists in the committed tree.
    $output = @(
        & git -C $repository cat-file -e 'HEAD:.gitmodules' 2>&1
    )
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "The committed repository does not contain a .gitmodules file: $repository"
    }

    # Parse the committed .gitmodules file as Git configuration.
    $output = @(
        & git -C $repository config `
            --blob HEAD:.gitmodules `
            --list 2>&1
    )
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $details = $output -join [Environment]::NewLine

        throw "The committed .gitmodules file contains invalid Git configuration in repository '$repository'.`nGit exited with code $exitCode.`n$details"
    }
}