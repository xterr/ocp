## Path helpers for ocp

ocp_home() {
  printf '%s' "${OCP_HOME:-$HOME/.config/ocp}"
}

ocp_profiles_dir() {
  printf '%s' "$(ocp_home)/profiles"
}

ocp_profile_dir() {
  printf '%s' "$(ocp_profiles_dir)/$1"
}

ocp_config_dir() {
  printf '%s' "$(ocp_profile_dir "$1")/config"
}

ocp_data_dir() {
  printf '%s' "$(ocp_profile_dir "$1")/data"
}

ocp_manifest() {
  printf '%s' "$(ocp_profile_dir "$1")/profile.env"
}

ocp_env_file() {
  printf '%s' "$(ocp_profile_dir "$1")/env"
}

ocp_config_file() {
  printf '%s' "$(ocp_home)/ocp.json"
}

ocp_legacy_active_file() {
  printf '%s' "$(ocp_home)/active"
}

ocp_profile_exists() {
  [ -d "$(ocp_profile_dir "$1")" ]
}

# Expand a leading ~ to $HOME
ocp_expand() {
  case "$1" in
    "~") printf '%s' "$HOME" ;;
    "~/"*) printf '%s' "$HOME/${1#\~/}" ;;
    *) printf '%s' "$1" ;;
  esac
}
