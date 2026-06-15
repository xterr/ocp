old="${args[old]}"
new="${args[new]}"
ocp_validate_name "$old"
ocp_validate_name "$new"

[ "$old" = "$new" ] && ocp_die "Old and new names are the same."
ocp_profile_exists "$old" || ocp_die "Profile '$old' does not exist."
ocp_profile_exists "$new" && ocp_die "Profile '$new' already exists. Choose another name or remove it first."

olddir="$(ocp_profile_dir "$old")"
newdir="$(ocp_profile_dir "$new")"

mv "$olddir" "$newdir" || ocp_die "Failed to rename $olddir -> $newdir"
ocp_success "Renamed profile '$old' -> '$new'."

active=""
ocp_active_profile >/dev/null && active="$(ocp_active_profile)"
if [ "$active" = "$old" ]; then
  ocp_set_active "$new"
  ocp_info "Default profile updated -> '$new'."
fi

ocp_warn "Pinned .ocprofile files referencing '$old' are not updated; re-pin with: ocp pin $new <dir>"
ocp_info "If you use per-profile shell aliases, reload your shell to refresh the 'opencode-<name>' launchers."
