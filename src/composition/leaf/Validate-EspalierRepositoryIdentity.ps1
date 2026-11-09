function Validate-EspalierRepositoryIdentity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryName,

        [Parameter(Mandatory)]
        [string] $PomologyPath
    )

    if (-not (Test-Path -LiteralPath $PomologyPath -PathType Leaf)) {
        throw "Pomology file does not exist: $PomologyPath"
    }

    $repositorySegments = $RepositoryName -split '-', 2

    if (
        $repositorySegments.Count -ne 2 -or
        [string]::IsNullOrWhiteSpace($repositorySegments[0]) -or
        [string]::IsNullOrWhiteSpace($repositorySegments[1])
    ) {
        throw "Repository name does not follow the '<solution>-<leaf>' convention: $RepositoryName"
    }

    $leafName = $repositorySegments[1]

    try {
        $pomology = Get-Content -LiteralPath $PomologyPath -Raw |
            ConvertFrom-Json -AsHashtable -ErrorAction Stop
    }
    catch {
        throw "Unable to parse Pomology file '$PomologyPath': $($_.Exception.Message)"
    }

    if (-not $pomology.ContainsKey('cordons')) {
        throw 'Pomology does not contain a cordons definition.'
    }

    $matches = @(
        foreach ($cordon in $pomology.cordons.GetEnumerator()) {
            if ($null -ne $cordon.Value.leaves -and
                $cordon.Value.leaves.ContainsKey($leafName)) {
                [PSCustomObject]@{
                    Cordon = $cordon.Key
                    Leaf   = $leafName
                }
            }
        }
    )

    if ($matches.Count -eq 0) {
        throw "Repository '$RepositoryName' does not identify a Leaf in Pomology."
    }

    if ($matches.Count -gt 1) {
        throw "Repository '$RepositoryName' identifies more than one Leaf in Pomology."
    }

    return $matches[0]
}