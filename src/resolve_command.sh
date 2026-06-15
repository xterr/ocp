dir="${args[dir]:-$PWD}"
dir="$(ocp_expand "$dir")"

p="$(ocp_resolve_profile "" "$dir" 2>/dev/null || true)"

if [ -n "${args[--quiet]}" ]; then
  [ -n "$p" ] && printf '%s\n' "$p"
  exit 0
fi

src="$(ocp_resolve_source "" "$dir")"

if [ -z "$p" ]; then
  printf 'profile : %s\n' "$(yellow "(none)")"
  printf 'source  : %s\n' "$(cyan "$src")"
  exit 0
fi

printf 'profile : %s\n' "$(green_bold "$p")"
printf 'source  : %s\n' "$(cyan "$src")"
printf 'config  : %s\n' "$(ocp_config_dir "$p")"
printf 'data    : %s\n' "$(ocp_data_dir "$p")"
if ! ocp_profile_exists "$p"; then
  ocp_warn "profile '$p' is selected but does not exist (create it with: ocp create $p)"
fi
