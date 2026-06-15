root="$(ocp_profiles_dir)"

if [ ! -d "$root" ]; then
  ocp_info "No profiles yet. Create one with: ocp create <name>"
  exit 0
fi

default=""
ocp_active_profile >/dev/null && default="$(ocp_active_profile)"
resolved="$(ocp_resolve_profile "" "$PWD" 2>/dev/null || true)"

found=0
for d in "$root"/*/; do
  [ -d "$d" ] || continue
  found=1
  n="$(basename "$d")"
  ocp_load_manifest "$n"
  desc=""
  [ -n "$DESCRIPTION" ] && desc="  $(cyan "$DESCRIPTION")"
  if [ "$n" = "$resolved" ]; then
    printf '%s %s%s\n' "$(green_bold "->")" "$(green_bold "$n")" "$desc"
  else
    printf '   %s%s\n' "$n" "$desc"
  fi
done

if [ "$found" = 0 ]; then
  ocp_info "No profiles yet. Create one with: ocp create <name>"
  exit 0
fi

if [ -n "$default" ]; then
  printf '\n%s %s\n' "$(cyan "default ->")" "$(cyan "$default")"
fi
