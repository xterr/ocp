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

# Read the active default profile name (if any).
ocp_active_profile() {
  local af name
  af="$(ocp_active_file)"
  [ -f "$af" ] || return 1
  IFS= read -r name <"$af" || name=""
  name="$(printf '%s' "$name" | tr -d '[:space:]')"
  [ -n "$name" ] || return 1
  printf '%s\n' "$name"
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
