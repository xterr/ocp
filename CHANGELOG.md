# Changelog

All notable changes to this project are documented here.

## [1.4.1] - 2026-06-15

### Features

- Back up ocp.json before migrating (timestamped)

### Bug Fixes

- Refuse to overwrite newer ocp.json schema on downgrade

### Documentation

- Update changelog for 1.4.0
- Surface self-update and the manual-setup pain in the readme

### Miscellaneous

- 1.4.1

## [1.4.0] - 2026-06-15

### Features

- Add versioned state migrations with auto-run

### Documentation

- Update changelog for 1.3.0

### Miscellaneous

- 1.4.0

## [1.3.0] - 2026-06-15

### Features

- Add ocp rename and JSON-backed profile state

### Documentation

- Update changelog for 1.2.0

### Miscellaneous

- 1.3.0

## [1.2.0] - 2026-06-15

### Features

- Add self-update command to install latest or a specific release

### Documentation

- Update changelog for 1.1.1

### Miscellaneous

- 1.2.0

## [1.1.1] - 2026-06-15

### Bug Fixes

- Stage changelog before diff so the new file is committed

### Refactoring

- Stop committing the generated ocp binary

### Miscellaneous

- Sync generated ocp to version 1.1.0
- Bump version + improvements

## [1.1.0] - 2026-06-15

### Features

- Maintain changelog.md via git-cliff on release

### Miscellaneous

- Updated .gitignore
- Bump version

## [1.0.0] - 2026-06-15

### Features

- Generate release notes from conventional commits with git-cliff

### Bug Fixes

- Make release workflow idempotent when a release already exists

### Miscellaneous

- Set version to 1.0.0

## [0.1.0] - 2026-06-15

### Features

- Add ocp opencode profile manager
- Colorize help output via bashly usage_colors settings
- Add curl installer, logo, and rewrite readme
- Add release and pages workflows with release-based installer
- Add vitepress documentation site
- Support zsh, bash, and fish shells in init-shell and installer

### Bug Fixes

- Replace gitlab urls with github raw urls (xterr/ocp)
- Escape > in badge alt text breaking github header render

### Refactoring

- Remove confusing ocp login subcommand

### Documentation

- Remove gratuitous references to other tools
- Add mit license and clarify shell support

### Styling

- Add colored nvm-style profile listing

### Miscellaneous

- Ignore .idea ide folder

