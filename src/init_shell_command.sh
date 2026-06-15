cmd="${args[--command]:-opencode}"

printf '# >>> ocp shell integration >>>\n'
printf '%s() { command ocp launch -- "$@"; }\n' "$cmd"

if [ -z "${args[--no-chpwd]}" ]; then
  printf '_ocp_chpwd() { export OCP_ACTIVE_PROFILE="$(command ocp resolve --quiet 2>/dev/null)"; }\n'
  printf 'autoload -Uz add-zsh-hook 2>/dev/null && add-zsh-hook chpwd _ocp_chpwd\n'
  printf '_ocp_chpwd\n'
fi

if [ -n "${args[--per-profile-aliases]}" ]; then
  root="$(ocp_profiles_dir)"
  if [ -d "$root" ]; then
    for d in "$root"/*/; do
      [ -d "$d" ] || continue
      n="$(basename "$d")"
      printf '%s-%s() { command ocp launch -p %s -- "$@"; }\n' "$cmd" "$n" "$n"
    done
  fi
fi

printf '# <<< ocp shell integration <<<\n'
