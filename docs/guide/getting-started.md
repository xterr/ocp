# Getting started

`ocp` runs [opencode](https://opencode.ai) under named **profiles** — *work*, *personal*, *client* — each with its own authentication, session history, and configuration. Pick a profile explicitly, set a global default, or let it switch automatically based on the directory you're in.

## Requirements

- **Bash ≥ 4** to run `ocp`. macOS ships 3.2 — install a modern Bash and keep it first on `PATH`:
  ```sh
  brew install bash
  ```
- **opencode** installed and on your `PATH`.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/xterr/ocp/main/install.sh | bash
```

Pass a profile name (defaults to `default`):

```sh
curl -fsSL https://raw.githubusercontent.com/xterr/ocp/main/install.sh | bash -s -- work
```

The installer downloads `ocp` from the latest GitHub release into `~/.local/bin`, creates the profile, sets it as the default, and adds the shell integration to your rc file. Use `--no-shell` to skip the rc change.

Pin a specific version:

```sh
curl -fsSL https://raw.githubusercontent.com/xterr/ocp/main/install.sh | bash -s -- work --version 1.2.3
```

### Manual install

```sh
install -m755 ocp ~/.local/bin/ocp        # ~/.local/bin must be on your PATH
echo 'eval "$(ocp init-shell)"' >> ~/.zshrc
```

## Quick start

```sh
ocp create work --description "Work account"   # scaffold a profile
ocp use work                                    # set the global default
ocp launch -p work -- auth login                # authenticate (once per profile)
opencode                                         # runs under the active profile
```

## Shell integration

`ocp init-shell` prints a snippet that makes plain `opencode` profile-aware. Add it to your shell rc:

```sh
eval "$(ocp init-shell)"
```

This defines a wrapper that resolves the active profile before launching opencode:

```sh
opencode() { command ocp launch -- "$@"; }
```

Options:

- `--command <name>` — name the function something other than `opencode`.
- `--per-profile-aliases` — also emit `opencode-work`, `opencode-personal`, … one per profile.
- `--no-chpwd` — skip the directory-change hook that tracks the active profile.
