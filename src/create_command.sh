name="${args[name]}"
ocp_validate_name "$name"

pdir="$(ocp_profile_dir "$name")"

if [ -d "$pdir" ] && [ -z "${args[--force]}" ]; then
  ocp_die "Profile '$name' already exists. Use --force to overwrite."
fi

mkdir -p "$pdir/config" "$pdir/data/opencode" || ocp_die "Failed to create profile dirs."

from="${args[--from]:-}"
if [ -n "$from" ]; then
  from="$(ocp_expand "$from")"
  [ -d "$from" ] || ocp_die "--from dir not found: $from"
  cp -R "$from/." "$pdir/config/" || ocp_die "Failed to copy config from $from"
  ocp_info "Seeded config from $from"
fi

envf="${args[--env-file]:-}"
if [ -n "$envf" ]; then
  envf="$(ocp_expand "$envf")"
  [ -f "$envf" ] || ocp_die "--env-file not found: $envf"
  cp "$envf" "$(ocp_env_file "$name")" || ocp_die "Failed to copy env-file"
  chmod 600 "$(ocp_env_file "$name")" 2>/dev/null || true
  ocp_info "Installed env file -> env"
fi

seeded_auth=""
if [ -n "${args[--seed-auth]}" ]; then
  shared="${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json"
  if [ -f "$shared" ]; then
    cp "$shared" "$pdir/data/opencode/auth.json" || ocp_die "Failed to seed auth.json"
    chmod 600 "$pdir/data/opencode/auth.json" 2>/dev/null || true
    seeded_auth=1
    ocp_info "Seeded auth.json from $shared"
  else
    ocp_warn "No shared auth.json found at $shared; skipping --seed-auth"
  fi
fi

ocp_write_manifest "$name" "${args[--description]:-}" "${args[--wrapper]:-}" ""

ocp_success "Created profile '$name' at $pdir"
if [ -z "$seeded_auth" ]; then
  ocp_info "Next: run 'ocp launch -p $name -- auth login' to authenticate this profile."
fi
