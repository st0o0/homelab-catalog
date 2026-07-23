#!/usr/bin/env bash
set -euo pipefail

# First-time setup: generates an age keypair, backs it up to Bitwarden,
# configures SOPS, and creates empty encrypted secret files for every host
# in hosts.yml. Safe to re-run — skips steps that are already done.

AGE_KEY_DIR="$HOME/.config/sops/age"
AGE_KEY_FILE="$AGE_KEY_DIR/keys.txt"
SOPS_CONFIG="ansible/.sops.yaml"
HOSTS_FILE="ansible/hosts.yml"
BW_ITEM_NAME="Homelab SOPS Age Key"

cd "$(git rev-parse --show-toplevel)"

# ── Step 1: Age keypair ──────────────────────────────────────────────

if [ -f "$AGE_KEY_FILE" ]; then
    echo "==> Age key already exists at $AGE_KEY_FILE"
else
    echo "==> Generating age keypair..."
    mkdir -p "$AGE_KEY_DIR"
    age-keygen -o "$AGE_KEY_FILE" 2>&1
    chmod 600 "$AGE_KEY_FILE"
fi

PUBLIC_KEY=$(grep "public key:" "$AGE_KEY_FILE" | sed 's/.*public key: //')
echo "    Public key: $PUBLIC_KEY"

# ── Step 2: Backup to Bitwarden ──────────────────────────────────────

if [ -z "${BW_SESSION:-}" ]; then
    echo ""
    echo "==> BW_SESSION not set. To back up the age key to Bitwarden, run:"
    echo "    export BW_SESSION=\$(bw unlock --raw)"
    echo "    Then re-run this script."
    echo ""
    echo "    Continuing without Bitwarden backup..."
    echo ""
else
    EXISTING=$(bw get item "$BW_ITEM_NAME" 2>/dev/null | jq -r '.id // empty' 2>/dev/null || true)
    if [ -n "$EXISTING" ]; then
        echo "==> Age key already in Bitwarden ($BW_ITEM_NAME)"
    else
        echo "==> Backing up age key to Bitwarden..."
        KEY_CONTENT=$(cat "$AGE_KEY_FILE")
        bw get template item | \
            jq --arg name "$BW_ITEM_NAME" \
               --arg notes "$KEY_CONTENT" \
               '.type=2 | .name=$name | .notes=$notes | .secureNote={"type":0} | del(.login) | del(.folderId)' | \
            bw encode | bw create item > /dev/null
        echo "    Saved as Secure Note: $BW_ITEM_NAME"
    fi
fi

# ── Step 3: Update .sops.yaml ────────────────────────────────────────

CURRENT_KEY=$(grep -oP 'age1[a-z0-9]+' "$SOPS_CONFIG" 2>/dev/null || true)
if [ "$CURRENT_KEY" = "$PUBLIC_KEY" ]; then
    echo "==> .sops.yaml already has the correct public key"
elif echo "$CURRENT_KEY" | grep -q "TODO"; then
    echo "==> Updating .sops.yaml with public key..."
    sed -i "s|age1TODO_REPLACE_WITH_YOUR_PUBLIC_KEY|$PUBLIC_KEY|" "$SOPS_CONFIG"
    echo "    Updated: $SOPS_CONFIG"
elif [ -n "$CURRENT_KEY" ]; then
    echo "==> .sops.yaml already has a different key: $CURRENT_KEY"
    echo "    Not overwriting. Edit manually if you want to change it."
else
    echo "==> Updating .sops.yaml with public key..."
    sed -i "s|age1TODO_REPLACE_WITH_YOUR_PUBLIC_KEY|$PUBLIC_KEY|" "$SOPS_CONFIG"
    echo "    Updated: $SOPS_CONFIG"
fi

# ── Step 4: Scaffold secret.sops.yml for each host ────────────────────────

export SOPS_AGE_KEY_FILE="$AGE_KEY_FILE"

HOSTS=$(grep -oP '^\s{4}\S+(?=:)' "$HOSTS_FILE" | sed 's/^ *//' || true)

if [ -z "$HOSTS" ]; then
    echo "==> No hosts found in $HOSTS_FILE"
else
    echo "==> Checking secret files for hosts: $(echo $HOSTS | tr '\n' ' ')"
    for HOST in $HOSTS; do
        SECRET_FILE="ansible/host_vars/$HOST/secret.sops.yml"
        if [ -f "$SECRET_FILE" ]; then
            echo "    $HOST: secret.sops.yml already exists"
        else
            echo "    $HOST: creating from template..."
            mkdir -p "ansible/host_vars/$HOST"
            TEMPLATE="ansible/host_vars/secret.sops.yml.tpl"
            cp "$TEMPLATE" "/tmp/secret.sops.yml"
            sops --encrypt --age "$PUBLIC_KEY" --input-type yaml --output-type yaml "/tmp/secret.sops.yml" > "$SECRET_FILE"
            rm "/tmp/secret.sops.yml"
        fi
    done
fi

# ── Done ──────────────────────────────────────────────────────────────

echo ""
echo "==> Setup complete!"
echo ""
echo "    Next steps:"

NEEDS_EDIT=false
for HOST in $HOSTS; do
    SECRET_FILE="ansible/host_vars/$HOST/secret.sops.yml"
    if sops -d "$SECRET_FILE" 2>/dev/null | grep -q "CHANGEME"; then
        NEEDS_EDIT=true
        break
    fi
done

if [ "$NEEDS_EDIT" = true ]; then
    echo "    1. Edit secrets for each host (from ansible/):"
    for HOST in $HOSTS; do
        echo "       just secret $HOST"
    done
    echo "    2. Commit: git add .sops.yaml host_vars/ && git commit -m 'feat(ansible): add SOPS-encrypted host secrets'"
    echo "    3. Test:   just ping"
else
    echo "    All secrets already configured."
    echo "    Test: just ping"
fi
