#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
readonly _home_folder="$(cd "${_dir}/.." && pwd)"

readonly _enable_pa_forward="${FP_ENABLE_PA_FORWARD:-false}"
readonly _sourcetype_pa="${FP_SOURCETYPE_PA:-"private-access"}"
readonly _sourcetype_pa_monitor_type="${FP_SOURCETYPE_PA_MONITOR_TYPE:-"directory"}"
readonly _sourcetype_pa_monitor_value="${FP_SOURCETYPE_PA_MONITOR_VALUE:-"/forcepoint-logs/pa"}"
readonly _sourcetype_pa_monitor_server_value="${FP_SOURCETYPE_PA_MONITOR_SERVER_VALUE:-""}"

readonly _enable_csg_forward="${FP_ENABLE_CSG_FORWARD:-false}"
readonly _sourcetype_csg="${FP_SOURCETYPE_CSG:-"cloud-security-gateway"}"
readonly _sourcetype_csg_monitor_type="${FP_SOURCETYPE_CSG_MONITOR_TYPE:-"directory"}"
readonly _sourcetype_csg_monitor_value="${FP_SOURCETYPE_CSG_MONITOR_VALUE:-"/forcepoint-logs/csg"}"
readonly _sourcetype_csg_monitor_server_value="${FP_SOURCETYPE_CSG_MONITOR_SERVER_VALUE:-""}"

readonly _enable_ngfw_forward="${FP_ENABLE_NGFW_FORWARD:-false}"
readonly _sourcetype_ngfw="${FP_SOURCETYPE_NGFW:-"next-generation-firewall"}"
readonly _sourcetype_ngfw_monitor_type="${FP_SOURCETYPE_NGFW_MONITOR_TYPE:-"tcp"}"
readonly _sourcetype_ngfw_monitor_value="${FP_SOURCETYPE_NGFW_MONITOR_VALUE:-8180}"
readonly _sourcetype_ngfw_monitor_server_value="${FP_SOURCETYPE_NGFW_MONITOR_SERVER_VALUE:-""}"

readonly _BOLD_WHITE='\033[1;37m'
readonly _NO_COLOR='\033[0m'

validate_prerequisites() {
  local __r=0
  local __prerequisites=("$@")
  local __clear_previous_display="\r\033[K"
  for prerequisite in "${__prerequisites[@]}"; do
    echo -en "${__clear_previous_display}Prerequisite - ${prerequisite} - check" && sleep 0.1
    command -v ${prerequisite} >/dev/null 2>&1 || {
      error "${__clear_previous_display}We require >>> ${prerequisite} <<< but it's not installed. Please try again after installing ${prerequisite}." &&
        __r=1 &&
        break
    }
  done
  echo -en "${__clear_previous_display}"
  return "${__r}"
}

info() {
    local -r __msg="${1}"
    local -r __nobreakline="${2:-""}"
    test ! -z "${__nobreakline}" &&
        printf "${_BOLD_WHITE}${__msg}${_NO_COLOR}" ||
        printf "${_BOLD_WHITE}${__msg}${_NO_COLOR}\n"
}

setup_receiving_host() {
    local -r __config_file="${1}"
    info "Enter Splunk indexer IP address e.g. 11.22.33.44: " "nobreakline"
    read __user_input_1
    info "Enter Splunk indexer receiving port number e.g. 9997: " "nobreakline"
    read __user_input_2
    cat <<EOF >"${__config_file}"
[indexAndForward]
index = false

[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = ${__user_input_1}:${__user_input_2}

[tcpout-server://${__user_input_1}:${__user_input_2}]
EOF

    return $?
}

get_listener_string() {
  local -r __input_monitor_type="${1}"
  local -r __input_monitor_value="${2}"
  local -r __input_monitor_server_value="${3}"
  
  local __output=""

  if test -z "$__input_monitor_server_value"; then
        __output="["${__input_monitor_type}"://"${__input_monitor_value}"]"
  else
        __output="["${__input_monitor_type}"://"${__input_monitor_server_value}":"${__input_monitor_value}"]"
  fi
        
  echo "${__output}"
}

get_monitor_string() {
  local -r __input_monitor_type="${1}"
  local -r __input_monitor_value="${2}"
  local -r __input_monitor_server_value="${3}"

  local __output=""
  case "${__input_monitor_type}" in
    "directory")
        __output="[monitor://"${__input_monitor_value}"]"
        ;;
    "tcp"|"udp")
        __output=$(get_listener_string "${__input_monitor_type}" "${__input_monitor_value}" "${__input_monitor_server_value}")
        ;;
    *) echo ""
        ;;
  esac
  echo "${__output}"
}

