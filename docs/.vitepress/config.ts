import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Homelab Catalog',
  description: 'Dockhand template catalog for homelab services',
  base: '/homelab-catalog/',
  themeConfig: {
    socialLinks: [
      { icon: 'github', link: 'https://github.com/st0o0/homelab-catalog' },
    ],
  },
})
