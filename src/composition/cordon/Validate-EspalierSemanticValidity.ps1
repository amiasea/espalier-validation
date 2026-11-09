function Validate-EspalierSemanticValidity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $RepositoryName,

        [Parameter(Mandatory)]
        [hashtable] $Pomology,

        [Parameter(Mandatory)]
        [string] $Variety
    )

    if ($env:ESPALIER_TARGET_BRANCH -cne 'development') {
        throw "PR target branch must be 'development'; received '$env:ESPALIER_TARGET_BRANCH'."
    }

    if (-not $Pomology.ContainsKey('varieties')) {
        throw 'Pomology does not contain a varieties definition.'
    }

    if ($Variety -notin $Pomology.varieties) {
        throw "Variety '$Variety' is not declared in Pomology."
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

    if (-not $Pomology.ContainsKey('aspectOptions')) {
        throw 'Pomology does not contain an aspectOptions definition.'
    }

    foreach ($leafEntry in $cordon.leaves.GetEnumerator()) {
        $leafName = $leafEntry.Key
        $leafDefinition = $leafEntry.Value

        if (
            $null -eq $leafDefinition.options -or
            -not $leafDefinition.options.ContainsKey($Variety)
        ) {
            throw "Leaf '$leafName' does not define an aspect-option assignment for variety '$Variety'."
        }

        $aspectOption = $leafDefinition.options[$Variety]

        if ($aspectOption -notin $Pomology.aspectOptions) {
            throw "Aspect option '$aspectOption' assigned to Leaf '$leafName' for variety '$Variety' is not declared in Pomology."
        }
    }

    return [PSCustomObject]@{
        Cordon  = $cordonName
        Variety = $Variety
        Leaves  = @(
            foreach ($leafEntry in $cordon.leaves.GetEnumerator()) {
                [PSCustomObject]@{
                    Name         = $leafEntry.Key
                    AspectOption = $leafEntry.Value.options[$Variety]
                }
            }
        )
    }
}