setup_splunk_props() {
    local -r __config_file="${1}"
    cat /dev/null > "${__config_file}"
    if test "${_enable_pa_forward}" = true; then  
        local __monitor_string_pa=$(get_monitor_string "${_sourcetype_pa_monitor_type}" "${_sourcetype_pa_monitor_value}" "${_sourcetype_pa_monitor_server_value}")
        [ -z "${__monitor_string_pa}" ] && echo "Invalid Options - "${_sourcetype_pa_monitor_type}" "${_sourcetype_pa_monitor_value}" "${_sourcetype_pa_monitor_server_value}"" || cat <<EOF >>"${__config_file}"
${__monitor_string_pa}
disabled = false
index = forcepoint
sourcetype = ${_sourcetype_pa}

EOF
    fi

    if test "${_enable_csg_forward}" = true; then
        local -r __monitor_string_csg=$(get_monitor_string "${_sourcetype_csg_monitor_type}" "${_sourcetype_csg_monitor_value}" "${_sourcetype_csg_monitor_server_value}")
        [ -z "${__monitor_string_csg}" ] && echo "Invalid Options - "${_sourcetype_csg_monitor_type}" "${_sourcetype_csg_monitor_value}" "${_sourcetype_csg_monitor_server_value}"" || cat <<EOF >>"${__config_file}"
${__monitor_string_csg}
disabled = false
index = forcepoint
sourcetype = ${_sourcetype_csg}

EOF
    fi

    if test "${_enable_ngfw_forward}" = true; then
        local -r __monitor_string_ngfw=$(get_monitor_string "${_sourcetype_ngfw_monitor_type}" "${_sourcetype_ngfw_monitor_value}" "${_sourcetype_ngfw_monitor_server_value}")
        [ -z "${__monitor_string_ngfw}" ] && echo "Invalid Options - "${_sourcetype_ngfw_monitor_type}" "${_sourcetype_ngfw_monitor_value}" "${_sourcetype_ngfw_monitor_server_value}"" || cat <<EOF >>"${__config_file}"
${__monitor_string_ngfw}
disabled = false
index = forcepoint
sourcetype = ${_sourcetype_ngfw}

EOF
    fi

    return $?
}

setup_forwarder_props() {
    local -r __config_file="${1}"
    cat <<EOF >"${__config_file}"
[cloud-security-gateway]
SHOULD_LINEMERGE=false
LINE_BREAKER=([\r\n]+)
NO_BINARY_CHECK=true
CHARSET=UTF-8
INDEXED_EXTRACTIONS=CSV
KV_MODE=none
category=Custom
description=Forcepoint Cloud Security Gateway Logs
disabled=false
pulldown_type=true
EOF

    return $?
}

main() {
    local __prerequisites=(printf)
    local -r __user="$(whoami)"
    sudo chown -R "${__user}": "${_home_folder}"
    validate_prerequisites "${__prerequisites[@]}"
    setup_receiving_host "${_home_folder}/outputs.conf"
    setup_splunk_props "${_home_folder}/inputs.conf"
    setup_forwarder_props "${_home_folder}/props.conf"
}

main "$@"
