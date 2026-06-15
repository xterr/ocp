p="$(ocp_resolve_profile "" "$PWD" 2>/dev/null || true)"
if [ -z "$p" ]; then
  ocp_info "(none) - opencode would run without a profile"
else
  ocp_info "$p"
fi
