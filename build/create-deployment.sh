#!/usr/bin/env bash

set -o pipefail
set -o nounset

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"
readonly _create_dev_env="${1:-false}"
source "${_dir}"/conf-variables.sh

copy_content() {
    cd "${_dir}"/"${_PROJECT_NAME}"
    cp -r "${_dir}"/../deploy "${_dir}"/"${_PROJECT_NAME}"
}

create_content() {
    cd "${_dir}"/"${_PROJECT_NAME}"
    tar -xvzf "${_dir}"/"${_PROJECT_NAME}"/deploy/splunkforwarder-*.tgz -C "${_dir}"/"${_PROJECT_NAME}"/deploy
}

remove_project_specific_files() {
    cd "${_dir}"/"${_PROJECT_NAME}"
    rm -rf "${_dir}"/"${_PROJECT_NAME}"/deploy/splunkforwarder-*.tgz 2> /dev/null
}

delete_content() {
    cd "${_dir}"/"${_PROJECT_NAME}"
    rm -rf ..?* .[!.]*
    rm ./README.md 2>/dev/null
    rm -r ./test ./logs ./docs 2>/dev/null
    remove_project_specific_files
}

create_deployment() {
    sudo rm -rf "${_dir}"/"${_PROJECT_NAME}" "${_dir}"/"${_DEPLOYMENT_NAME}" "${_dir}"/*.tar.gz
    mkdir "${_dir}"/"${_PROJECT_NAME}"
    copy_content
    create_content
    delete_content
    mv "${_dir}"/"${_PROJECT_NAME}" "${_dir}"/"${_DEPLOYMENT_NAME}"
    cd "${_dir}"
    tar -zcf "${_DEPLOYMENT_NAME}-${_DEPLOYMENT_VERSION}".tar.gz "${_DEPLOYMENT_NAME}"
    rm -rf "${_dir}"/"${_DEPLOYMENT_NAME}"
}

main() {
    cd "${_dir}"/..
    git status --porcelain | grep -q '^' &&
        echo "You have files that is not commited, check your git status!" || {
        echo "$(git status)" | grep -qw "Your branch is up to date with 'origin/master'." && {
            create_deployment
        } || echo "Code is not up to-date, check your git status!" 
    }
}

main "$@"
