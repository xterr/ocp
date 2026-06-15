dir="${args[dir]:-$PWD}"
dir="$(ocp_expand "$dir")"

p="$(ocp_resolve_profile "" "$dir" 2>/dev/null || true)"

if [ -n "${args[--quiet]}" ]; then
  [ -n "$p" ] && printf '%s\n' "$p"
  exit 0
fi

src="$(ocp_resolve_source "" "$dir")"

if [ -z "$p" ]; then
  ocp_info "profile : (none)"
  ocp_info "source  : $src"
  exit 0
fi

ocp_info "profile : $p"
ocp_info "source  : $src"
ocp_info "config  : $(ocp_config_dir "$p")"
ocp_info "data    : $(ocp_data_dir "$p")"
if ! ocp_profile_exists "$p"; then
  ocp_warn "profile '$p' is selected but does not exist (create it with: ocp create $p)"
fi
