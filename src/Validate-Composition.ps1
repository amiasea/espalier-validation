[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$sourceRoot = Join-Path $PSScriptRoot 'composition'

$compositionType = $env:ESPALIER_TYPE
$repositoryName = $env:ESPALIER_REPOSITORY_NAME
$repositoryPath = $env:GITHUB_WORKSPACE
$pomologyPath = $env:ESPALIER_POMOLOGY
$variety = $env:ESPALIER_VARIETY

if ($compositionType -notin @('cordon', 'leaf')) {
    throw "Invalid composition type '$compositionType'. Expected 'cordon' or 'leaf'."
}

if ([string]::IsNullOrWhiteSpace($repositoryName)) {
    throw 'The repository name was not supplied.'
}

if ([string]::IsNullOrWhiteSpace($repositoryPath)) {
    throw 'GITHUB_WORKSPACE was not supplied.'
}

if (-not (Test-Path -LiteralPath $repositoryPath -PathType Container)) {
    throw "Repository path does not exist: $repositoryPath"
}

if ([string]::IsNullOrWhiteSpace($pomologyPath)) {
    throw 'The Pomology path was not supplied.'
}

if (-not [System.IO.Path]::IsPathRooted($pomologyPath)) {
    $pomologyPath = Join-Path $repositoryPath $pomologyPath
}

if (-not (Test-Path -LiteralPath $pomologyPath -PathType Leaf)) {
    throw "Pomology file does not exist: $pomologyPath"
}

& cue vet -c (Join-Path $PSScriptRoot 'pomology.cue') $pomologyPath

if ($LASTEXITCODE -ne 0) {
    throw 'Pomology validation against pomology.cue failed.'
}

if ([string]::IsNullOrWhiteSpace($variety)) {
    throw 'The selected variety was not supplied.'
}

Write-Host "Validating $compositionType composition '$repositoryName'."

# Structural validation

Write-Host 'Running shared structural validation...'

. (Join-Path $sourceRoot 'shared/Validate-EspalierWorkingTree.ps1')

Validate-EspalierWorkingTree `
    -RepositoryPath $repositoryPath |
    Out-Null

if ($compositionType -eq 'cordon') {
    $structuralValidators = @(
        'cordon/Validate-EspalierGitmodules.ps1'
        'cordon/Validate-EspalierGitlinks.ps1'
        'cordon/Validate-EspalierSubmoduleInitialization.ps1'
    )

    Write-Host 'Running Cordon structural validation...'

    foreach ($validator in $structuralValidators) {
        . (Join-Path $sourceRoot $validator)

        $functionName = [System.IO.Path]::GetFileNameWithoutExtension($validator)

        & $functionName `
            -RepositoryPath $repositoryPath |
            Out-Null
    }
}

# Logical validation

Write-Host 'Running logical validation...'

if ($compositionType -eq 'leaf') {
    . (Join-Path $sourceRoot 'leaf/Validate-EspalierRepositoryIdentity.ps1')
    . (Join-Path $sourceRoot 'leaf/Validate-EspalierSemanticValidity.ps1')

    Validate-EspalierRepositoryIdentity `
        -RepositoryName $repositoryName `
        -PomologyPath $pomologyPath |
        Out-Null

    Validate-EspalierSemanticValidity `
        -RepositoryName $repositoryName `
        -PomologyPath $pomologyPath `
        -Variety $variety `
        -SourceBranch $env:ESPALIER_SOURCE_BRANCH `
        -TargetBranch $env:ESPALIER_TARGET_BRANCH |
        Out-Null
}
else {
    $pomology = Get-Content -LiteralPath $pomologyPath -Raw |
        ConvertFrom-Json -AsHashtable -ErrorAction Stop

    . (Join-Path $sourceRoot 'cordon/Validate-EspalierRepositoryIdentity.ps1')
    . (Join-Path $sourceRoot 'cordon/Validate-EspalierSemanticValidity.ps1')
    . (Join-Path $sourceRoot 'cordon/Validate-EspalierGitlinkValidity.ps1')
    . (Join-Path $sourceRoot 'cordon/Validate-EspalierMissingSubmodule.ps1')
    . (Join-Path $sourceRoot 'cordon/Validate-EspalierUnexpectedSubmodule.ps1')

    Validate-EspalierRepositoryIdentity `
        -RepositoryName $repositoryName `
        -PomologyPath $pomologyPath |
        Out-Null

    Validate-EspalierSemanticValidity `
        -RepositoryName $repositoryName `
        -Pomology $pomology `
        -Variety $variety |
        Out-Null

    Validate-EspalierGitlinkValidity `
        -RepositoryPath $repositoryPath |
        Out-Null

    Validate-EspalierMissingSubmodule `
        -RepositoryName $repositoryName `
        -RepositoryPath $repositoryPath `
        -Pomology $pomology |
        Out-Null

    Validate-EspalierUnexpectedSubmodule `
        -RepositoryName $repositoryName `
        -RepositoryPath $repositoryPath `
        -Pomology $pomology |
        Out-Null
}

Write-Host "Successfully validated $compositionType composition '$repositoryName'."