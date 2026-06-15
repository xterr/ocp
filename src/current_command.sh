p="$(ocp_resolve_profile "" "$PWD" 2>/dev/null || true)"
if [ -z "$p" ]; then
  ocp_info "$(yellow "(none)") - opencode would run without a profile"
else
  green_bold "$p"
fi
