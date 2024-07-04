#!/usr/bin/env bash

set -eu -o pipefail

if [ "$(id -u)" -ne 0 ]; then
	echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
	exit 1
fi

add_global_run_command() {
	local command=$1

	if [ -f "/etc/os-release" ] && grep "ID_LIKE=.*alpine.*\|ID=.*alpine.*" /etc/os-release; then
		if [ -f "/etc/profile" ] && [[ "$(cat /etc/profile)" != *"${command}"* ]]; then
			echo "Add ${command} to /etc/profile"
			echo -e "${command}" >>/etc/profile
		fi
	fi

	if [ -f "/etc/bash.bashrc" ] && [[ "$(cat /etc/bash.bashrc)" != *"${command}"* ]]; then
			echo "Add ${command} to /etc/bash.bashrc"
		echo -e "${command}" >>/etc/bash.bashrc
	fi

	if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh/zshrc)" != *"${command}"* ]]; then
		echo "Add ${command} to /etc/zsh/zshrc"
		echo -e "${command}" >>/etc/zsh/zshrc
	fi
}

install_aqua_binary() {
	local aquq_root_dir=$1
	local aqua_installer_version=$2
	local aqua_version=$3

	mkdir -p "${aquq_root_dir}"

	local aqua_installer_ref='main'
	if [ -n "${aqua_installer_version}" ] && [ "${aqua_installer_version}" != 'latest' ]; then
		aqua_installer_ref="v${aqua_installer_version##v}"
	fi
	local aqua_installer_url="https://raw.githubusercontent.com/aquaproj/aqua-installer/${aqua_installer_ref}/aqua-installer"

	local command="curl -fsSL \"${aqua_installer_url}\" | AQUA_ROOT_DIR=\"${aquq_root_dir}\" bash -s --"
	if [ -n "${aqua_version}" ] && [ "${aqua_version}" != 'latest' ]; then
		command="${command} -v v${aqua_version##v}"
	fi

	bash -c "${command}"
}

make_aqua_user_writable() {
	local aquq_root_dir=$1
	local aqua_user_name=$2

	groupadd aqua
	gpasswd -a "${aqua_user_name}" aqua
	chgrp -R aqua "${aquq_root_dir}"
	chmod -R g+rws "${aquq_root_dir}"
}

add_aqua_environment_variables() {
	local aquq_root_dir=$1

	add_global_run_command "export AQUA_ROOT_DIR=\"${aquq_root_dir}\""
	add_global_run_command "if [[ \"\${PATH}\" != *\"\${AQUA_ROOT_DIR}/bin\"* ]]; then export PATH=\"\${PATH}:\${AQUA_ROOT_DIR}/bin\"; fi"
}

install() {
	local aqua_root_dir=$1
	local aqua_installer_version=$2
	local aqua_version=$3
	local aqua_user_name=$4

	install_aqua_binary "${aqua_root_dir}" "${aqua_installer_version}" "${aqua_version}"
	make_aqua_user_writable "${aqua_root_dir}" "${aqua_user_name}"
	add_aqua_environment_variables "${aqua_root_dir}"
}

install "${AQUAROOTDIR:-/usr/local/share/aquaproj-aqua}" "${INSTALLERVERSION:-latest}" "${VERSION:-latest}" "${_REMOTE_USER:-root}"

echo "Done!"
