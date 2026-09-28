#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
DRY_RUN=0

usage() {
  printf '사용법: ./setup.sh [--dry-run] [--help]\n'
}

while (($#)); do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --help|-h) usage; exit 0 ;;
    *) printf '[ERROR] 알 수 없는 옵션: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$(uname -s)" != Linux ]]; then
  printf '[ERROR] Linux에서만 실행할 수 있습니다.\n' >&2
  exit 1
fi

# macOS 레포와 같은 Git 사용자 값을 기본값으로 사용한다.
source "$SCRIPT_DIR/config.sh"
if [[ -f "$SCRIPT_DIR/config.local.sh" ]]; then
  source "$SCRIPT_DIR/config.local.sh"
fi

if [[ -z "${GIT_USER_NAME:-}" || -z "${GIT_USER_EMAIL:-}" ]]; then
  printf '[ERROR] config.sh 또는 config.local.sh에 Git 이름과 이메일을 설정하세요.\n' >&2
  exit 2
fi
if ! command -v git >/dev/null 2>&1; then
  printf '[ERROR] Git을 찾을 수 없습니다.\n' >&2
  exit 1
fi

MANAGED_DIR="$HOME/.config/linux-bootstrap"
BACKUP_DIR=""

change() { printf '[CHANGE] %s\n' "$1"; }
skip() { printf '[SKIP] %s\n' "$1"; }

backup_file() {
  local path="$1" name="$2"
  [[ -e "$path" || -L "$path" ]] || return 0
  if [[ -z "$BACKUP_DIR" ]]; then
    BACKUP_DIR="$HOME/.linux-bootstrap-backups/$(date +%Y%m%d-%H%M%S)-$$"
    mkdir -p -- "$BACKUP_DIR"
  fi
  cp -p -- "$path" "$BACKUP_DIR/$name"
  printf '[BACKUP] %s\n' "$BACKUP_DIR/$name"
}

install_managed_file() {
  local source_path="$1" target_path="$2" backup_name="$3"
  if [[ -f "$target_path" ]] && cmp -s -- "$source_path" "$target_path"; then
    skip "$target_path: 이미 최신"
    return
  fi
  change "${target_path}에 설정 파일 설치"
  if ((DRY_RUN)); then return; fi
  mkdir -p -- "$MANAGED_DIR"
  backup_file "$target_path" "$backup_name"
  cp -- "$source_path" "$target_path"
}

ensure_source_block() {
  local rc_path="$1" label="$2" begin="$3" end="$4" source_line="$5" backup_name="$6"
  if [[ -f "$rc_path" ]] && grep -Fqx -- "$begin" "$rc_path"; then
    if grep -Fqx -- "$source_line" "$rc_path" && grep -Fqx -- "$end" "$rc_path"; then
      skip "$label 연결 블록: 이미 존재"
      return
    fi
    printf '[ERROR] %s의 기존 linux-bootstrap 블록을 확인하세요: %s\n' "$label" "$rc_path" >&2
    return 1
  fi
  if [[ -f "$rc_path" ]] && grep -Fqx -- "$end" "$rc_path"; then
    printf '[ERROR] %s의 기존 linux-bootstrap 블록을 확인하세요: %s\n' "$label" "$rc_path" >&2
    return 1
  fi
  change "${rc_path}에 $label 연결 블록 추가"
  if ((DRY_RUN)); then return; fi
  backup_file "$rc_path" "$backup_name"
  if [[ -s "$rc_path" ]]; then printf '\n' >> "$rc_path"; fi
  printf '%s\n%s\n%s\n' "$begin" "$source_line" "$end" >> "$rc_path"
}

install_managed_file "$SCRIPT_DIR/dotfiles/vimrc.managed" "$MANAGED_DIR/vimrc" vimrc.managed.before-bootstrap
ensure_source_block "$HOME/.vimrc" Vim \
  '" >>> linux-bootstrap >>>' '" <<< linux-bootstrap <<<' \
  'execute "source " . fnameescape(expand("$HOME/.config/linux-bootstrap/vimrc"))' \
  vimrc.before-bootstrap

install_managed_file "$SCRIPT_DIR/dotfiles/bashrc.managed" "$MANAGED_DIR/bashrc" bashrc.managed.before-bootstrap
ensure_source_block "$HOME/.bashrc" Bash \
  '# >>> linux-bootstrap >>>' '# <<< linux-bootstrap <<<' \
  '[ -f "$HOME/.config/linux-bootstrap/bashrc" ] && . "$HOME/.config/linux-bootstrap/bashrc"' \
  bashrc.before-bootstrap

configure_git() {
  local key="$1" desired="$2" current
  current="$(git config --global --get "$key" || true)"
  if [[ "$current" == "$desired" ]]; then
    skip "Git $key: 이미 설정됨"
    return
  fi
  change "Git $key: ${current:-미설정} -> $desired"
  if ((DRY_RUN)); then return; fi
  git config --global --replace-all "$key" "$desired"
}

configure_git user.name "$GIT_USER_NAME"
configure_git user.email "$GIT_USER_EMAIL"

if ((DRY_RUN)); then
  printf '\n[DRY RUN] 실제 파일과 Git 설정은 변경하지 않았습니다.\n'
else
  printf '\n완료. Bash 별칭을 현재 셸에 반영하려면 새 Bash 셸을 여세요.\n'
fi
