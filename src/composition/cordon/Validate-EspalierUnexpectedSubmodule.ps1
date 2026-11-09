function Validate-EspalierUnexpectedSubmodule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryName,

        [Parameter(Mandatory)]
        [string] $RepositoryPath,

        [Parameter(Mandatory)]
        [hashtable] $Pomology
    )

    if (-not (Test-Path -LiteralPath $RepositoryPath -PathType Container)) {
        throw "Cordon repository path does not exist: $RepositoryPath"
    }

    $repositorySegments = $RepositoryName -split '-', 2

    if (
        $repositorySegments.Count -ne 2 -or
        [string]::IsNullOrWhiteSpace($repositorySegments[0]) -or
        [string]::IsNullOrWhiteSpace($repositorySegments[1])
    ) {
        throw "Repository name does not follow the '<solution>-<cordon>' convention: $RepositoryName"
    }

    $cordonName = $repositorySegments[1]

    if (
        -not $Pomology.ContainsKey('cordons') -or
        -not $Pomology.cordons.ContainsKey($cordonName)
    ) {
        throw "Repository '$RepositoryName' does not identify a Cordon in Pomology."
    }

    $cordon = $Pomology.cordons[$cordonName]

    if ($null -eq $cordon.leaves -or $cordon.leaves.Count -eq 0) {
        throw "Cordon '$cordonName' does not declare any Leaves in Pomology."
    }

    $declaredLeaves = @($cordon.leaves.Keys)

    $gitlinks = @(
        git -C $RepositoryPath ls-files --stage |
            ForEach-Object {
                if ($_ -match '^160000 [0-9a-f]+ 0\s+(.+)$') {
                    $Matches[1]
                }
            }
    )

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to read Gitlinks from Cordon repository '$RepositoryPath'."
    }

    $unexpectedSubmodules = @(
        foreach ($gitlink in $gitlinks) {
            if ($gitlink -notin $declaredLeaves) {
                $gitlink
            }
        }
    )

    if ($unexpectedSubmodules.Count -gt 0) {
        throw "Cordon '$cordonName' contains the following undeclared Leaf submodules: $($unexpectedSubmodules -join ', ')."
    }

    return [PSCustomObject]@{
        Cordon = $cordonName
        Leaves = $gitlinks
    }
}