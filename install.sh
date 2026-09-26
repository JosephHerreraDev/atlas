#!/usr/bin/env bash

set -Eeuo pipefail

readonly REPOSITORY_ARCHIVE="https://github.com/JosephHerreraDev/atlas/archive/refs/heads/main.tar.gz"
readonly INSTALL_DIR="${HOME}/.local/share/atlas"
readonly ATLAS_USER="$(id -un)"
readonly ATLAS_HOME="${HOME}"

die() {
  printf 'atlas installer: %s\n' "$*" >&2
  exit 1
}

run_with_spinner() {
  local message="$1"
  shift

  local -a frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local frame_index=0
  local command_pid
  local interrupted_status=0
  local output_file
  local status

  output_file="$(mktemp)"
  "$@" >"${output_file}" 2>&1 &
  command_pid=$!

  trap 'interrupted_status=130; kill "${command_pid}" 2>/dev/null || true' INT
  trap 'interrupted_status=143; kill "${command_pid}" 2>/dev/null || true' TERM

  if [[ -t 1 ]]; then
    while kill -0 "${command_pid}" 2>/dev/null; do
      printf '\r\033[2K%s %s' "${frames[frame_index]}" "${message}"
      frame_index=$(((frame_index + 1) % ${#frames[@]}))
      sleep 0.08
    done
  fi

  if wait "${command_pid}"; then
    status=0
  else
    status=$?
  fi

  trap - INT TERM

  if ((interrupted_status != 0)); then
    status="${interrupted_status}"
  fi

  if ((status == 0)); then
    [[ -t 1 ]] && printf '\r\033[2K'
    printf '✓ %s\n' "${message}"
  else
    [[ -t 2 ]] && printf '\r\033[2K' >&2
    printf '✗ %s\n' "${message}" >&2
    cat "${output_file}" >&2
  fi

  rm -f -- "${output_file}"
  return "${status}"
}

if ((EUID == 0)); then
  die "run this installer as your normal user, not as root"
fi

[[ -e /etc/NIXOS ]] || die "Atlas can only be installed on NixOS"

# A script read from standard input has no path, so it cannot access the rest
# of the repository. Download a temporary checkout and restart from there.
if [[ -z "${BASH_SOURCE[0]:-}" ]]; then
  for command_name in curl mktemp tar; do
    command -v "${command_name}" >/dev/null || die "required command not found: ${command_name}"
  done

  bootstrap_dir="$(mktemp -d)"
  trap 'rm -rf -- "${bootstrap_dir}"' EXIT

  download_atlas() {
    curl -fsSL "${REPOSITORY_ARCHIVE}" |
      tar -xz --strip-components=1 -C "${bootstrap_dir}"
  }

  run_with_spinner "Downloading Atlas" download_atlas

  bash "${bootstrap_dir}/install.sh"
  exit
fi

readonly SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

for command_name in cat cp mktemp nixos-rebuild sudo; do
  command -v "${command_name}" >/dev/null || die "required command not found: ${command_name}"
done

cat "${SOURCE_DIR}/logo.txt"
printf '\n'

printf 'Installing Atlas for %s in %s\n' "${ATLAS_USER}" "${INSTALL_DIR}"
printf '\n'

copy_atlas_files() {
  if [[ "${SOURCE_DIR}" != "${INSTALL_DIR}" && ! -e "${INSTALL_DIR}" && ! -L "${INSTALL_DIR}" ]]; then
    mkdir -p -- "$(dirname -- "${INSTALL_DIR}")"
    mkdir -- "${INSTALL_DIR}"
    cp -a -- "${SOURCE_DIR}/." "${INSTALL_DIR}/"
  fi
}

run_with_spinner "Copying Atlas files" copy_atlas_files

# The flake reads these values during impure evaluation so it can create the
# correct NixOS and Home Manager user instead of assuming a fixed account.
sudo -v
run_with_spinner "Rebuilding NixOS" \
  sudo env "ATLAS_USER=${ATLAS_USER}" "ATLAS_HOME=${ATLAS_HOME}" \
    nixos-rebuild switch --impure --flake "${INSTALL_DIR}#atlas"

# Use the installed scripts directly because the updated session PATH needs a
# new shell.
export ATLAS_PATH="${INSTALL_DIR}"
export PATH="${INSTALL_DIR}/bin:${PATH}"
theme-set nord

printf '\nAtlas is installed. Log out and back in to start the Hyprland session.\n'
