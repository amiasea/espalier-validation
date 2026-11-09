function New-TestComposition {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Path,

        [Parameter(Mandatory)]
        [hashtable[]] $Leaves
    )

    if (Test-Path -LiteralPath $Path) {
        throw "Composition path already exists: $Path"
    }

    $cordonPath = Join-Path $Path 'cordon'
    $leafRoot = Join-Path $Path 'leaves'

    New-Item -ItemType Directory -Path $leafRoot -Force | Out-Null

    $cordon = New-TestGitRepository -Path $cordonPath
    $leafResults = @()

    foreach ($leaf in $Leaves) {
        if (-not $leaf.Name -or -not $leaf.Path) {
            throw 'Each Leaf must define Name and Path.'
        }

        $leafRepositoryPath = Join-Path $leafRoot $leaf.Name

        $leafRepository = New-TestGitRepository `
            -Path $leafRepositoryPath

        Add-TestGitFile `
            -RepositoryPath $leafRepository `
            -RelativePath 'README.md' `
            -Content "# $($leaf.Name)`n"

        $leafCommit = Add-TestGitCommit `
            -RepositoryPath $leafRepository `
            -Message 'Initial Leaf commit'

        Add-TestGitSubmodule `
            -CordonPath $cordon `
            -LeafPath $leafRepository `
            -SubmodulePath $leaf.Path

        $leafResults += [PSCustomObject]@{
            Name           = $leaf.Name
            Path           = $leaf.Path
            RepositoryPath = $leafRepository
            Commit         = $leafCommit
        }
    }

    $cordonCommit = Add-TestGitCommit `
        -RepositoryPath $cordon `
        -Message 'Initial Cordon composition'

    Initialize-TestGitSubmodules -RepositoryPath $cordon

    return [PSCustomObject]@{
        Root          = (Get-Item -LiteralPath $Path).FullName
        CordonPath    = $cordon
        CordonCommit  = $cordonCommit
        Leaves        = $leafResults
    }
}