version="${args[version]:-}"
repo="${OCP_REPO:-xterr/ocp}"

self="${BASH_SOURCE[0]:-$0}"
case "$self" in
  */*) ;;
  *) self="$(command -v "$self" 2>/dev/null || true)" ;;
esac
{ [ -n "$self" ] && [ -e "$self" ]; } || self="$(command -v ocp 2>/dev/null || true)"
[ -n "$self" ] || ocp_die "could not locate the ocp binary to update"
self_dir="$(cd "$(dirname "$self")" && pwd)"
self="$self_dir/$(basename "$self")"

if [ -n "$version" ]; then
  tag="${version#v}"
  url="https://github.com/$repo/releases/download/$tag/ocp"
  label="$tag"
else
  url="https://github.com/$repo/releases/latest/download/ocp"
  label="latest"
fi

[ -w "$self_dir" ] || ocp_die "no write permission for $self_dir (re-run with sudo, or reinstall via the install script)"

cur_ver="$("$self" --version 2>/dev/null | head -1 | tr -d '[:space:]')"

tmp="$self_dir/.ocp.update.$$"
trap 'rm -f "$tmp"' EXIT

if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$tmp" || ocp_die "download failed: $url (no such version? see https://github.com/$repo/releases)"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$tmp" "$url" || ocp_die "download failed: $url"
else
  ocp_die "need curl or wget to download ocp"
fi

[ -s "$tmp" ] || ocp_die "downloaded file is empty"
head -1 "$tmp" | grep -q '^#!.*bash' || ocp_die "downloaded file is not an ocp script (got an unexpected response)"
bash -n "$tmp" || ocp_die "downloaded file failed a syntax check; aborting"
chmod +x "$tmp"

new_ver="$("$tmp" --version 2>/dev/null | head -1 | tr -d '[:space:]')"

if [ -z "$version" ] && [ -z "${args[--force]}" ] && [ -n "$new_ver" ] && [ "$new_ver" = "$cur_ver" ]; then
  ocp_info "ocp is already up to date ($cur_ver)"
  exit 0
fi

mv "$tmp" "$self" || ocp_die "failed to replace $self"
trap - EXIT

ocp_success "Updated ocp ${cur_ver:-?} -> ${new_ver:-$label}  ($self)"
