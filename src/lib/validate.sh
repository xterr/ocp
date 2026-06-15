## Output + validation helpers for ocp

ocp_die() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

ocp_info() {
  printf '%s\n' "$1"
}

ocp_warn() {
  printf 'Warning: %s\n' "$1" >&2
}

ocp_validate_name() {
  case "$1" in
    '')
      ocp_die "Profile name cannot be empty."
      ;;
    *[!A-Za-z0-9_-]*)
      ocp_die "Profile name may only contain letters, numbers, '_' and '-'."
      ;;
  esac
}
