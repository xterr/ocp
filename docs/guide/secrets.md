# Secrets & environment

`ocp` ships with **no** secret manager. Each profile has two optional, composable hooks. Edit them with `ocp edit <name> --what env` or `ocp edit <name> --what manifest`.

## The `env` file

`<profile>/env` is **sourced as Bash** right before launch, and every variable it defines is exported. Use static values or pull from any secret store at runtime:

```sh
# static
OPENAI_API_KEY=sk-...
OPENCODE_MODEL=anthropic/claude-sonnet-4-5

# macOS Keychain
export ANTHROPIC_API_KEY="$(security find-generic-password -a "$USER" -s opencode-work -w)"

# 1Password
export OPENAI_API_KEY="$(op read 'op://Work/openai/credential')"
```

Seed it at creation time with `--env-file`:

```sh
ocp create work --env-file ./work.env
```

::: warning
The `env` file is executed as Bash. Keep it readable only by you — `ocp` sets `chmod 600` on files it seeds; do the same for files you create by hand, and never commit real secrets.
:::

## macOS Keychain

Store the secret once (you are prompted for the value):

```sh
security add-generic-password -a "$USER" -s opencode-work -w
```

Then read it dynamically in the profile's `env` file:

```sh
export ANTHROPIC_API_KEY="$(security find-generic-password -a "$USER" -s opencode-work -w)"
```

Nothing secret is written to disk — the key is read from Keychain at launch.

## 1Password

**Read individual secrets** in the `env` file (needs the `op` CLI, signed in):

```sh
export ANTHROPIC_API_KEY="$(op read 'op://Private/anthropic/credential')"
```

**Or wrap the whole launch** with `op run` and an op-reference env file using the `WRAPPER` hook below.

## The `WRAPPER` hook

`WRAPPER` (in the profile manifest) is a command prefix that wraps the entire opencode invocation. It supports `{profile_dir}`, `{config_dir}`, and `{data_dir}` substitution tokens:

```sh
ocp create work --wrapper 'op run --no-masking --env-file={profile_dir}/secrets.env --'
```

At launch this becomes:

```
op run --no-masking --env-file=~/.config/ocp/profiles/work/secrets.env -- opencode …
```

The same mechanism works with any "run-with-env" tool — for example `aws-vault exec work --` or `direnv exec {profile_dir} --`.

## Verifying

`--print` shows exactly what will run, without running it:

```sh
ocp launch -p work --print -- run "hi"
# OPENCODE_CONFIG_DIR=~/.config/ocp/profiles/work/config
# XDG_DATA_HOME=~/.config/ocp/profiles/work/data
# env-file: ~/.config/ocp/profiles/work/env
# exec op run --no-masking --env-file=…/secrets.env -- opencode run hi
```
