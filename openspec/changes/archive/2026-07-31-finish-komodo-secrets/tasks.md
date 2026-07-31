## 1. Document the secrets workflow

- [x] 1.1 Write `komodo/README.md` covering: first-time setup (`scripts/init-secrets.sh`), age key location and Bitwarden backup, editing shared secrets (`just secrets`), editing per-host secrets (`just secrets <hostname>`), decrypting on the Core host (`just decrypt` / `komodo/decrypt.sh`), and how `[[SECRET_NAME]]` interpolation reaches stacks via `KOMODO_SECRETS_FILE`.
- [x] 1.2 Add a "Rotating a secret" subsection: edit the value with `just secrets [TARGET]`, commit + push, pull on the Core host, re-run `just decrypt` (or `komodo/decrypt.sh`), restart Komodo Core.
- [x] 1.3 Add an "Adding a new host" subsection: create `komodo/hosts/<hostname>/`, copy `komodo/hosts/secrets.sops.yaml.tpl`, fill in and encrypt with `just secrets <hostname>`.
- [x] 1.4 Link `komodo/README.md` from the root `README.md`.

## 2. Close out the roadmap item

- [x] 2.1 Check off all completed items under ROADMAP.md §7 (Secret management with SOPS).
