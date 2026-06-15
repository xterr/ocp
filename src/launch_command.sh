p="$(ocp_resolve_profile "${args[--profile]:-}" "$PWD" 2>/dev/null || true)"
src="$(ocp_resolve_source "${args[--profile]:-}" "$PWD" 2>/dev/null || true)"

if [ -n "$p" ] && ! ocp_profile_exists "$p"; then
  if [ "$src" = "active-default" ]; then
    ocp_warn "Default profile '$p' no longer exists; running opencode without a profile. Set a new default with 'ocp use <name>'."
    p=""
  else
    ocp_die "Profile '$p' does not exist. Create it with: ocp create $p"
  fi
fi

pass=()
if [ "${other_args[*]:-}" != "" ]; then
  pass=("${other_args[@]}")
fi

if [ -z "$p" ]; then
  if [ -n "${args[--print]}" ]; then
    printf 'exec'
    printf ' %q' opencode "${pass[@]}"
    printf '\n'
    exit 0
  fi
  exec opencode "${pass[@]}"
fi

cfg="$(ocp_config_dir "$p")"
data="$(ocp_data_dir "$p")"
envf="$(ocp_env_file "$p")"
ocp_load_manifest "$p"

cmd=(opencode)
if [ -n "${DEFAULT_ARGS:-}" ]; then
  # shellcheck disable=SC2206
  cmd+=($DEFAULT_ARGS)
fi
cmd+=("${pass[@]}")

if [ -n "${WRAPPER:-}" ]; then
  w="$WRAPPER"
  w="${w//\{profile_dir\}/$(ocp_profile_dir "$p")}"
  w="${w//\{config_dir\}/$cfg}"
  w="${w//\{data_dir\}/$data}"
  read -ra wrap <<<"$w"
  cmd=("${wrap[@]}" "${cmd[@]}")
fi

if [ -n "${args[--print]}" ]; then
  printf 'OPENCODE_CONFIG_DIR=%s\n' "$cfg"
  printf 'XDG_DATA_HOME=%s\n' "$data"
  [ -f "$envf" ] && printf 'env-file: %s\n' "$envf"
  printf 'exec'
  printf ' %q' "${cmd[@]}"
  printf '\n'
  exit 0
fi

if [ -f "$envf" ]; then
  set -a
  # shellcheck disable=SC1090
  . "$envf"
  set +a
fi

exec env OPENCODE_CONFIG_DIR="$cfg" XDG_DATA_HOME="$data" "${cmd[@]}"
