if [ -n "${args[--check]}" ]; then
  cur="$(ocp_state_version 2>/dev/null || true)"
  [ -n "$cur" ] || cur="(none)"
  ocp_info "Current schema version: $cur"
  ocp_info "Target schema version:  $OCP_SCHEMA_VERSION"
  exit 0
fi

ocp_apply_migrations "verbose"
