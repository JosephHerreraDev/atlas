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

  printf 'Downloading Atlas...\n'
  curl -fsSL "${REPOSITORY_ARCHIVE}" |
    tar -xz --strip-components=1 -C "${bootstrap_dir}"

  bash "${bootstrap_dir}/install.sh"
  exit
fi

readonly SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

for command_name in cat cp nixos-rebuild sudo; do
  command -v "${command_name}" >/dev/null || die "required command not found: ${command_name}"
done

cat "${SOURCE_DIR}/logo.txt"
printf '\n'

printf 'Installing Atlas for %s in %s\n' "${ATLAS_USER}" "${INSTALL_DIR}"

if [[ "${SOURCE_DIR}" != "${INSTALL_DIR}" && ! -e "${INSTALL_DIR}" && ! -L "${INSTALL_DIR}" ]]; then
  mkdir -p -- "$(dirname -- "${INSTALL_DIR}")"
  mkdir -- "${INSTALL_DIR}"
  cp -a -- "${SOURCE_DIR}/." "${INSTALL_DIR}/"
fi

# The flake reads these values during impure evaluation so it can create the
# correct NixOS and Home Manager user instead of assuming a fixed account.
sudo env "ATLAS_USER=${ATLAS_USER}" "ATLAS_HOME=${ATLAS_HOME}" \
  nixos-rebuild switch --impure --flake "${INSTALL_DIR}#atlas"

# Home Manager installs the wallpaper library during the rebuild. Use the
# installed scripts directly because the updated session PATH needs a new shell.
export ATLAS_PATH="${INSTALL_DIR}"
export PATH="${INSTALL_DIR}/bin:${PATH}"
theme-set nord

printf '\nAtlas is installed. Log out and back in to start the Hyprland session.\n'
