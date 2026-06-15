#!/usr/bin/env bash
#
# ocp installer
#
#   curl -fsSL <raw-url>/install.sh | bash
#   curl -fsSL <raw-url>/install.sh | bash -s -- <profile-name>
#
# Options (after `--`): [profile-name] [--no-shell] [--bin-dir DIR] [--url URL]
# Env overrides: OCP_SRC_URL, OCP_BIN_DIR
#
set -eu

OCP_SRC_URL="${OCP_SRC_URL:-https://raw.githubusercontent.com/xterr/ocp/main/ocp}"
BIN_DIR="${OCP_BIN_DIR:-$HOME/.local/bin}"
PROFILE="default"
DO_SHELL=1

while [ $# -gt 0 ]; do
  case "$1" in
    --no-shell) DO_SHELL=0 ;;
    --bin-dir) shift; BIN_DIR="$1" ;;
    --bin-dir=*) BIN_DIR="${1#*=}" ;;
    --url) shift; OCP_SRC_URL="$1" ;;
    --url=*) OCP_SRC_URL="${1#*=}" ;;
    -h | --help)
      cat <<'EOF'
ocp installer

  curl -fsSL <raw-url>/install.sh | bash
  curl -fsSL <raw-url>/install.sh | bash -s -- <profile-name>

Options (after --): [profile-name] [--no-shell] [--bin-dir DIR] [--url URL]
Env overrides:      OCP_SRC_URL, OCP_BIN_DIR
EOF
      exit 0
      ;;
    -*) printf 'Unknown option: %s\n' "$1" >&2; exit 1 ;;
    *) PROFILE="$1" ;;
  esac
  shift
done

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

detect_rc() {
  case "$(basename "${SHELL:-}")" in
    zsh) printf '%s\n' "$HOME/.zshrc" ;;
    bash) [ "$(uname)" = Darwin ] && printf '%s\n' "$HOME/.bash_profile" || printf '%s\n' "$HOME/.bashrc" ;;
    *) printf '\n' ;;
  esac
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

if bash4="$(find_bash4)"; then
  if "$bash4" "$BIN_DIR/ocp" path "$PROFILE" >/dev/null 2>&1; then
    ok "profile '$PROFILE' already exists"
  else
    "$bash4" "$BIN_DIR/ocp" create "$PROFILE" >/dev/null
    ok "created profile '$PROFILE'"
  fi
  "$bash4" "$BIN_DIR/ocp" use "$PROFILE" >/dev/null
  ok "default profile -> '$PROFILE'"
else
  warn "bash >= 4 not found (ocp needs it). Install it (macOS: brew install bash), then: ocp create $PROFILE && ocp use $PROFILE"
fi

if [ "$DO_SHELL" = 1 ]; then
  rc="$(detect_rc)"
  if [ -z "$rc" ]; then
    warn "could not detect your shell rc; add this line manually:  eval \"\$(ocp init-shell)\""
  elif grep -q 'ocp init-shell' "$rc" 2>/dev/null; then
    ok "shell integration already present in $rc"
  else
    printf '\n# ocp\nexport PATH="%s:$PATH"\neval "$(ocp init-shell)"\n' "$BIN_DIR" >>"$rc"
    ok "added shell integration to $rc"
  fi
fi

printf '\n%sDone.%s Open a new shell, then authenticate:\n' "$B" "$X"
printf '  ocp launch -p %s -- auth login\n' "$PROFILE"
