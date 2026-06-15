## Profile manifest (profile.env) read/write helpers

# Quote a value for safe sourcing
ocp_q() {
  local v="$1"
  v="${v//\\/\\\\}"
  v="${v//\"/\\\"}"
  printf '"%s"' "$v"
}

# Load manifest fields into the current shell.
# Sets: DESCRIPTION WRAPPER DEFAULT_ARGS
ocp_load_manifest() {
  local f
  f="$(ocp_manifest "$1")"
  DESCRIPTION=""
  WRAPPER=""
  DEFAULT_ARGS=""
  if [ -f "$f" ]; then
    # shellcheck disable=SC1090
    . "$f"
  fi
}

# ocp_write_manifest <name> <description> <wrapper> <default_args>
ocp_write_manifest() {
  local f
  f="$(ocp_manifest "$1")"
  {
    printf 'DESCRIPTION=%s\n' "$(ocp_q "$2")"
    printf 'WRAPPER=%s\n' "$(ocp_q "$3")"
    printf 'DEFAULT_ARGS=%s\n' "$(ocp_q "$4")"
  } >"$f" || ocp_die "Failed to write manifest: $f"
}
