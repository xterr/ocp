name="${args[name]}"
ocp_validate_name "$name"
ocp_profile_exists "$name" || ocp_die "Profile '$name' does not exist."

cfg="$(ocp_config_dir "$name")"
data="$(ocp_data_dir "$name")"
envf="$(ocp_env_file "$name")"
ocp_load_manifest "$name"

cmd=(opencode auth login)

if [ -n "${WRAPPER:-}" ]; then
  w="$WRAPPER"
  w="${w//\{profile_dir\}/$(ocp_profile_dir "$name")}"
  w="${w//\{config_dir\}/$cfg}"
  w="${w//\{data_dir\}/$data}"
  read -ra wrap <<<"$w"
  cmd=("${wrap[@]}" "${cmd[@]}")
fi

if [ -f "$envf" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$envf"
  set +a
fi

exec env OPENCODE_CONFIG_DIR="$cfg" XDG_DATA_HOME="$data" "${cmd[@]}"
