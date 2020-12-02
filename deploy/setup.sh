#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
readonly _home_folder="$(cd "${_dir}/.." && pwd)"

main() {
    cd "${_dir}"
    local -r __user="$(whoami)"
    sudo chown -R "${__user}": "${_home_folder}"
    sudo chmod +x "${_dir}"/*.sh
    sudo mkdir -p /forcepoint-logs/pa /forcepoint-logs/csg "${_dir}"/splunkforwarder/etc/apps/search/local
    sudo chown -R "${__user}": /forcepoint-logs
    sudo cp -f "${_home_folder}"/inputs.conf "${_dir}"/splunkforwarder/etc/apps/search/local/inputs.conf 
    cp -f "${_home_folder}"/outputs.conf "${_dir}"/splunkforwarder/etc/system/local/outputs.conf
    cp -f "${_home_folder}"/props.conf "${_dir}"/splunkforwarder/etc/system/local/props.conf
    cd ${_dir}/splunkforwarder/bin
    ./splunk start --accept-license --answer-yes
    sudo ./splunk enable boot-start -user "${__user}"
    ./splunk restart
}

main "$@"
