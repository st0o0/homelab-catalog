set windows-shell := ["pwsh", "-NoProfile", "-Command"]

# --- DevContainer management ---
# On Linux: wraps .devcontainer/devcontainer.sh (VARIANT default: linux)
# On Windows: wraps .devcontainer/devcontainer.ps1 (Variant default: windows)

variant := env_var_or_default("VARIANT", if os() == "windows" { "windows" } else { "linux" })

# Create/start the dev container
[unix]
up:
    .devcontainer/devcontainer.sh --variant {{variant}} up

[windows]
up:
    devcontainer up --workspace-folder . --config .devcontainer/{{variant}}/devcontainer.json

# Stop the dev container
[unix]
down:
    .devcontainer/devcontainer.sh --variant {{variant}} down

[windows]
down:
    $p = $PWD.Path[0].ToString().ToLower() + $PWD.Path.Substring(1); $cid = docker ps -q --filter "label=devcontainer.local_folder=$p"; if ($cid) { docker stop $cid } else { Write-Host "No running devcontainer found." }

# Remove + rebuild the dev container from scratch (--no-cache)
[unix]
rebuild:
    .devcontainer/devcontainer.sh --variant {{variant}} rebuild

[windows]
rebuild:
    devcontainer up --workspace-folder . --config .devcontainer/{{variant}}/devcontainer.json --remove-existing-container --build-no-cache

# Open an interactive shell inside the dev container
[unix]
shell:
    .devcontainer/devcontainer.sh --variant {{variant}} shell

[windows]
shell:
    devcontainer exec --workspace-folder . --config .devcontainer/{{variant}}/devcontainer.json tmux new-session -A -s main

# Run a command inside the dev container, e.g.: just exec just lint
[unix]
exec *ARGS:
    .devcontainer/devcontainer.sh --variant {{variant}} exec {{ARGS}}

[windows]
exec *ARGS:
    devcontainer exec --workspace-folder . --config .devcontainer/{{variant}}/devcontainer.json {{ARGS}}

# --- First-time setup ---

# First-time setup: restore/generate AGE key, sync with Bitwarden, configure .sops.yaml
setup:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ -z "${BW_SESSION:-}" ]; then
        echo "BW_SESSION not set. Run 'unlock' first."
        exit 1
    fi
    bash scripts/init-secrets.sh

# --- Secrets management ---

# Edit encrypted secrets ('all' for shared, or a hostname for host-specific)
secrets TARGET="all":
    #!/usr/bin/env bash
    set -euo pipefail
    if [ "{{TARGET}}" = "all" ]; then
        SECRET="komodo/secrets.sops.yaml"
        TEMPLATE="komodo/secrets.example.yaml"
    else
        SECRET="komodo/hosts/{{TARGET}}/secrets.sops.yaml"
        TEMPLATE="komodo/hosts/secrets.sops.yaml.tpl"
    fi
    if [ ! -f "$SECRET" ]; then
        mkdir -p "$(dirname "$SECRET")"
        cp "$TEMPLATE" /tmp/secrets.sops.yaml
        sops --config komodo/.sops.yaml --encrypt /tmp/secrets.sops.yaml > /tmp/secrets.sops.yaml.out
        mv /tmp/secrets.sops.yaml.out "$SECRET"
        rm /tmp/secrets.sops.yaml
        echo "Created $SECRET"
    fi
    sops --config komodo/.sops.yaml "$SECRET" || true

# Decrypt all secrets (shared + per-host) into Komodo Core config
decrypt OUTPUT="/etc/komodo/core.secrets.toml":
    #!/usr/bin/env bash
    set -euo pipefail
    SOPS_CONFIG="komodo/.sops.yaml"
    GLOBAL="komodo/secrets.sops.yaml"
    if [ ! -f "$GLOBAL" ]; then
        echo "Error: $GLOBAL not found. Run 'just secrets' first."
        exit 1
    fi
    echo "Decrypting to {{OUTPUT}} ..."
    {
        echo "[secrets]"
        sops -d --config "$SOPS_CONFIG" --output-type json "$GLOBAL" \
            | jq -r 'to_entries[] | "\(.key) = \"\(.value)\""'
        for host_dir in komodo/hosts/*/; do
            HOST_SECRET="${host_dir}secrets.sops.yaml"
            if [ -f "$HOST_SECRET" ]; then
                HOST=$(basename "$host_dir")
                sops -d --config "$SOPS_CONFIG" --output-type json "$HOST_SECRET" \
                    | jq -r --arg h "$HOST" 'to_entries[] | "\($h)_\(.key) = \"\(.value)\""'
            fi
        done
    } > "{{OUTPUT}}"
    chmod 600 "{{OUTPUT}}"
    echo "Done. Restart Komodo Core to pick up changes."

# Show decrypted secrets (stdout only, does not write files)
show-secrets TARGET="all":
    #!/usr/bin/env bash
    if [ "{{TARGET}}" = "all" ]; then
        sops -d --config komodo/.sops.yaml komodo/secrets.sops.yaml
    else
        sops -d --config komodo/.sops.yaml "komodo/hosts/{{TARGET}}/secrets.sops.yaml"
    fi

# --- Linting & Validation ---

# Lint all compose files, env files, and YAML
lint: lint-yaml lint-compose lint-env

# YAML lint (all yml/yaml files)
lint-yaml:
    yamllint .

# Validate all Docker Compose files
lint-compose:
    #!/usr/bin/env bash
    set -euo pipefail
    errors=0
    while IFS= read -r file; do
        dir="$(dirname "$file")"
        base="$dir/compose.yml"
        if [ "$file" = "$base" ]; then
            args=(-f "$file")
        else
            args=(-f "$base" -f "$file")
        fi
        if docker compose "${args[@]}" config -q 2>/dev/null; then
            echo "  ok  $file"
        else
            echo "  FAIL $file"
            errors=$((errors + 1))
        fi
    done < <(find stacks -name 'compose*.yml' | sort)
    if [ "$errors" -gt 0 ]; then
        echo ""
        echo "$errors compose file(s) failed validation"
        exit 1
    fi
    echo ""
    echo "All compose files valid"

# Lint all .env files
lint-env:
    dotenv-linter --recursive --skip UnorderedKey --skip LowercaseKey stacks

