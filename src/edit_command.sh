name="${args[name]}"
what="${args[--what]:-config}"
ocp_profile_exists "$name" || ocp_die "Profile '$name' does not exist."

pdir="$(ocp_profile_dir "$name")"
case "$what" in
  config) target="$pdir/config" ;;
  manifest) target="$(ocp_manifest "$name")" ;;
  opencode-json) target="$pdir/config/opencode.json" ;;
  omo) target="$pdir/config/oh-my-openagent.json" ;;
  env) target="$(ocp_env_file "$name")" ;;
  data) target="$pdir/data/opencode" ;;
  *) ocp_die "Unknown --what target: $what" ;;
esac

ed="${VISUAL:-${EDITOR:-}}"
if [ -z "$ed" ]; then
  ocp_info "$target"
  ocp_die "No \$EDITOR/\$VISUAL set; path printed above."
fi

exec "$ed" "$target"
