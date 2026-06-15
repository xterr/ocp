root="$(ocp_profiles_dir)"

if [ ! -d "$root" ]; then
  ocp_info "No profiles yet. Create one with: ocp create <name>"
  exit 0
fi

active=""
ocp_active_profile >/dev/null && active="$(ocp_active_profile)"
resolved="$(ocp_resolve_profile "" "$PWD" 2>/dev/null || true)"

found=0
for d in "$root"/*/; do
  [ -d "$d" ] || continue
  found=1
  n="$(basename "$d")"
  marks=""
  [ "$n" = "$active" ] && marks="$marks default"
  [ "$n" = "$resolved" ] && marks="$marks here"
  ocp_load_manifest "$n"
  desc=""
  [ -n "$DESCRIPTION" ] && desc=" - $DESCRIPTION"
  if [ -n "$marks" ]; then
    printf '  %s [%s]%s\n' "$n" "${marks# }" "$desc"
  else
    printf '  %s%s\n' "$n" "$desc"
  fi
done

[ "$found" = 0 ] && ocp_info "No profiles yet. Create one with: ocp create <name>"
