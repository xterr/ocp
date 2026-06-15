#!/usr/bin/env bash
#
# ocp installer
#
#   curl -fsSL https://raw.githubusercontent.com/xterr/ocp/main/install.sh | bash
#   curl -fsSL .../install.sh | bash -s -- <profile-name>
#   curl -fsSL .../install.sh | bash -s -- work --version 1.2.3
#
# Args (after --): [profile-name] [--version TAG] [--no-shell] [--bin-dir DIR] [--url URL]
# Env overrides:   OCP_VERSION, OCP_REPO, OCP_BIN_DIR, OCP_SRC_URL
#
set -eu

REPO="${OCP_REPO:-xterr/ocp}"
OCP_SRC_URL="${OCP_SRC_URL:-}"
OCP_VERSION="${OCP_VERSION:-}"
BIN_DIR="${OCP_BIN_DIR:-$HOME/.local/bin}"
PROFILE="default"
PROFILE_EXPLICIT=0
DO_SHELL=1

while [ $# -gt 0 ]; do
  case "$1" in
    --no-shell) DO_SHELL=0 ;;
    --bin-dir) shift; BIN_DIR="$1" ;;
    --bin-dir=*) BIN_DIR="${1#*=}" ;;
    --version) shift; OCP_VERSION="$1" ;;
    --version=*) OCP_VERSION="${1#*=}" ;;
    --url) shift; OCP_SRC_URL="$1" ;;
    --url=*) OCP_SRC_URL="${1#*=}" ;;
    -h | --help)
      cat <<'EOF'
ocp installer

  curl -fsSL https://raw.githubusercontent.com/xterr/ocp/main/install.sh | bash
  curl -fsSL .../install.sh | bash -s -- <profile-name>
  curl -fsSL .../install.sh | bash -s -- work --version 1.2.3

Args (after --): [profile-name] [--version TAG] [--no-shell] [--bin-dir DIR] [--url URL]
Env overrides:   OCP_VERSION, OCP_REPO, OCP_BIN_DIR, OCP_SRC_URL

By default the latest GitHub release asset is installed.
EOF
      exit 0
      ;;
    -*) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
    *) PROFILE="$1"; PROFILE_EXPLICIT=1 ;;
  esac
  shift
done

if [ -z "$OCP_SRC_URL" ]; then
  if [ -n "$OCP_VERSION" ]; then
    tag="${OCP_VERSION#v}"
    OCP_SRC_URL="https://github.com/$REPO/releases/download/$tag/ocp"
  else
    OCP_SRC_URL="https://github.com/$REPO/releases/latest/download/ocp"
  fi
fi

if [ -t 1 ]; then
  G=$'\033[1;32m'; Y=$'\033[1;33m'; R=$'\033[1;31m'; B=$'\033[1m'; X=$'\033[0m'
else
  G=''; Y=''; R=''; B=''; X=''
fi
ok() { printf '%s  ok%s %s\n' "$G" "$X" "$*"; }
warn() { printf '%s  ! %s %s\n' "$Y" "$X" "$*" >&2; }
die() { printf '%s  x %s %s\n' "$R" "$X" "$*" >&2; exit 1; }

download() {
  case "$1" in
    file://*) cp "${1#file://}" "$2" ;;
    /* | ./* | ../*) cp "$1" "$2" ;;
    *)
      if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$1" -o "$2"
      elif command -v wget >/dev/null 2>&1; then
        wget -qO "$2" "$1"
      else
        die "need curl or wget to download ocp"
      fi
      ;;
  esac
}

find_bash4() {
  for b in bash /opt/homebrew/bin/bash /usr/local/bin/bash /usr/bin/bash; do
    p="$(command -v "$b" 2>/dev/null || true)"
    [ -n "$p" ] || continue
    v="$("$p" -c 'echo ${BASH_VERSINFO[0]:-0}' 2>/dev/null || echo 0)"
    if [ "${v:-0}" -ge 4 ] 2>/dev/null; then
      printf '%s\n' "$p"
      return 0
    fi
  done
  return 1
}

printf '%socp installer%s\n' "$B" "$X"

mkdir -p "$BIN_DIR" || die "cannot create $BIN_DIR"
download "$OCP_SRC_URL" "$BIN_DIR/ocp"
chmod +x "$BIN_DIR/ocp"
ok "installed ocp -> $BIN_DIR/ocp"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) warn "$BIN_DIR is not on PATH (the shell snippet below will add it)" ;;
esac

profiles_dir="${OCP_HOME:-$HOME/.config/ocp}/profiles"
any_profiles() {
  [ -d "$profiles_dir" ] || return 1
  for d in "$profiles_dir"/*/; do
    [ -d "$d" ] && return 0
  done
  return 1
}

auth_hint="$PROFILE"
if bash4="$(find_bash4)"; then
  if "$bash4" "$BIN_DIR/ocp" path "$PROFILE" >/dev/null 2>&1; then
    ok "profile '$PROFILE' already exists"
  elif [ "$PROFILE_EXPLICIT" = 1 ]; then
    "$bash4" "$BIN_DIR/ocp" create "$PROFILE" >/dev/null
    ok "created profile '$PROFILE'"
    "$bash4" "$BIN_DIR/ocp" use "$PROFILE" >/dev/null
    ok "default profile -> '$PROFILE'"
  elif any_profiles; then
    # User deleted/renamed the default; don't recreate it on every upgrade.
    ok "existing profiles found; skipping default profile creation"
    auth_hint=""
  else
    "$bash4" "$BIN_DIR/ocp" create "$PROFILE" >/dev/null
    ok "created profile '$PROFILE'"
    "$bash4" "$BIN_DIR/ocp" use "$PROFILE" >/dev/null
    ok "default profile -> '$PROFILE'"
  fi
else
  warn "bash >= 4 not found (ocp needs it). Install it (macOS: brew install bash), then: ocp create $PROFILE && ocp use $PROFILE"
fi

if [ "$DO_SHELL" = 1 ]; then
  shell_name="$(basename "${SHELL:-}")"
  rc=""
  case "$shell_name" in
    zsh)
      rc="$HOME/.zshrc"
      path_line="export PATH=\"$BIN_DIR:\$PATH\""
      init_line="eval \"\$(ocp init-shell --shell zsh)\""
      ;;
    bash)
      if [ "$(uname)" = Darwin ]; then rc="$HOME/.bash_profile"; else rc="$HOME/.bashrc"; fi
      path_line="export PATH=\"$BIN_DIR:\$PATH\""
      init_line="eval \"\$(ocp init-shell --shell bash)\""
      ;;
    fish)
      rc="$HOME/.config/fish/config.fish"
      mkdir -p "$(dirname "$rc")"
      path_line="fish_add_path $BIN_DIR"
      init_line="ocp init-shell --shell fish | source"
      ;;
  esac
  if [ -z "$rc" ]; then
    warn "unrecognized shell '${shell_name:-unknown}'; add the ocp integration to your shell rc manually (see the README)"
  elif grep -q 'ocp init-shell' "$rc" 2>/dev/null; then
    ok "shell integration already present in $rc"
  else
    printf '\n# ocp\n%s\n%s\n' "$path_line" "$init_line" >>"$rc"
    ok "added shell integration to $rc"
  fi
fi

if [ -n "$auth_hint" ]; then
  printf '\n%sDone.%s Open a new shell, then authenticate:\n' "$B" "$X"
  printf '  ocp launch -p %s -- auth login\n' "$auth_hint"
else
  printf '\n%sDone.%s Your existing profiles are intact. List them with:\n' "$B" "$X"
  printf '  ocp list\n'
fi
