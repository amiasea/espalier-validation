$ErrorActionPreference = 'Stop'

$helperFiles = @(
    'GitRepository.ps1'
    'Submodule.ps1'
    'Composition.ps1'
)

foreach ($file in $helperFiles) {
    $path = Join-Path $PSScriptRoot $file

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Test helper not found: $path"
    }

    . $path
}