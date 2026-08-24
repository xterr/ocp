# Profiles & isolation

## How isolation works

opencode reads its directories from environment variables. `ocp` sets three, scoped to the launched process:

| What | Variable | Resolves to | Isolated |
| --- | --- | --- | --- |
| config | `OPENCODE_CONFIG_DIR` | `<profile>/config` | yes |
| auth + sessions | `XDG_DATA_HOME` | `<profile>/data` | yes |
| omo section | `OMO_PROFILE` | `<name>` | yes, by section |
| binary cache | *(untouched)* | shared | shared on purpose |

Your agents, skills, plugins, auth, and session history are children of the first two directories, so they are isolated automatically. The opencode binary cache is left shared so it is not re-downloaded per profile.

## oh-my-openagent (omo)

omo needs its own variable because it no longer stores config inside the opencode config directory.

Since omo 5.x it reads a **single, home-anchored** `~/.omo/omo.jsonc` (plus any project-level `.omo/omo.jsonc`), and there is no environment variable to relocate that file. `OPENCODE_CONFIG_DIR` therefore no longer isolates it. Instead, omo selects a section from the file's top-level `profiles` object, and `ocp` exports `OMO_PROFILE=<profile>` so each profile gets its own.

Put shared settings at the top level and per-profile overrides under `profiles.<name>`:

```jsonc
// ~/.omo/omo.jsonc
{
  "[opencode]": {
    "claude_code": { "skills": false }        // applies to every profile
  },
  "profiles": {
    "personal": {
      "[opencode]": {
        "agents": { "oracle": { "model": "anthropic/claude-opus-4-7" } }
      }
    },
    "work": {
      "[opencode]": {
        "agents": { "oracle": { "model": "llmgateway/claude-opus-4-7" } }
      }
    }
  }
}
```

The profile layer merges over the base, so a section only needs to declare what differs.

::: warning
If `profiles.<name>` is missing, omo does **not** error — it silently falls back to the base config, which can hand one profile another account's models. `ocp create` warns about this, and `ocp resolve` shows which section is in play.
:::

To point a profile at a differently-named section, set `OMO_PROFILE` in the profile's `env` file — a value already in the environment wins over the profile name.

## Layout

```
~/.config/ocp/
├── active                       # name of the default profile
└── profiles/<name>/
    ├── profile.env              # manifest: DESCRIPTION, WRAPPER, DEFAULT_ARGS
    ├── env                      # optional: sourced before launch
    ├── config/                  # OPENCODE_CONFIG_DIR (opencode.json, agents, skills, …)
    └── data/opencode/           # XDG_DATA_HOME (auth.json, sessions, …)
```

omo config lives outside this tree, in `~/.omo/omo.jsonc` under `profiles.<name>`.

Override the root with the `OCP_HOME` environment variable.

## Working with profiles

```sh
ocp create work --description "Work account"   # scaffold a profile
ocp list                                        # show all profiles
ocp use work                                    # set the global default
ocp path work                                   # print a profile's directories
ocp remove work --purge-data                    # delete a profile (and its data)
```

`ocp list` marks the global default and the profile active in the current directory:

```
   client  Client ACME
-> work
   personal

default -> work
```

The `->` arrow points to the profile that would launch right now; the `default ->` line shows the global default.

## Seeding a profile

Copy an existing opencode config into a new profile with `--from`, and reuse your current login with `--seed-auth`:

```sh
ocp create work --from ~/.config/opencode --seed-auth
```

Without `--seed-auth`, a new profile starts logged out — authenticate it once:

```sh
ocp launch -p work -- auth login
```
