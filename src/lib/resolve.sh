## Profile resolution helpers

# Walk up from a directory looking for the nearest .ocprofile (like .nvmrc).
# Prints the profile name on success.
ocp_find_ocprofile() {
  local d name
  d="$1"
  while :; do
    if [ -f "$d/.ocprofile" ]; then
      IFS= read -r name <"$d/.ocprofile" || name=""
      name="$(printf '%s' "$name" | tr -d '[:space:]')"
      if [ -n "$name" ]; then
        printf '%s\n' "$name"
        return 0
      fi
    fi
    [ "$d" = "/" ] && break
    d="$(dirname "$d")"
  done
  return 1
}

# Extract a flat JSON string value: ocp_json_get_string <file> <key>.
# Profile names are restricted to [A-Za-z0-9_-], so a targeted match is safe
# and keeps ocp dependency-free (no jq).
ocp_json_get_string() {
  local file="$1" key="$2" val
  [ -f "$file" ] || return 1
  val="$(sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" "$file" | head -n1)"
  [ -n "$val" ] || return 1
  printf '%s\n' "$val"
}

ocp_write_config() {
  local f def schema
  f="$(ocp_config_file)"
  def="$1"
  schema="https://xterr.github.io/ocp/ocp.schema.json"
  mkdir -p "$(ocp_home)" || ocp_die "Failed to create $(ocp_home)"
  if [ -n "$def" ]; then
    printf '{\n  "$schema": "%s",\n  "version": 1,\n  "defaultProfile": "%s"\n}\n' "$schema" "$def" >"$f" || ocp_die "Failed to write $f"
  else
    printf '{\n  "$schema": "%s",\n  "version": 1\n}\n' "$schema" >"$f" || ocp_die "Failed to write $f"
  fi
}

ocp_set_active() {
  ocp_write_config "$1"
  rm -f "$(ocp_legacy_active_file)" 2>/dev/null || true
}

ocp_clear_active() {
  ocp_write_config ""
  rm -f "$(ocp_legacy_active_file)" 2>/dev/null || true
}

ocp_read_active_file() {
  local af name
  af="$1"
  [ -f "$af" ] || return 1
  IFS= read -r name <"$af" || name=""
  name="$(printf '%s' "$name" | tr -d '[:space:]')"
  [ -n "$name" ] || return 1
  printf '%s\n' "$name"
}

# Read the active default profile name, preferring ocp.json and falling back
# to the legacy 'active' file for backward compatibility.
ocp_active_profile() {
  local name
  if name="$(ocp_json_get_string "$(ocp_config_file)" defaultProfile)"; then
    name="$(printf '%s' "$name" | tr -d '[:space:]')"
    [ -n "$name" ] && { printf '%s\n' "$name"; return 0; }
  fi
  ocp_read_active_file "$(ocp_legacy_active_file)"
}

# Resolve the active profile via the priority chain.
# ocp_resolve_profile <explicit_name> <dir>
ocp_resolve_profile() {
  local explicit="$1" dir="${2:-$PWD}" found
  if [ -n "$explicit" ]; then
    printf '%s\n' "$explicit"
    return 0
  fi
  if [ -n "${OCP_PROFILE:-}" ]; then
    printf '%s\n' "$OCP_PROFILE"
    return 0
  fi
  if found="$(ocp_find_ocprofile "$dir")"; then
    printf '%s\n' "$found"
    return 0
  fi
  if found="$(ocp_active_profile)"; then
    printf '%s\n' "$found"
    return 0
  fi
  return 1
}

# Describe where the resolution came from.
# ocp_resolve_source <explicit_name> <dir>
ocp_resolve_source() {
  local explicit="$1" dir="${2:-$PWD}"
  if [ -n "$explicit" ]; then
    printf 'flag\n'
    return 0
  fi
  if [ -n "${OCP_PROFILE:-}" ]; then
    printf 'env:OCP_PROFILE\n'
    return 0
  fi
  if ocp_find_ocprofile "$dir" >/dev/null; then
    printf '.ocprofile\n'
    return 0
  fi
  if ocp_active_profile >/dev/null; then
    printf 'active-default\n'
    return 0
  fi
  printf 'none\n'
}
