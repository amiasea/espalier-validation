BeforeAll {
    $validatorPath = Join-Path $PSScriptRoot '../../../../src/composition/leaf/Validate-EspalierSemanticValidity.ps1'
    $identityValidatorPath = Join-Path $PSScriptRoot '../../../../src/composition/leaf/Validate-EspalierRepositoryIdentity.ps1'
    $pomologyPath = Join-Path $PSScriptRoot '../../../fixtures/pomology/valid.json'

    . $identityValidatorPath
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

Describe 'Validate-EspalierSemanticValidity' {
    It 'accepts a PR from the assigned aspect-option main branch into development' {
        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-host-api' `
                -PomologyPath $pomologyPath `
                -Variety 'hermes' `
                -SourceBranch 'main-gamma' `
                -TargetBranch 'development'
        } | Should -Not -Throw
    }

    It 'rejects a variety that is not declared in Pomology' {
        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-host-api' `
                -PomologyPath $pomologyPath `
                -Variety 'unknown' `
                -SourceBranch 'main-gamma' `
                -TargetBranch 'development'
        } | Should -Throw
    }

    It 'rejects a repository that does not resolve to a Leaf in Pomology' {
        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-unknown' `
                -PomologyPath $pomologyPath `
                -Variety 'hermes' `
                -SourceBranch 'main-gamma' `
                -TargetBranch 'development'
        } | Should -Throw
    }

    It 'rejects a Leaf without an aspect-option assignment for the selected variety' {
        $path = New-TestPomologyFile {
            param($pomology)
            $pomology.cordons.enterprise.leaves.'host-api'.options.Remove('hermes')
        }

        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-host-api' `
                -PomologyPath $path `
                -Variety 'hermes' `
                -SourceBranch 'main-gamma' `
                -TargetBranch 'development'
        } | Should -Throw
    }

    It 'rejects an aspect-option assignment that is not declared in Pomology' {
        $path = New-TestPomologyFile {
            param($pomology)
            $pomology.cordons.enterprise.leaves.'host-api'.options.hermes = 'delta'
        }

        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-host-api' `
                -PomologyPath $path `
                -Variety 'hermes' `
                -SourceBranch 'main-delta' `
                -TargetBranch 'development'
        } | Should -Throw
    }

    It 'rejects a PR whose source branch is not the assigned aspect-option main branch' {
        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-host-api' `
                -PomologyPath $pomologyPath `
                -Variety 'hermes' `
                -SourceBranch 'main-delta' `
                -TargetBranch 'development'
        } | Should -Throw
    }

    It 'rejects a PR whose target branch is not development' {
        {
            Validate-EspalierSemanticValidity `
                -RepositoryName 'tannin-host-api' `
                -PomologyPath $pomologyPath `
                -Variety 'hermes' `
                -SourceBranch 'main-gamma' `
                -TargetBranch 'development-gamma'
        } | Should -Throw
    }
}