function Validate-EspalierSemanticValidity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryName,

        [Parameter(Mandatory)]
        [string] $PomologyPath,

        [Parameter(Mandatory)]
        [string] $Variety,

        [Parameter(Mandatory)]
        [string] $SourceBranch,

        [Parameter(Mandatory)]
        [string] $TargetBranch
    )

    if (-not (Test-Path -LiteralPath $PomologyPath -PathType Leaf)) {
        throw "Pomology file does not exist: $PomologyPath"
    }

    try {
        $pomology = Get-Content -LiteralPath $PomologyPath -Raw |
            ConvertFrom-Json -AsHashtable -ErrorAction Stop
    }
    catch {
        throw "Unable to parse Pomology file '$PomologyPath': $($_.Exception.Message)"
    }

    if (-not $pomology.ContainsKey('varieties')) {
        throw 'Pomology does not contain a varieties definition.'
    }

    if ($Variety -notin $pomology.varieties) {
        throw "Variety '$Variety' is not declared in Pomology."
    }

    $identity = Validate-EspalierRepositoryIdentity `
        -RepositoryName $RepositoryName `
        -PomologyPath $PomologyPath

    $leaf = $pomology.cordons[$identity.Cordon].leaves[$identity.Leaf]

    if (
        $null -eq $leaf.options -or
        -not $leaf.options.ContainsKey($Variety)
    ) {
        throw "Leaf '$($identity.Leaf)' does not define an aspect-option assignment for variety '$Variety'."
    }

    $aspectOption = $leaf.options[$Variety]

    if (
        -not $pomology.ContainsKey('aspectOptions') -or
        $aspectOption -notin $pomology.aspectOptions
    ) {
        throw "Aspect option '$aspectOption' assigned to Leaf '$($identity.Leaf)' for variety '$Variety' is not declared in Pomology."
    }

    $expectedSourceBranch = "main-$aspectOption"

    if ($SourceBranch -cne $expectedSourceBranch) {
        throw "PR source branch must be '$expectedSourceBranch' for Leaf '$($identity.Leaf)' and variety '$Variety'; received '$SourceBranch'."
    }

    if ($TargetBranch -cne 'development') {
        throw "PR target branch must be 'development'; received '$TargetBranch'."
    }

    return [PSCustomObject]@{
        Cordon       = $identity.Cordon
        Leaf         = $identity.Leaf
        Variety      = $Variety
        AspectOption = $aspectOption
        SourceBranch = $SourceBranch
        TargetBranch = $TargetBranch
    }
}