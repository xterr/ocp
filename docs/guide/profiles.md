# Profiles & isolation

## How isolation works

opencode reads its directories from environment variables. `ocp` sets only the two that matter, scoped to the launched process:

| What | Variable | Resolves to | Isolated |
| --- | --- | --- | --- |
| config + omo | `OPENCODE_CONFIG_DIR` | `<profile>/config` | yes |
| auth + sessions | `XDG_DATA_HOME` | `<profile>/data` | yes |
| binary cache | *(untouched)* | shared | shared on purpose |

Everything else — your omo config, agents, skills, plugins, auth, and session history — is a child of those two directories, so it is isolated automatically. The opencode binary cache is left shared so it is not re-downloaded per profile.

## Layout

```
~/.config/ocp/
├── active                       # name of the default profile
└── profiles/<name>/
    ├── profile.env              # manifest: DESCRIPTION, WRAPPER, DEFAULT_ARGS
    ├── env                      # optional: sourced before launch
    ├── config/                  # OPENCODE_CONFIG_DIR (opencode.json, omo, agents, …)
    └── data/opencode/           # XDG_DATA_HOME (auth.json, sessions, …)
```

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
