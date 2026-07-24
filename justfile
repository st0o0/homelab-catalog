# Manage the dev container without VS Code (wraps .devcontainer/devcontainer.sh).
# Pass VARIANT=windows to target the Windows host config (default: linux).

variant := env_var_or_default("VARIANT", "linux")

# Create/start the dev container
up:
    .devcontainer/devcontainer.sh --variant {{variant}} up

# Stop the dev container
down:
    .devcontainer/devcontainer.sh --variant {{variant}} down

# Remove + rebuild the dev container from scratch (--no-cache)
rebuild:
    .devcontainer/devcontainer.sh --variant {{variant}} rebuild

# Open an interactive shell inside the dev container
shell:
    .devcontainer/devcontainer.sh --variant {{variant}} shell

# Run a command inside the dev container, e.g.: just exec ansible --version
exec *ARGS:
    .devcontainer/devcontainer.sh --variant {{variant}} exec {{ARGS}}
