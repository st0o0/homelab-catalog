#!/usr/bin/env bash
set -euo pipefail

# --------------------------------------------------------------------------
# Layer 1: Shell toolchain (zsh, tmux, starship, chezmoi, fzf, zoxide)
# --------------------------------------------------------------------------
echo "==> Installing shell toolchain via dotfiles/install.sh..."
curl -fsSL https://raw.githubusercontent.com/st0o0/dotfiles/main/install.sh \
    | bash -s -- --profile devcontainer

# --------------------------------------------------------------------------
# Layer 2: Catalog tools (linting, validation, build)
# --------------------------------------------------------------------------
echo "==> Installing system dependencies..."
sudo apt-get update -qq
sudo apt-get install -y -qq --no-install-recommends \
    yamllint \
    jq \
    > /dev/null

echo "==> Installing dotenv-linter..."
DOTENV_VERSION="v3.3.0"
curl -fsSL "https://github.com/dotenv-linter/dotenv-linter/releases/download/${DOTENV_VERSION}/dotenv-linter-linux-x86_64.tar.gz" \
    | sudo tar -xz -C /usr/local/bin/

echo "==> Installing just..."
curl -fsSL https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin

echo "==> Installing commitlint dependencies..."
npm install --save-dev @commitlint/cli @commitlint/config-conventional --silent

# --------------------------------------------------------------------------
# Layer 3: DevContainer shell customizations
# --------------------------------------------------------------------------
echo "==> Configuring system-wide tmux autostart..."
TMUX_AUTOSTART_MARKER="# homelab-catalog: tmux autostart"
TMUX_AUTOSTART_SNIPPET="
${TMUX_AUTOSTART_MARKER}
if [ -z \"\${NO_AUTOSTART:-}\" ] && [ -z \"\${TMUX:-}\" ] && [ -n \"\${PS1:-}\" ] && command -v tmux >/dev/null 2>&1; then
    exec tmux new-session -A -s main
fi
"
for rc in /etc/bash.bashrc /etc/zsh/zshrc /etc/profile /etc/zsh/zprofile; do
    sudo mkdir -p "$(dirname "$rc")"
    sudo touch "$rc"
    if ! sudo grep -q "$TMUX_AUTOSTART_MARKER" "$rc"; then
        printf '%s\n' "$TMUX_AUTOSTART_SNIPPET" | sudo tee -a "$rc" > /dev/null
        echo "    Added to $rc"
    else
        echo "    Already present in $rc"
    fi
done

# --------------------------------------------------------------------------
# Verify
# --------------------------------------------------------------------------
echo "==> Verifying installations..."
yamllint --version
dotenv-linter --version
docker compose version
just --version
pwsh --version | head -1
tmux -V
zsh --version
fzf --version
starship --version | head -1
chezmoi --version | head -1

echo "==> Done."
