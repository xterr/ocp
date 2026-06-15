# Getting started

`ocp` runs [opencode](https://opencode.ai) under named **profiles** — *work*, *personal*, *client* — each with its own authentication, session history, and configuration. Pick a profile explicitly, set a global default, or let it switch automatically based on the directory you're in.

## Requirements

- **Bash ≥ 4 installed as the interpreter** — `ocp` is a Bash script, so a modern Bash must be on the
  system. This is *not* your login shell: **zsh, bash, and fish are all fully supported**. macOS ships
  Bash 3.2, so install a newer one:
  ```sh
  brew install bash
  ```
- **opencode** installed and on your `PATH`.

::: tip
Your interactive shell (zsh, bash, fish) is independent of the Bash that runs the `ocp` script. The
installer detects your shell and wires up the matching integration automatically.
:::

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

# zsh / bash — add to ~/.zshrc or ~/.bashrc:
eval "$(ocp init-shell)"

# fish — add to ~/.config/fish/config.fish:
ocp init-shell --shell fish | source
```

## Quick start

```sh
ocp create work --description "Work account"   # scaffold a profile
ocp use work                                    # set the global default
ocp launch -p work -- auth login                # authenticate (once per profile)
opencode                                         # runs under the active profile
```

## Shell integration

`ocp init-shell` prints a snippet that makes plain `opencode` profile-aware. It emits the right syntax for
your shell (auto-detected from `$SHELL`, or set `--shell zsh|bash|fish|posix`).

```sh
# zsh / bash — add to ~/.zshrc or ~/.bashrc:
eval "$(ocp init-shell)"

# fish — add to ~/.config/fish/config.fish:
ocp init-shell --shell fish | source
```

This defines a wrapper that resolves the active profile before launching opencode, plus a directory-change
hook that tracks the active profile (zsh `chpwd`, bash `PROMPT_COMMAND`, fish `--on-variable PWD`). The
`.ocprofile` directory switching works in every shell because it is resolved at launch — the hook only
keeps the `$OCP_ACTIVE_PROFILE` prompt variable current.

Options:

- `--shell <name>` — force `zsh`, `bash`, `fish`, or `posix` output.
- `--command <name>` — name the function something other than `opencode`.
- `--per-profile-aliases` — also emit `opencode-work`, `opencode-personal`, … one per profile.
- `--no-chpwd` — skip the directory-change hook that tracks the active profile.
