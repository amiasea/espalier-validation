function Validate-EspalierGitlinkValidity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryPath
    )

    if (-not (Test-Path -LiteralPath $RepositoryPath -PathType Container)) {
        throw "Cordon repository path does not exist: $RepositoryPath"
    }

    $gitlinks = @(
        git -C $RepositoryPath ls-files --stage |
            ForEach-Object {
                if ($_ -match '^160000 ([0-9a-f]+) 0\s+(.+)$') {
                    [PSCustomObject]@{
                        Commit = $Matches[1]
                        Path   = $Matches[2]
                    }
                }
            }
    )

    foreach ($gitlink in $gitlinks) {
        $leafPath = Join-Path $RepositoryPath $gitlink.Path

        if (-not (Test-Path -LiteralPath $leafPath -PathType Container)) {
            throw "Leaf submodule '$($gitlink.Path)' is not initialized."
        }

        $mainCommit = git -C $leafPath rev-parse --verify refs/heads/main 2>$null

        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($mainCommit)) {
            throw "Leaf submodule '$($gitlink.Path)' does not have a local main branch."
        }

        git -C $leafPath merge-base --is-ancestor $gitlink.Commit $mainCommit 2>$null

        if ($LASTEXITCODE -ne 0) {
            throw "Gitlink '$($gitlink.Path)' commit '$($gitlink.Commit)' is not contained in the Leaf's main branch."
        }
    }

    return $gitlinks
}