---
layout: home
hero:
  name: Homelab Catalog
  tagline: Dockhand template catalog for homelab services
  actions:
    - theme: brand
      text: View on GitHub
      link: https://github.com/st0o0/homelab-catalog
---

## Connect to Dockhand

In the Dockhand UI go to **Templates > Sources** and add a new source:

| Field | Value |
|-------|-------|
| Name  | `Homelab` |
| URL   | `https://st0o0.github.io/homelab-catalog/templates.json` |

Dockhand fetches and caches the catalog for one hour. After adding the source, switch to the **Templates** tab to browse and deploy.

## Alternative: curl / scripts

For non-browser consumers (scripts, CI, curl), use the GitHub Release asset URL:

```bash
curl -fsSL https://github.com/st0o0/homelab-catalog/releases/latest/download/templates.json
```

## Related Repos

- [homelab-ansible](https://github.com/st0o0/homelab-ansible) — Server provisioning
- [dotfiles](https://github.com/st0o0/dotfiles) — Shell toolchain
