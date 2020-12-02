#!/usr/bin/env bash

readonly _dir="$(cd "$(dirname "${0}")" && pwd)"

main() {
    cd ${_dir}/splunkforwarder/bin
    ./splunk status
}

main "$@"
