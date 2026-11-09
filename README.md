# Espalier Validation Action

A GitHub Action for validating Espalier Leaf and Cordon compositions against a Solution's Pomology definition.

The action provides two independent validation targets:

- **Leaf** — validates a Leaf repository's identity and logical validity for a selected variety.
- **Cordon** — validates a Cordon repository's structure and its logical correspondence with the Leaves declared in Pomology.

## Usage

Invoke the action from a pull request workflow:

```yaml
name: Validate Espalier Composition

on:
  pull_request:
    branches:
      - development

permissions:
  contents: read

jobs:
  validate:
    runs-on: ubuntu-latest

    steps:
      - name: Check out repository
        uses: actions/checkout@v4
        with:
          submodules: true

      - name: Validate composition
        uses: amiasea/espalier-validation-action@v1
        with:
          type: cordon
          pomology: path/to/pomology.json
          variety: hermes
```

For a Leaf repository, set `type` to `leaf`:

```yaml
      - name: Validate composition
        uses: amiasea/espalier-validation-action@v1
        with:
          type: leaf
          pomology: path/to/pomology.json
          variety: hermes
```

The selected variety must be declared in the supplied Pomology definition.

## Inputs

| Input | Required | Description |
|---|---|---|
| `type` | Yes | Composition type to validate: `cordon` or `leaf`. |
| `pomology` | Yes | Path to the Pomology JSON document. Relative paths are resolved from the checked-out repository root. |
| `variety` | Yes | Solution variety selected for validation. |

The repository name is obtained from the GitHub event context. For Leaf validation, the source and target branches are obtained from the pull request event.

## Validation

Validation runs in two phases: structural validation followed by logical validation. A failure in either phase fails the action.

### Shared validation

Both composition types require a clean working tree:

- No staged changes.
- No unstaged changes.
- No untracked files.

Ignored files do not count as pending changes.

### Leaf validation

Logical validation establishes:

- The repository identifies exactly one Leaf declared in Pomology.
- The selected variety is declared in Pomology.
- The Leaf assigns an aspect option for the selected variety.
- The assigned aspect option is declared in Pomology.
- The pull request source branch is `main-[aspect-option]`.
- The pull request target branch is `development`.

### Cordon validation

Structural validation establishes:

- `.gitmodules` is consistent with the repository's Gitlinks.
- Gitlinks are structurally valid.
- Every declared submodule is initialized.

Logical validation establishes:

- The repository identifies a Cordon declared in Pomology.
- The selected variety is declared in Pomology.
- Every Leaf declared by the Cordon assigns a valid aspect option for the selected variety.
- Every direct submodule corresponds to a Leaf declared in Pomology.
- Every declared Leaf has a corresponding direct submodule.
- Each Gitlink references a commit contained in the corresponding Leaf's `main` branch.

A Gitlink may reference an earlier commit as long as that commit remains reachable from `main`.

## Responsibilities

This action validates the checked-out repository. It does not:

- Check out the repository.
- Initialize or update submodules.
- Fetch remote branches or commits.
- Create branches, commits, or pull requests.
- Merge aspect-option branches.
- Recursively inspect nested compositions.
- Publish releases or attestations.

The calling workflow is responsible for checking out the repository and preparing its submodules before invoking the action.

## Development

The implementation is written in PowerShell and organized by composition type and validation responsibility:

```text
src/
├── composition/
│   ├── shared/
│   ├── cordon/
│   └── leaf/
├── pomology.cue
└── Validate-Composition.ps1

tests/
├── composition/
│   ├── shared/
│   ├── cordon/
│   │   ├── structural/
│   │   └── logical/
│   └── leaf/
│       └── logical/
├── fixtures/
└── helpers/
```

Tests use Pester and temporary Git repositories to exercise validation against realistic repository states.

## License

See [LICENSE](LICENSE).