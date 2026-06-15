cmd="${args[--command]:-opencode}"
shell="${args[--shell]:-}"
[ -n "$shell" ] || shell="$(basename "${SHELL:-}")"

profiles=()
if [ -n "${args[--per-profile-aliases]}" ]; then
  root="$(ocp_profiles_dir)"
  if [ -d "$root" ]; then
    for d in "$root"/*/; do
      [ -d "$d" ] || continue
      profiles+=("$(basename "$d")")
    done
  fi
fi

printf '# >>> ocp shell integration >>>\n'

case "$shell" in
  fish)
    printf 'function %s; command ocp launch -- $argv; end\n' "$cmd"
    if [ -z "${args[--no-chpwd]}" ]; then
      printf 'function _ocp_chpwd --on-variable PWD; set -gx OCP_ACTIVE_PROFILE (command ocp resolve --quiet 2>/dev/null); end\n'
      printf '_ocp_chpwd\n'
    fi
    if [ "${#profiles[@]}" -gt 0 ]; then
      for n in "${profiles[@]}"; do
        printf 'function %s-%s; command ocp launch -p %s -- $argv; end\n' "$cmd" "$n" "$n"
      done
    fi
    ;;
  bash)
    printf '%s() { command ocp launch -- "$@"; }\n' "$cmd"
    if [ -z "${args[--no-chpwd]}" ]; then
      printf '_ocp_chpwd() { [ "$PWD" = "${_OCP_LAST_PWD:-}" ] && return; _OCP_LAST_PWD="$PWD"; export OCP_ACTIVE_PROFILE="$(command ocp resolve --quiet 2>/dev/null)"; }\n'
      printf 'case "${PROMPT_COMMAND:-}" in *_ocp_chpwd*) ;; *) PROMPT_COMMAND="_ocp_chpwd${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;; esac\n'
      printf '_ocp_chpwd\n'
    fi
    if [ "${#profiles[@]}" -gt 0 ]; then
      for n in "${profiles[@]}"; do
        printf '%s-%s() { command ocp launch -p %s -- "$@"; }\n' "$cmd" "$n" "$n"
      done
    fi
    ;;
  zsh)
    printf '%s() { command ocp launch -- "$@"; }\n' "$cmd"
    if [ -z "${args[--no-chpwd]}" ]; then
      printf '_ocp_chpwd() { export OCP_ACTIVE_PROFILE="$(command ocp resolve --quiet 2>/dev/null)"; }\n'
      printf 'autoload -Uz add-zsh-hook 2>/dev/null && add-zsh-hook chpwd _ocp_chpwd\n'
      printf '_ocp_chpwd\n'
    fi
    if [ "${#profiles[@]}" -gt 0 ]; then
      for n in "${profiles[@]}"; do
        printf '%s-%s() { command ocp launch -p %s -- "$@"; }\n' "$cmd" "$n" "$n"
      done
    fi
    ;;
  *)
    printf '%s() { command ocp launch -- "$@"; }\n' "$cmd"
    if [ "${#profiles[@]}" -gt 0 ]; then
      for n in "${profiles[@]}"; do
        printf '%s-%s() { command ocp launch -p %s -- "$@"; }\n' "$cmd" "$n" "$n"
      done
    fi
    ;;
esac

printf '# <<< ocp shell integration <<<\n'
