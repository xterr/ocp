name="${args[name]}"
ocp_validate_name "$name"
ocp_profile_exists "$name" || ocp_die "Profile '$name' does not exist."

pdir="$(ocp_profile_dir "$name")"

if [ -d "$pdir/data" ] && [ -z "${args[--purge-data]}" ]; then
  ocp_die "Profile '$name' has data (auth/sessions) at $pdir/data. Re-run with --purge-data to delete everything, or back it up first."
fi

if [ -z "${args[--yes]}" ]; then
  printf "Remove profile '%s' at %s (INCLUDING data/auth/sessions)? [y/N]: " "$name" "$pdir"
  IFS= read -r ans || ans=""
  case "$ans" in
    y | Y | yes) ;;
    *)
      ocp_info "Aborted."
      exit 0
      ;;
  esac
fi

rm -rf "$pdir" || ocp_die "Failed to remove $pdir"
ocp_info "Removed profile '$name'."

active=""
ocp_active_profile >/dev/null && active="$(ocp_active_profile)"
if [ "$name" = "$active" ]; then
  rm -f "$(ocp_active_file)"
  ocp_warn "Removed the active default; set a new one with 'ocp use <name>'."
fi
