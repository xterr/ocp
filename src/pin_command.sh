name="${args[name]}"
ocp_validate_name "$name"

dir="${args[dir]:-$PWD}"
dir="$(ocp_expand "$dir")"
[ -d "$dir" ] || ocp_die "Directory not found: $dir"

ocp_profile_exists "$name" || ocp_warn "Profile '$name' does not exist yet (create it with: ocp create $name)."

printf '%s\n' "$name" >"$dir/.ocprofile" || ocp_die "Failed to write .ocprofile"
ocp_info "Pinned '$name' in $dir/.ocprofile"
