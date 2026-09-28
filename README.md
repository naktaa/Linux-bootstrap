# Linux-bootstrap

Linux 환경에서 Vim 설정, Bash 별칭, Git 사용자 이름과 이메일을 적용한다.
기존 `~/.vimrc`와 `~/.bashrc` 내용은 보존하고 관리 설정을 불러오는 블록만 추가한다.

## 실행

```bash
./setup.sh --dry-run
./setup.sh
```

`--dry-run`은 변경 예정 항목만 출력한다. 실제 실행 후 새 Bash 셸을 열면 별칭이 반영된다.
재실행해도 연결 블록은 중복 추가되지 않는다. 기존 파일을 변경할 때는
`~/.linux-bootstrap-backups/` 아래에 백업을 만든다.

## 적용 항목

- Vim: `dotfiles/vimrc.managed`의 설정을 그대로 사용한다.
- Bash: `c=clear`, `py=python3` 별칭을 추가한다.
- Git: global `user.name`, `user.email`을 `config.sh`의 값으로 설정한다.

Git 이름과 이메일을 이 레포의 기본값과 다르게 사용하려면 `config.local.sh`를 만들고
아래 두 값을 지정한다. 이 파일은 Git에 포함되지 않는다.

```bash
GIT_USER_NAME="본인 이름"
GIT_USER_EMAIL="you@example.com"
```

설정 파일은 `~/.config/linux-bootstrap/`에 복사된다. `~/.vimrc`와
`~/.bashrc`의 연결 블록이 해당 파일을 불러온다.
