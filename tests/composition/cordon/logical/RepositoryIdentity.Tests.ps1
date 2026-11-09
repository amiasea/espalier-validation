BeforeAll {
    $validatorPath = Join-Path $PSScriptRoot '../../../../src/composition/cordon/Validate-EspalierRepositoryIdentity.ps1'
    $pomologyPath = Join-Path $PSScriptRoot '../../../fixtures/pomology/valid.json'

    . $validatorPath

    function New-TestPomologyFile {
        param(
            [Parameter(Mandatory)]
            [scriptblock] $Modify
        )

        $pomology = Get-Content -LiteralPath $pomologyPath -Raw |
            ConvertFrom-Json -AsHashtable

        & $Modify $pomology

        $path = Join-Path $TestDrive ([guid]::NewGuid().ToString() + '.json')

        $pomology |
            ConvertTo-Json -Depth 100 |
            Set-Content -LiteralPath $path

        return $path
    }
}

Describe 'Validate-EspalierRepositoryIdentity' {
    It 'accepts a repository whose Cordon is declared in Pomology' {
        {
            Validate-EspalierRepositoryIdentity `
                -RepositoryName 'tannin-enterprise' `
                -PomologyPath $pomologyPath
        } | Should -Not -Throw
    }

    It 'rejects a repository whose Cordon is not declared in Pomology' {
        {
            Validate-EspalierRepositoryIdentity `
                -RepositoryName 'tannin-unknown' `
                -PomologyPath $pomologyPath
        } | Should -Throw
    }

    It 'rejects a repository name without a Solution and Cordon separator' {
        {
            Validate-EspalierRepositoryIdentity `
                -RepositoryName 'tannin' `
                -PomologyPath $pomologyPath
        } | Should -Throw
    }

    It 'rejects a repository name with an empty Cordon identity' {
        {
            Validate-EspalierRepositoryIdentity `
                -RepositoryName 'tannin-' `
                -PomologyPath $pomologyPath
        } | Should -Throw
    }

    It 'rejects a missing Pomology file' {
        {
            Validate-EspalierRepositoryIdentity `
                -RepositoryName 'tannin-enterprise' `
                -PomologyPath (Join-Path $TestDrive 'missing.json')
        } | Should -Throw
    }
}