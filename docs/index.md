---
layout: home
hero:
  name: ocp
  text: Isolated opencode profiles
  tagline: Config, auth, sessions, and omo — switched per directory.
  image:
    src: /logo.svg
    alt: ocp
  actions:
    - theme: brand
      text: Get started
      link: /guide/getting-started
    - theme: alt
      text: GitHub
      link: https://github.com/xterr/ocp
features:
  - title: Isolated auth & sessions
    details: Each profile has its own auth.json and session database. Stay logged into multiple accounts side by side.
  - title: Isolated config & omo
    details: Separate opencode.json, AGENTS.md, agents, skills, plugins, and oh-my-openagent setup per profile.
  - title: Per-directory activation
    details: Drop a .ocprofile in a project and opencode picks the right profile automatically.
  - title: Bring your own secrets
    details: Plain env files, macOS Keychain, 1Password, or any wrapper command. Nothing baked in.
  - title: Zero runtime dependencies
    details: A single Bash script that sets two environment variables opencode already understands.
  - title: One-line install
    details: Install via curl from the latest release, then switch by flag, default, or directory.
---
