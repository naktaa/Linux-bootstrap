#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

usage() {
  printf '사용법: bash install.sh [--help]\n'
}

while (($#)); do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    *) printf '[ERROR] 알 수 없는 옵션: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ ! -r /etc/os-release ]]; then
  printf '[ERROR] /etc/os-release를 읽을 수 없습니다. Ubuntu에서 실행하세요.\n' >&2
  exit 1
fi
source /etc/os-release
if [[ "${ID:-}" != ubuntu ]]; then
  printf '[ERROR] Ubuntu에서만 실행할 수 있습니다. 현재 배포판: %s\n' "${ID:-알 수 없음}" >&2
  exit 1
fi
if ((EUID == 0)); then
  printf '[ERROR] sudo 없이 일반 사용자로 실행하세요. 패키지 설치에만 sudo를 사용합니다.\n' >&2
  exit 1
fi
if ! command -v apt-get >/dev/null 2>&1 || ! command -v dpkg-query >/dev/null 2>&1; then
  printf '[ERROR] apt-get 또는 dpkg-query를 찾을 수 없습니다.\n' >&2
  exit 1
fi

packages=(
  git curl wget unzip build-essential procps psmisc htop acl tree vim openssh-client
)
missing_packages=()
for package in "${packages[@]}"; do
  if [[ "$(dpkg-query -W -f='${Status}' "$package" 2>/dev/null || true)" != 'install ok installed' ]]; then
    missing_packages+=("$package")
  fi
done

if ((${#missing_packages[@]})); then
  if ! command -v sudo >/dev/null 2>&1; then
    printf '[ERROR] 패키지 설치에 필요한 sudo를 찾을 수 없습니다.\n' >&2
    exit 1
  fi
  printf '[CHANGE] 패키지 설치: %s\n' "${missing_packages[*]}"
  sudo apt-get update
  sudo apt-get install -y "${missing_packages[@]}"
else
  printf '[SKIP] 요청한 패키지가 모두 설치되어 있습니다.\n'
fi

printf '\n=== 사용자 설정 적용 ===\n'
bash "$SCRIPT_DIR/setup.sh"
