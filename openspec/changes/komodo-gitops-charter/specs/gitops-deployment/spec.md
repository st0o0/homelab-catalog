## Purpose

Defines Komodo ResourceSync as the repository's sole deployment mechanism: stacks are declared host-agnostically under `stacks/`, and host assignment, server inventory, and shared variables are declared separately under `komodo/resources/`.

## ADDED Requirements

### Requirement: Stack definitions are host-agnostic
Each deployable stack SHALL be defined under `stacks/<service>/` (compose file(s), `.env.example`, optional README) without embedding a specific target host, so any stack can be assigned to any capable server without modifying its compose or env files.

#### Scenario: Stack reassigned to a different host
- **WHEN** a stack's server assignment changes to a different host in `komodo/resources/stacks.toml`
- **THEN** no files under `stacks/<service>/` need to change

### Requirement: Host assignment is declared via ResourceSync, not directory structure
Which server a stack deploys to SHALL be declared exclusively in `komodo/resources/stacks.toml`. Directory paths under `stacks/` SHALL NOT encode a host.

#### Scenario: New host added
- **WHEN** a new server is added to `komodo/resources/servers.toml`
- **THEN** existing or new stacks can be assigned to it by editing `komodo/resources/stacks.toml` alone, without moving, renaming, or nesting any files under `stacks/`

### Requirement: Single deployment mechanism
The repository SHALL expose exactly one mechanism for getting a stack running on a host: Komodo ResourceSync. No parallel catalog-publishing mechanism SHALL exist alongside it.

#### Scenario: Repository contains no Dockhand artifacts
- **WHEN** the repository tree is inspected after this change
- **THEN** `templates/`, `scripts/build.ps1`, `stacks/dockhand/`, `stacks/hawser/`, and `docs/` do not exist, and no CI workflow builds, validates, or publishes `templates.json`

#### Scenario: No stack depends on a Dockhand server
- **WHEN** any `stacks/<service>/` compose or env file is inspected after this change
- **THEN** none of them reference a Dockhand server URL or otherwise require Dockhand to be running

### Requirement: Komodo's own control-plane stacks are excluded from ResourceSync
`stacks/komodo/` and `stacks/komodo-periphery/` SHALL NOT be declared in `komodo/resources/stacks.toml`. They remain source/documentation in the repo and are deployed and updated manually, because Komodo has no native self-update mechanism for either component and managing its own control plane through itself would let a broken Core sync interfere with the Core that's supposed to execute it.

#### Scenario: stacks.toml contains no Komodo entries
- **WHEN** `komodo/resources/stacks.toml` is inspected
- **THEN** it contains no `[[stack]]` entry with `run_directory` set to `stacks/komodo` or `stacks/komodo-periphery`

### Requirement: Servers are declared before stacks reference them
Every server a stack can be assigned to SHALL be declared in `komodo/resources/servers.toml` before it is referenced by name in `komodo/resources/stacks.toml`.

#### Scenario: Stack references an undeclared server
- **WHEN** `komodo/resources/stacks.toml` assigns a stack to a server name absent from `komodo/resources/servers.toml`
- **THEN** the ResourceSync SHALL fail validation rather than deploy to an unresolved target

### Requirement: Secrets remain resolvable through the existing SOPS layer
Stack environment values managed by ResourceSync SHALL continue to resolve secrets via the existing `komodo/secrets.sops.yaml` and `komodo/hosts/<host>/secrets.sops.yaml` mechanism, referenced as `[[SECRET_NAME]]`.

#### Scenario: Stack variable references a shared secret
- **WHEN** `komodo/resources/stacks.toml` declares an environment value using `[[SECRET_NAME]]`
- **THEN** Komodo Core resolves it from the decrypted secrets TOML at deploy time, using the existing secrets workflow unchanged
