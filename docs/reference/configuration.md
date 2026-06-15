# Configuration

## Directory root

All profiles live under `OCP_HOME`, which defaults to `~/.config/ocp`:

```
~/.config/ocp/
├── ocp.json                     # managed state: $schema + version + default profile
└── profiles/<name>/
    ├── profile.env              # manifest
    ├── env                      # optional environment file
    ├── config/                  # OPENCODE_CONFIG_DIR
    └── data/opencode/           # XDG_DATA_HOME
```

Override it per invocation or in your shell rc:

```sh
export OCP_HOME=/path/to/ocp
```

## State — `ocp.json`

A small, ocp-managed JSON file holding global state. You normally never edit it by hand — `ocp use`,
`ocp rename`, and `ocp remove` keep it in sync. It carries a `$schema` reference (served from this
site) and a `version` so the format can evolve:

```json
{
  "$schema": "https://xterr.github.io/ocp/ocp.schema.json",
  "version": 1,
  "defaultProfile": "work"
}
```

Earlier versions used a plain-text `active` file; it is migrated to `ocp.json` automatically the next
time the default changes.

## Manifest — `profile.env`

A small, Bash-sourceable file. `config/` and `data/` are derived by convention, so they are not stored here.

```sh
DESCRIPTION="Work account"     # shown in `ocp list`
WRAPPER=""                     # command prefix; {profile_dir}/{config_dir}/{data_dir} tokens
DEFAULT_ARGS=""                # extra args always prepended to opencode
```

## Environment file — `env`

Optional. Sourced as Bash before launch; all variables are exported. Use it for API keys, model overrides, or dynamic secret lookups. See [Secrets & environment](/guide/secrets).

## Directory file — `.ocprofile`

A one-line file naming a profile. Placed in a project, it activates that profile for the whole tree. See [Per-directory switching](/guide/switching).

## Environment variables

| Variable | Purpose |
| --- | --- |
| `OCP_HOME` | Root directory for profiles (default `~/.config/ocp`) |
| `OCP_PROFILE` | Force a profile, overriding `.ocprofile` and the default |

## What opencode sees

For the resolved profile, `ocp` sets exactly:

```sh
OPENCODE_CONFIG_DIR=<profile>/config
XDG_DATA_HOME=<profile>/data
```

Then it optionally applies the profile's `WRAPPER` and sources its `env` file before exec-ing opencode. The binary cache is left shared.
