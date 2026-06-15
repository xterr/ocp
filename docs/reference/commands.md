# Commands

| Command | Description |
| --- | --- |
| [`create`](#create) | Create a self-contained profile |
| [`list`](#list) | List profiles; mark the default and the one active here |
| [`current`](#current) | Print the profile active in this directory |
| [`resolve`](#resolve) | Show the resolved profile, its source, and paths |
| [`use`](#use) | Set the global default profile |
| [`rename`](#rename) | Rename a profile (repoints the default if needed) |
| [`launch`](#launch) | Run opencode under a profile with isolated env |
| [`pin`](#pin) | Write a `.ocprofile` |
| [`edit`](#edit) | Open a profile's config, manifest, env, or data |
| [`path`](#path) | Print a profile's directories |
| [`remove`](#remove) | Remove a profile |
| [`init-shell`](#init-shell) | Print shell integration to `eval` |
| [`self-update`](#self-update) | Update `ocp` to the latest release (or a specific version) |
| [`migrate`](#migrate) | Migrate on-disk state to the current schema version |

Run `ocp <command> --help` for the full flag list of any command.

## create

```sh
ocp create <name> [flags]
```

| Flag | Description |
| --- | --- |
| `--from <dir>` | Seed `config/` by copying an existing opencode config directory |
| `--seed-auth` | Copy your current `~/.local/share/opencode/auth.json` into the profile |
| `--env-file <file>` | Seed the profile's `env` file from a dotenv file |
| `--wrapper <cmd>` | Command prefix to wrap opencode (supports `{profile_dir}`) |
| `--description <text>` | Stored in the manifest, shown in `ocp list` |
| `--force`, `-f` | Overwrite if the profile already exists |

## list

```sh
ocp list
```

Lists profiles. `->` marks the profile active in the current directory; the `default ->` footer shows the global default.

## current

```sh
ocp current
```

Prints the name of the profile that applies in the current directory, or `(none)`.

## resolve

```sh
ocp resolve [dir]
```

Shows the resolved profile, the source of the decision (`flag`, `env:OCP_PROFILE`, `.ocprofile`, `active-default`, `none`), and the resolved `config`/`data` paths. `--quiet` prints only the name (used by the shell hook).

## use

```sh
ocp use <name>
```

Sets the global default profile (written to `~/.config/ocp/ocp.json`).

## rename

```sh
ocp rename <old> <new>
```

Renames a profile directory. If the global default pointed at `<old>`, it is repointed to `<new>`.
Fails if `<new>` already exists. Pinned `.ocprofile` files that reference `<old>` are **not** rewritten —
re-pin them with `ocp pin <new>`.

## launch

```sh
ocp launch [-p <name>] [--print] -- <opencode args>
```

Resolves a profile and execs opencode with the isolated environment. Everything after `--` is passed straight through. `--print` shows the resolved env and command without running it.

## pin

```sh
ocp pin <name> [dir]
```

Writes a `.ocprofile` (defaults to the current directory) so opencode auto-selects the profile there.

## edit

```sh
ocp edit <name> --what <target>
```

Targets: `config` (default), `manifest`, `opencode-json`, `omo`, `env`, `data`. Opens the target in `$VISUAL`/`$EDITOR`.

## path

```sh
ocp path <name>
```

Prints the profile's `root`, `config`, and `data` directories.

## remove

```sh
ocp remove <name> [--purge-data] [--yes]
```

Removes a profile. Refuses to delete a profile that has a `data/` directory unless `--purge-data` is given. `--yes` skips the confirmation prompt.

## init-shell

```sh
ocp init-shell [--command <name>] [--per-profile-aliases] [--no-chpwd]
```

Prints the shell integration to `eval` in your rc file.

The plain `opencode` launcher resolves the profile live on every call, so creating, renaming, or
removing profiles takes effect immediately. The optional `--per-profile-aliases` functions
(`opencode-<name>`) are generated once at `eval` time, so after you add or rename a profile you must
reload your shell (or re-run the `eval`) for those aliases to catch up.

## self-update

```sh
ocp self-update [version] [--force]
```

Replaces the running `ocp` binary with a release from GitHub. With no argument it installs the latest release; pass a `version` (e.g. `1.0.0`) to pin or revert to a specific one. The download is syntax-checked before it atomically replaces the binary in place, so a failed or interrupted update never corrupts your install. `--force` reinstalls even when already on the target version.

Updating to a version older than the one that introduced `self-update` will leave you without the command — reinstall via the [install script](/guide/getting-started#install) to recover.

## migrate

```sh
ocp migrate [--check]
```

Upgrades ocp's on-disk state under `$OCP_HOME` to the current schema version. This is normally
automatic — every `ocp` command (and the installer / `self-update`) runs pending migrations
first — so you rarely need it by hand. The integer `version` field in `ocp.json` tracks what has
been applied; the legacy plain-text `active` file is treated as version 0 and converted to
`ocp.json`. `--check` prints the current and target versions without changing anything. A file from
a newer ocp (version greater than this binary supports) is left untouched.
