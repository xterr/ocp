import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'ocp',
  description: 'Isolated opencode profiles — config, auth, sessions, and omo, switched per directory.',
  base: '/ocp/',
  cleanUrls: true,
  lastUpdated: true,
  head: [['link', { rel: 'icon', href: '/ocp/logo.svg' }]],
  themeConfig: {
    logo: '/logo.svg',
    nav: [
      { text: 'Guide', link: '/guide/getting-started', activeMatch: '/guide/' },
      { text: 'Reference', link: '/reference/commands', activeMatch: '/reference/' },
    ],
    sidebar: [
      {
        text: 'Guide',
        items: [
          { text: 'Getting started', link: '/guide/getting-started' },
          { text: 'Profiles & isolation', link: '/guide/profiles' },
          { text: 'Per-directory switching', link: '/guide/switching' },
          { text: 'Secrets & environment', link: '/guide/secrets' },
        ],
      },
      {
        text: 'Reference',
        items: [
          { text: 'Commands', link: '/reference/commands' },
          { text: 'Configuration', link: '/reference/configuration' },
        ],
      },
    ],
    outline: { level: [2, 3], label: 'On this page' },
    socialLinks: [{ icon: 'github', link: 'https://github.com/xterr/ocp' }],
    search: { provider: 'local' },
    editLink: {
      pattern: 'https://github.com/xterr/ocp/edit/main/docs/:path',
      text: 'Edit this page on GitHub',
    },
    footer: {
      message: 'Isolated opencode profiles.',
      copyright: '© 2026 xterr',
    },
  },
})
