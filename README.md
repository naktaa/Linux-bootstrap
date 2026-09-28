# Linux-bootstrap

Ubuntu 환경에서 기본 개발 패키지와 Vim, Bash, Git 사용자 설정을 적용한다.
기존 `~/.vimrc`와 `~/.bashrc` 내용은 보존하고 관리 설정을 불러오는 블록만 추가한다.

## 새 Ubuntu에서 처음 실행

OrbStack Ubuntu 머신에 직접 접속해 레포를 머신 안에 clone하려면, 처음에는 Git이
없으므로 Git 설치만 먼저 실행한다.

```bash
sudo apt-get update
sudo apt-get install -y git
./install.sh && exec bash
```

`install.sh`가 나머지 패키지를 설치하고 Vim·Bash·Git 사용자 설정을 적용한다.
Git도 설치 목록에 있지만, 위 순서에서는 이미 설치된 것으로 확인하고 건너뛴다.

Git을 미리 설치하고 싶지 않다면 OrbStack에서 Mac 파일이 보이는 `/mnt/mac` 경로의
레포를 직접 실행할 수도 있다. 이 경우 Ubuntu에 Git이 없어도 `install.sh`가
Git을 설치한다.

```bash
cd "/mnt/mac/Users/$USER/Linux-bootstrap"
./install.sh && exec bash
```

`install.sh`는 별도 프로세스에서 실행되므로 현재 터미널의 Bash 설정을 직접
바꿀 수 없다. `&& exec bash`는 설치에 성공한 뒤 현재 셸을 새 Bash로 교체해
`~/.bashrc`의 별칭을 즉시 반영한다. 새 터미널을 열 예정이라면 생략해도 된다.
공유 폴더에서 실행 권한 문제가 나면 `bash install.sh && exec bash`를 사용한다.

패키지 설치에만 `sudo`를 사용하므로 **`sudo ./install.sh`로 실행하지 않는다.**
재실행 시 이미 설치된 패키지와 Vim·Bash 연결 블록은 건너뛴다.

설치 패키지: `git`, `curl`, `wget`, `unzip`, `build-essential`, `procps`,
`psmisc`, `htop`, `acl`, `tree`, `vim`, `openssh-client`.

## 사용자 설정만 다시 적용

```bash
./setup.sh --dry-run
./setup.sh
```

`--dry-run`은 변경 예정 항목만 출력한다. 실제 실행 후 새 Bash 셸을 열면 별칭이 반영된다.
기존 파일을 변경할 때는 `~/.linux-bootstrap-backups/` 아래에 백업을 만든다.

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
