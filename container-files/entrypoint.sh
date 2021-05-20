#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

readonly _splunk_indexer_ip_address="${SPLUNK_INDEXER_IP_ADDRESS}"
readonly _splunk_indexer_receiving_port="${SPLUNK_INDEXER_RECEIVING_PORT:-9997}"

readonly _enable_pa_forward="${FP_ENABLE_PA_FORWARD:-false}"
readonly _sourcetype_pa="${FP_SOURCETYPE_PA:-"private-access"}"
readonly _sourcetype_pa_monitor_type="${FP_SOURCETYPE_PA_MONITOR_TYPE:-"directory"}"
readonly _sourcetype_pa_monitor_value="${FP_SOURCETYPE_PA_MONITOR_VALUE:-"/app/forcepoint-logs/pa"}"
readonly _sourcetype_pa_monitor_server_value="${FP_SOURCETYPE_PA_MONITOR_SERVER_VALUE:-""}"

readonly _enable_csg_forward="${FP_ENABLE_CSG_FORWARD:-false}"
readonly _sourcetype_csg="${FP_SOURCETYPE_CSG:-"cloud-security-gateway"}"
readonly _sourcetype_csg_monitor_type="${FP_SOURCETYPE_CSG_MONITOR_TYPE:-"directory"}"
readonly _sourcetype_csg_monitor_value="${FP_SOURCETYPE_CSG_MONITOR_VALUE:-"/app/forcepoint-logs/csg"}"
readonly _sourcetype_csg_monitor_server_value="${FP_SOURCETYPE_CSG_MONITOR_SERVER_VALUE:-""}"

readonly _enable_ngfw_forward="${FP_ENABLE_NGFW_FORWARD:-false}"
readonly _sourcetype_ngfw="${FP_SOURCETYPE_NGFW:-"next-generation-firewall"}"
readonly _sourcetype_ngfw_monitor_type="${FP_SOURCETYPE_NGFW_MONITOR_TYPE:-"tcp"}"
readonly _sourcetype_ngfw_monitor_value="${FP_SOURCETYPE_NGFW_MONITOR_VALUE:-8180}"
readonly _sourcetype_ngfw_monitor_server_value="${FP_SOURCETYPE_NGFW_MONITOR_SERVER_VALUE:-""}"

readonly _enable_casb_forward="${FP_ENABLE_CASB_FORWARD:-false}"
readonly _sourcetype_casb="${FP_SOURCETYPE_CASB:-"cloud-access-security-broker"}"
readonly _sourcetype_casb_monitor_type="${FP_SOURCETYPE_CASB_MONITOR_TYPE:-"directory"}"
readonly _sourcetype_casb_monitor_value="${FP_SOURCETYPE_CASB_MONITOR_VALUE:-"/app/forcepoint-logs/casb"}"
readonly _sourcetype_casb_monitor_server_value="${FP_SOURCETYPE_CASB_MONITOR_SERVER_VALUE:-""}"

setup_receiving_host() {
    local -r __config_file="${1}"
    cat <<EOF >"${__config_file}"
[indexAndForward]
index = false

[tcpout]
defaultGroup = default-autolb-group

[tcpout:default-autolb-group]
server = ${_splunk_indexer_ip_address}:${_splunk_indexer_receiving_port}

[tcpout-server://${_splunk_indexer_ip_address}:${_splunk_indexer_receiving_port}]
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
        local -r __monitor_string_pa=$(get_monitor_string "${_sourcetype_pa_monitor_type}" "${_sourcetype_pa_monitor_value}" "${_sourcetype_pa_monitor_server_value}")
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

    if test "${_enable_casb_forward}" = true; then
        local -r __monitor_string_casb=$(get_monitor_string "${_sourcetype_casb_monitor_type}" "${_sourcetype_casb_monitor_value}" "${_sourcetype_casb_monitor_server_value}")
        [ -z "${__monitor_string_casb}" ] && echo "Invalid Options - "${_sourcetype_casb_monitor_type}" "${_sourcetype_casb_monitor_value}" "${_sourcetype_casb_monitor_server_value}"" || cat <<EOF >>"${__config_file}"
${__monitor_string_casb}
disabled = false
index = forcepoint
sourcetype = ${_sourcetype_casb}
blacklist = \.txt$

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
    mkdir -p /opt/splunkforwarder/etc/apps/search/local /opt/splunkforwarder/etc/system/local
    setup_receiving_host "/opt/splunkforwarder/etc/system/local/outputs.conf"
    setup_splunk_props "/opt/splunkforwarder/etc/apps/search/local/inputs.conf"
    setup_forwarder_props "/opt/splunkforwarder/etc/system/local/props.conf"
    /sbin/entrypoint.sh start-service
}

main "$@"

