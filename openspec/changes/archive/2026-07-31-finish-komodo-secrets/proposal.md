## Why

ROADMAP.md §7 (Secret management with SOPS) is implemented end-to-end —
`komodo/.sops.yaml`, `komodo/secrets.sops.yaml`, per-host secrets under
`komodo/hosts/<host>/`, `komodo/decrypt.sh`, the `just secrets` /
`just decrypt` / `just show-secrets` targets, `scripts/init-secrets.sh`,
and the `KOMODO_SECRETS_FILE` mount into Komodo Core all exist and work
together. The one unchecked box left in §7 is "Document secret rotation
workflow in README" — there is currently no write-up of the day-2 workflow
(first-time setup, editing a secret, rotating a compromised value, adding a
new host), so anyone other than the person who built it has to reverse
engineer the flow from `justfile` and `decrypt.sh`.

## What Changes

- Add `komodo/README.md` documenting the SOPS/age secrets workflow:
  first-time setup (`scripts/init-secrets.sh`), editing shared vs.
  per-host secrets (`just secrets [TARGET]`), decrypting on the Core host
  (`just decrypt` / `komodo/decrypt.sh`), rotating a secret end-to-end, and
  adding secrets for a new host.
- Link `komodo/README.md` from the root `README.md`.
- Check off the completed items in ROADMAP.md §7 (all technical items are
  already done; only the documentation item remains open).

## Capabilities

### New Capabilities
(none — documentation only)

### Modified Capabilities
(none — no spec-level behavior changes; existing secrets workflow behavior
is unchanged, only documented)

## Impact

- New file: `komodo/README.md`
- Edited: root `README.md` (add link), `ROADMAP.md` (check off §7 items)
- No code, compose, or CI changes
