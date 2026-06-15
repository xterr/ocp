# ocp — opencode profile manager

> Run [opencode](https://opencode.ai) with isolated **profiles** — each with its own config, auth, sessions, and [oh-my-openagent](https://opencode.ai) (omo) setup. Switch by flag, by default, or **automatically per-directory** (like `nvm` + `.nvmrc`).

`ocp` is a single, dependency-free Bash script generated with [bashly](https://bashly.dannyb.co/). It wires up nothing more than two environment variables that opencode already understands — so it is small, transparent, and easy to audit.

---

## Table of contents

- [Why](#why)
- [How it works](#how-it-works)
- [Requirements](#requirements)
- [Install](#install)
- [Quick start](#quick-start)
- [Shell integration](#shell-integration)
- [Per-directory auto-switching](#per-directory-auto-switching)
- [Profile resolution order](#profile-resolution-order)
- [Secrets & environment variables](#secrets--environment-variables)
  - [Plain env file](#1-plain-env-file)
  - [macOS Keychain](#2-macos-keychain)
  - [1Password](#3-1password)
  - [Other tools (aws-vault, direnv, doppler …)](#4-other-tools-untested)
- [Command reference](#command-reference)
- [Profile anatomy](#profile-anatomy)
- [Manifest reference](#manifest-reference-profileenv)
- [Distribution](#distribution)
- [Uninstall](#uninstall)
- [Troubleshooting](#troubleshooting)
- [Security notes](#security-notes)
- [Credits](#credits)

---

## Why

opencode keeps **one** global config (`~/.config/opencode`) and **one** data directory (`~/.local/share/opencode`, holding `auth.json` and your session database). If you juggle multiple accounts or contexts — *work*, *personal*, *a client* — you end up hand-editing files or maintaining ad-hoc shell functions.

`ocp` gives each context a fully self-contained profile:

- 🔐 **Isolated auth** — separate `auth.json`; log into different accounts side by side.
- 🧠 **Isolated sessions** — separate session database per profile; no cross-contamination.
- ⚙️ **Isolated config** — separate `opencode.json`, `AGENTS.md`, agents, skills, plugins, and your **omo** (`oh-my-openagent.json`) setup.
- 📁 **Per-directory activation** — drop a `.ocprofile` in a repo and `opencode` uses the right profile automatically.
- 🧩 **Bring your own secrets** — plain env files, macOS Keychain, 1Password, or any wrapper command. No secret manager is baked in.

---

## How it works

opencode resolves its directories from a handful of environment variables (verified against the binary's path-resolution module):

```
data   = $XDG_DATA_HOME/opencode        # auth.json, opencode.db, storage, snapshot, logs
config = $OPENCODE_CONFIG_DIR           # opencode.json, omo, AGENTS.md, agents/, skills/, plugins/
cache  = $XDG_CACHE_HOME/opencode       # the downloaded opencode binary
```

`ocp launch` sets **only** the two that matter, scoped to the launched process:

| Concern | Variable | Behavior | Isolated? |
|---|---|---|---|
| Config + **omo** | `OPENCODE_CONFIG_DIR` | full path → `<profile>/config` | ✅ |
| Auth + sessions | `XDG_DATA_HOME` | base → `<profile>/data` (opencode appends `/opencode`) | ✅ |
| Binary cache | *(left untouched)* | shared `~/.cache/opencode` | ➖ shared on purpose (no re-downloads) |

That's the entire mechanism. Everything else (your omo config, agents, auth, session history) is simply a child of those two directories, so it is isolated for free.

---

## Requirements

- **Bash ≥ 4** to *run* `ocp` (the generated script uses associative arrays).
  - macOS ships Bash 3.2. Install a modern Bash and make sure it's first on `PATH`:
    ```sh
    brew install bash
    ```
    The script's shebang is `#!/usr/bin/env bash`, so it picks up the Homebrew Bash automatically.
- **opencode** installed and on `PATH`.
- **bashly** — only needed to *build* `ocp` from source (via Docker or RubyGems). Not needed to run it.
- *(optional)* a secret tool — `security` (built into macOS), `op` (1Password), `aws-vault`, etc. — only if you use one.

---

## Install

### 1. Build the script

From the repository root (where `src/bashly.yml` lives):

**With Docker** (no Ruby needed):
```sh
docker run --rm --user "$(id -u):$(id -g)" --volume "$PWD:/app" dannyben/bashly generate
```

**Or with RubyGems:**
```sh
gem install bashly
bashly generate
```

Both produce a single executable `./ocp`.

### 2. Put it on your PATH

```sh
install -m755 ocp ~/.local/bin/ocp     # ensure ~/.local/bin is on your PATH
```

Verify:
```sh
ocp --help
```

---

## Quick start

```sh
# Create two fresh profiles
ocp create personal
ocp create work --description "Work account"

# Make 'personal' the default when nothing else applies
ocp use personal

# Authenticate each profile once (in its isolated data dir)
ocp launch -p personal -- auth login
ocp launch -p work -- auth login

# See what you have
ocp list
#   personal [default here]
#   work - Work account

# Launch (auto-resolves to 'personal')
ocp launch -- run "hello"

# Launch a specific profile
ocp launch -p work -- run "hello from work"
```

> Tip: instead of typing `ocp launch …`, set up [shell integration](#shell-integration) so plain `opencode` becomes profile-aware.

---

## Shell integration

`ocp init-shell` prints a snippet that turns `opencode` into a profile-aware wrapper. Add this to your `~/.zshrc`:

```zsh
eval "$(ocp init-shell)"
```

This defines:

```zsh
opencode() { command ocp launch -- "$@"; }
```

so every `opencode` invocation resolves the active profile first. (The function never recurses — `ocp` runs the real binary in a subprocess where the function isn't defined.)

### Options

```sh
ocp init-shell --command oc            # name the function 'oc' instead of 'opencode'
ocp init-shell --per-profile-aliases   # also emit opencode-work(), opencode-personal(), …
ocp init-shell --no-chpwd              # skip the prompt-helper hook
```

With `--per-profile-aliases` you get one function per profile:

```zsh
opencode-work()     { command ocp launch -p work -- "$@"; }
opencode-personal() { command ocp launch -p personal -- "$@"; }
```

A full setup in `~/.zshrc`:

```zsh
export PATH=$HOME/.opencode/bin:$PATH
eval "$(ocp init-shell --per-profile-aliases)"
```

---

## Per-directory auto-switching

Like `nvm`'s `.nvmrc`, drop a `.ocprofile` file in a directory and `opencode` launched anywhere under it uses that profile:

```sh
cd ~/work/some-repo
ocp pin work          # writes ./.ocprofile containing "work"
opencode              # → uses the 'work' profile automatically
```

`ocp` walks **up** from your current directory to find the nearest `.ocprofile`, so it applies to every subdirectory of the repo. A `.ocprofile` only *selects one of your own profiles* — it never executes code.

---

## Profile resolution order

When you run `ocp launch` (or the `opencode` wrapper), the profile is chosen by this priority chain:

1. `-p <name>` / `--profile <name>` flag
2. `$OCP_PROFILE` environment variable
3. nearest `.ocprofile` walking up from the current directory
4. the **active default** (set with `ocp use <name>`)
5. *(none)* → plain `opencode` with no isolation

Inspect what would happen anywhere:

```sh
ocp resolve
# profile : work
# source  : .ocprofile
# config  : ~/.config/ocp/profiles/work/config
# data    : ~/.config/ocp/profiles/work/data
```

---

## Secrets & environment variables

`ocp` ships with **no** secret manager. Instead, each profile has two optional, composable hooks:

- **`env` file** — `<profile>/env`, *sourced as Bash* right before launch. Use plain `KEY=value` lines **or** dynamic `KEY="$(some-command)"` to pull from any secret store. All variables are auto-exported.
- **`WRAPPER`** — a command prefix (in the manifest) that wraps the whole opencode invocation. Supports `{profile_dir}`, `{config_dir}`, and `{data_dir}` substitution tokens.

Edit either with:

```sh
ocp edit work --what env        # opens <profile>/env in $EDITOR
ocp edit work --what manifest   # opens profile.env (where WRAPPER lives)
```

### 1. Plain env file

```sh
ocp edit work --what env
```
```sh
# ~/.config/ocp/profiles/work/env
OPENAI_API_KEY=sk-...
OPENCODE_MODEL=anthropic/claude-sonnet-4-5
```

Seed it at creation time instead:

```sh
ocp create work --env-file ./work.env
```

### 2. macOS Keychain

Store the secret once (you'll be prompted for the value):

```sh
security add-generic-password -a "$USER" -s opencode-work-anthropic -w
```

Then fetch it dynamically in the profile's `env` file:

```sh
# ~/.config/ocp/profiles/work/env
export ANTHROPIC_API_KEY="$(security find-generic-password -a "$USER" -s opencode-work-anthropic -w)"
```

Nothing secret is stored on disk — the key is read from Keychain at launch.

### 3. 1Password

**Option A — read individual secrets in the `env` file** (needs the `op` CLI, signed in):

```sh
# ~/.config/ocp/profiles/work/env
export ANTHROPIC_API_KEY="$(op read 'op://Private/anthropic/credential')"
export OPENAI_API_KEY="$(op read 'op://Work/openai/credential')"
```

**Option B — wrap the whole launch with `op run`** and an op-reference env file:

```sh
# 1) create a secrets.env inside the profile dir with op:// references
#    ~/.config/ocp/profiles/work/secrets.env
#    ANTHROPIC_API_KEY=op://Private/anthropic/credential

# 2) set the wrapper (the {profile_dir} token resolves to the profile path)
ocp create work --wrapper 'op run --no-masking --env-file={profile_dir}/secrets.env --'
```

At launch this becomes:
```
op run --no-masking --env-file=~/.config/ocp/profiles/work/secrets.env -- opencode …
```

### 4. Other tools (untested)

The same `WRAPPER` field works with any "run-with-env" tool. These are illustrative — adapt to your setup:

```sh
ocp create work --wrapper 'aws-vault exec work --'
ocp create work --wrapper 'doppler run --'
ocp create work --wrapper 'direnv exec {profile_dir} --'
```

> The `env` file is **sourced as Bash**, so it executes. Keep it readable only by you (`ocp` sets `chmod 600` on files it seeds; do the same for files you create by hand) and never commit real secrets.

---

## Command reference

| Command | Description |
|---|---|
| `ocp create <name> [flags]` | Create a new self-contained profile |
| `ocp list` / `ocp ls` | List profiles; marks the `[default]` and the one active `[here]` |
| `ocp current` | Print the profile that applies in the current directory |
| `ocp resolve [dir] [-q]` | Show the resolved profile, its source, and paths |
| `ocp use <name>` | Set the global default profile |
| `ocp launch [flags] -- <args>` | Resolve a profile and exec opencode with isolated env |
| `ocp pin <name> [dir]` | Write a `.ocprofile` (defaults to the current dir) |
| `ocp edit <name> [--what …]` | Open a profile's config / manifest / env / data |
| `ocp path <name>` | Print a profile's resolved directories |
| `ocp remove <name> [flags]` | Remove a profile |
| `ocp init-shell [flags]` | Print zsh integration to `eval` |

### `create`

```sh
ocp create <name>
  --from <dir>          # seed config/ by copying an existing opencode config dir
  --seed-auth           # copy your current ~/.local/share/opencode/auth.json into the profile
  --env-file <file>     # seed the profile's env file (dotenv KEY=VALUE)
  --wrapper <cmd>       # command prefix to wrap opencode (supports {profile_dir} etc.)
  --description <text>  # stored in the manifest, shown in `ocp list`
  --force, -f           # overwrite if the profile already exists
```

### `launch`

```sh
ocp launch
  --profile, -p <name>  # explicit profile (otherwise auto-resolved)
  --print               # print the resolved env + command instead of running
  -- <opencode args>    # everything after -- is passed straight to opencode
```

`--print` is the safe way to see exactly what will run:

```sh
ocp launch -p work --print -- run "hi"
# OPENCODE_CONFIG_DIR=~/.config/ocp/profiles/work/config
# XDG_DATA_HOME=~/.config/ocp/profiles/work/data
# env-file: ~/.config/ocp/profiles/work/env
# exec op run --no-masking --env-file=…/secrets.env -- opencode run hi
```

### `edit`

```sh
ocp edit <name> --what <target>
# targets: config (default) | manifest | opencode-json | omo | env | data
```

### `remove`

```sh
ocp remove <name>
  --purge-data   # also delete data/ (auth + sessions) — required if data exists
  --yes, -y      # skip the confirmation prompt
```

For safety, `remove` refuses to delete a profile that has a `data/` directory unless you pass `--purge-data`.

---

## Profile anatomy

```
~/.config/ocp/                          # OCP_HOME (override with $OCP_HOME)
├── active                              # name of the default profile
└── profiles/
    └── work/
        ├── profile.env                 # manifest: DESCRIPTION, WRAPPER, DEFAULT_ARGS
        ├── env                         # optional: dotenv, sourced before launch
        ├── secrets.env                 # optional: e.g. op:// references for `op run`
        ├── config/                     # → OPENCODE_CONFIG_DIR
        │   ├── opencode.json
        │   ├── oh-my-openagent.json    # your omo config
        │   ├── AGENTS.md
        │   └── agents/ skills/ plugin/ commands/
        └── data/                       # → XDG_DATA_HOME
            └── opencode/
                ├── auth.json           # isolated auth
                ├── opencode.db          # isolated sessions
                └── storage/ snapshot/ log/
```

---

## Manifest reference (`profile.env`)

A small, Bash-sourceable file. `config/` and `data/` are derived by convention, so they are **not** stored here.

```sh
DESCRIPTION="Work account"     # shown in `ocp list`
WRAPPER=""                     # optional command prefix; {profile_dir}/{config_dir}/{data_dir} tokens
DEFAULT_ARGS=""                # extra args always prepended to opencode
```

---

## Distribution

`ocp` compiles to a **single self-contained Bash file** — that's the whole point of bashly. To share it:

1. Build the slimmer **production** variant (strips dev-only helpers like `inspect_args` and view markers):
   ```sh
   docker run --rm --user "$(id -u):$(id -g)" --volume "$PWD:/app" dannyben/bashly generate --env production
   # or, with the gem:  bashly generate --env production
   ```
2. Ship the resulting `./ocp` file. Recipients only need Bash ≥ 4 and opencode; **bashly is not required to run it**.

Common channels:

```sh
# Direct: drop it on PATH
install -m755 ocp ~/.local/bin/ocp

# Homebrew tap, GitHub Release asset, or an install script that curls the raw file
curl -fsSL https://example.com/ocp -o ~/.local/bin/ocp && chmod +x ~/.local/bin/ocp
```

To change anything, edit files under `src/` and re-run `bashly generate`; never hand-edit the generated `ocp`. Help-text colors are configured in `settings.yml` (`usage_colors`); runtime color follows your terminal and the [`NO_COLOR`](https://no-color.org) standard.

---

## Uninstall

```sh
rm ~/.local/bin/ocp                 # remove the command
# remove the shell snippet block from ~/.zshrc
rm -rf ~/.config/ocp                # remove ALL profiles, auth, and sessions (destructive)
```

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `declare: -A: invalid option` when running `ocp` | Your Bash is < 4. `brew install bash` and ensure it's first on `PATH`. |
| `opencode` still uses the old account after switching | opencode reads `auth.json` at launch — fully quit it, then relaunch. |
| `Profile '<x>' does not exist` from a `.ocprofile` | The pinned profile was never created. Run `ocp create <x>` or fix the `.ocprofile`. |
| A profile starts logged-out | Full isolation means a fresh `auth.json`. Run `ocp launch -p <name> -- auth login` once (or create with `--seed-auth`). |
| Secrets not present in opencode | Check `ocp launch -p <name> --print`; confirm the `env`/`WRAPPER` lines are what you expect. |

---

## Security notes

- Each profile's `data/opencode/auth.json` holds real credentials. `ocp` creates seeded auth/env files with `chmod 600`; keep hand-created files the same and don't commit them.
- The `env` file is **sourced as Bash** before launch. Treat it like `.bashrc`: only put trusted content there.
- A `.ocprofile` cannot run code — it only names one of your existing profiles.

---

## Credits

- Built with [bashly](https://bashly.dannyb.co/) by Danny Ben Shitrit.
- Inspired by the [opencode profile switcher gist](https://gist.github.com/locxter/82b613aef5909817b352f62ba9734726) and [OCX](https://ocx.kdco.dev/).
- For [opencode](https://opencode.ai).
