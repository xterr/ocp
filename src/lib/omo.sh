## oh-my-openagent (omo) integration helpers
##
## Since oh-my-openagent 5.x the plugin no longer reads
## <profile>/config/oh-my-openagent.json. It loads a single home-anchored
## ~/.omo/omo.jsonc (plus project-level .omo/omo.jsonc) and picks a
## per-profile section from its top-level "profiles" object. The section is
## chosen by $OMO_PROFILE, so that is what ocp exports on launch.
##
## ocp only ever *reads* the omo config; it never rewrites it.

ocp_omo_dir() {
  printf '%s' "$HOME/.omo"
}

# Mirrors omo's own lookup: prefer omo.jsonc, fall back to omo.json, and
# default to omo.jsonc when neither exists yet.
ocp_omo_config_file() {
  local d
  d="$(ocp_omo_dir)"
  if [ -f "$d/omo.jsonc" ]; then
    printf '%s' "$d/omo.jsonc"
  elif [ -f "$d/omo.json" ]; then
    printf '%s' "$d/omo.json"
  else
    printf '%s' "$d/omo.jsonc"
  fi
}

# Print the profile names declared under the top-level "profiles" object,
# one per line. The scan is string-aware so braces or // sequences inside
# string values (e.g. the "$schema" URL) cannot desynchronise the depth
# counter. Returns nothing if the file is absent or declares no profiles.
ocp_omo_profiles() {
  local f
  f="$(ocp_omo_config_file)"
  [ -f "$f" ] || return 0

  awk '
    BEGIN {
      depth = 0; pdepth = -1; want = 0
      instr = 0; esc = 0; inblock = 0; cur = ""; last = ""
    }
    {
      n = length($0)
      for (i = 1; i <= n; i++) {
        c = substr($0, i, 1)
        d = (i < n) ? substr($0, i + 1, 1) : ""

        if (inblock) {
          if (c == "*" && d == "/") { inblock = 0; i++ }
          continue
        }

        if (instr) {
          if (esc)       { esc = 0; cur = cur c; continue }
          if (c == "\\") { esc = 1; continue }
          if (c == "\"") { instr = 0; last = cur; continue }
          cur = cur c
          continue
        }

        if (c == "/" && d == "/") break
        if (c == "/" && d == "*") { inblock = 1; i++; continue }

        if (c == "\"") { instr = 1; cur = ""; continue }

        if (c == "{") {
          depth++
          if (want) { pdepth = depth; want = 0 }
          continue
        }

        if (c == "}") {
          if (pdepth != -1 && depth == pdepth) pdepth = -1
          depth--
          continue
        }

        if (c == ":") {
          if (depth == 1 && last == "profiles") want = 1
          else if (pdepth != -1 && depth == pdepth) print last
          continue
        }
      }
    }
  ' "$f"
}

# True when the omo config declares a "profiles" section for this name.
ocp_omo_has_profile() {
  local name found
  name="$1"
  while IFS= read -r found; do
    [ "$found" = "$name" ] && return 0
  done < <(ocp_omo_profiles)
  return 1
}

# Warn when a profile has no matching omo section. omo does not fail on an
# unknown profile name -- it silently falls back to the base config, which
# would quietly hand this profile another profile's models. Surface it.
ocp_omo_check_profile() {
  local name f
  name="$1"
  f="$(ocp_omo_config_file)"

  [ -f "$f" ] || return 0
  ocp_omo_has_profile "$name" && return 0

  ocp_warn "omo config $f has no \"profiles\" entry for '$name'."
  ocp_info "Without it omo silently falls back to the shared base config. Add:"
  printf '\n  "profiles": {\n    "%s": {\n      "[opencode]": {}\n    }\n  }\n\n' "$name"
}
