## State migrations for ocp
##
## On-disk state under $OCP_HOME evolves over time. Each schema version N has an
## idempotent `ocp_migration_N` that upgrades state from N-1 to N. The applied
## version is tracked by the integer `version` field in ocp.json (the source of
## truth); missing/legacy state is treated as version 0. To add a future
## migration: write `ocp_migration_<N>` and bump OCP_SCHEMA_VERSION.

OCP_SCHEMA_VERSION=1

# Extract a flat JSON integer value (no jq). Profile data is ASCII so a targeted
# match is safe and keeps ocp dependency-free.
ocp_json_get_number() {
  local file="$1" key="$2" val
  [ -f "$file" ] || return 1
  val="$(sed -n "s/.*\"$key\"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p" "$file" | head -n1)"
  [ -n "$val" ] || return 1
  printf '%s\n' "$val"
}

# Print the current on-disk schema version. ocp.json -> its version (default 1
# if the field is absent); legacy `active` file only -> 0; no state -> fail.
ocp_state_version() {
  local cfg legacy v
  cfg="$(ocp_config_file)"
  legacy="$(ocp_legacy_active_file)"
  if [ -f "$cfg" ]; then
    if v="$(ocp_json_get_number "$cfg" version)"; then
      printf '%s\n' "$v"
    else
      printf '1\n'
    fi
    return 0
  fi
  [ -f "$legacy" ] && { printf '0\n'; return 0; }
  return 1
}

ocp_set_version() {
  local n="$1" f
  f="$(ocp_config_file)"
  [ -f "$f" ] || return 0
  if grep -q '"version"' "$f" 2>/dev/null; then
    sed "s/\"version\"[[:space:]]*:[[:space:]]*[0-9][0-9]*/\"version\": $n/" "$f" >"$f.tmp" 2>/dev/null &&
      mv "$f.tmp" "$f" 2>/dev/null
    rm -f "$f.tmp" 2>/dev/null || true
  fi
}

# mkdir is atomic on POSIX, so it doubles as a lock. A lock older than 60s is
# treated as stale (left by a killed process) and reclaimed.
ocp_migrate_lock() {
  local lock now mtime
  lock="$(ocp_home)/.migrate.lock"
  mkdir -p "$(ocp_home)" 2>/dev/null || return 1
  if [ -d "$lock" ]; then
    now="$(date +%s 2>/dev/null || echo 0)"
    mtime="$(stat -f %m "$lock" 2>/dev/null || stat -c %Y "$lock" 2>/dev/null || echo 0)"
    [ "$(( now - mtime ))" -gt 60 ] 2>/dev/null && rm -rf "$lock" 2>/dev/null
  fi
  mkdir "$lock" 2>/dev/null || return 1
  return 0
}

ocp_migrate_unlock() {
  rm -rf "$(ocp_home)/.migrate.lock" 2>/dev/null || true
}

# Copy the current state file aside before migrating, so a bad or unwanted
# migration can be recovered. Named by source version and a timestamp
# (e.g. ocp.json.v1.20260615T221530.bak) so repeated runs never clobber a backup.
ocp_backup_state() {
  local from="$1" src dst ts
  if [ -f "$(ocp_config_file)" ]; then
    src="$(ocp_config_file)"
  elif [ -f "$(ocp_legacy_active_file)" ]; then
    src="$(ocp_legacy_active_file)"
  else
    return 0
  fi
  ts="$(date +%Y%m%dT%H%M%S 2>/dev/null || date +%s 2>/dev/null || echo backup)"
  dst="$(ocp_home)/$(basename "$src").v$from.$ts.bak"
  cp "$src" "$dst" 2>/dev/null && printf '%s\n' "$dst"
  return 0
}

# v0 -> v1: replace the plain-text `active` file with ocp.json.
ocp_migration_1() {
  local name
  if name="$(ocp_read_active_file "$(ocp_legacy_active_file)")"; then
    ocp_write_config "$name"
  else
    ocp_write_config ""
  fi
  rm -f "$(ocp_legacy_active_file)" 2>/dev/null || true
}

ocp_apply_migrations() {
  local verbose="$1" from to v backup
  if ! from="$(ocp_state_version)"; then
    [ -n "$verbose" ] && ocp_info "No ocp state found; nothing to migrate."
    return 0
  fi
  to="$OCP_SCHEMA_VERSION"

  if [ "$from" -gt "$to" ] 2>/dev/null; then
    [ -n "$verbose" ] && ocp_warn "ocp.json is schema v$from but this ocp supports up to v$to; update ocp. Leaving it untouched."
    return 0
  fi
  if [ "$from" -ge "$to" ] 2>/dev/null; then
    [ -n "$verbose" ] && ocp_info "Already at schema v$to; nothing to migrate."
    return 0
  fi

  ocp_migrate_lock || { [ -n "$verbose" ] && ocp_warn "another migration is in progress; skipping."; return 0; }

  backup="$(ocp_backup_state "$from")"
  if [ -n "$backup" ]; then
    if [ -n "$verbose" ]; then
      ocp_info "  backed up state to $backup"
    else
      printf 'ocp: backed up state to %s\n' "$backup" >&2
    fi
  fi

  if [ -n "$verbose" ]; then
    ocp_info "Migrating ocp state: v$from -> v$to"
  else
    printf 'ocp: migrating state v%s -> v%s\n' "$from" "$to" >&2
  fi

  v="$from"
  while [ "$v" -lt "$to" ]; do
    v=$(( v + 1 ))
    if "ocp_migration_$v"; then
      ocp_set_version "$v"
      [ -n "$verbose" ] && ocp_info "  applied migration v$v"
    else
      ocp_migrate_unlock
      ocp_warn "migration v$v failed; state left at v$(( v - 1 ))."
      return 1
    fi
  done

  ocp_migrate_unlock
  [ -n "$verbose" ] && ocp_success "Migration complete (now at v$to)."
  return 0
}

# Best-effort auto-migration for the startup hook: never aborts the command and
# never writes to stdout (the shell hook captures `ocp resolve --quiet`).
ocp_migrate_auto() {
  set +e
  ocp_apply_migrations "" >/dev/null
  set -e
  return 0
}
