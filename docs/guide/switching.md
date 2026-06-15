# Per-directory switching

Drop a `.ocprofile` file in a project and any `opencode` launched within it uses that profile:

```sh
cd ~/work/some-repo
ocp pin work          # writes ./.ocprofile containing "work"
opencode              # uses the 'work' profile
```

`ocp` walks **up** from the current directory to find the nearest `.ocprofile`, so a single file at the repo root applies to every subdirectory inside it. A `.ocprofile` only selects one of your existing profiles — it never runs code.

## Resolution order

When you run `ocp launch` (or the `opencode` wrapper), the profile is chosen by this priority chain:

1. `-p <name>` / `--profile <name>` flag
2. `$OCP_PROFILE` environment variable
3. nearest `.ocprofile` walking up from the current directory
4. the global default (`ocp use`)
5. none → plain opencode with no isolation

## Inspecting resolution

```sh
ocp current          # the profile active here
ocp resolve          # the profile, where it came from, and its paths
```

```
profile : work
source  : .ocprofile
config  : ~/.config/ocp/profiles/work/config
data    : ~/.config/ocp/profiles/work/data
```

The `source` field tells you *why* a profile was chosen — `flag`, `env:OCP_PROFILE`, `.ocprofile`, `active-default`, or `none`.

::: tip
This only kicks in when you launch through the wrapper (`opencode` after `eval "$(ocp init-shell)"`, or `ocp launch`). Calling the bare `opencode` binary bypasses `ocp` and ignores `.ocprofile`.
:::
