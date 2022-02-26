#!/bin/bash

# -----------------------------------------------------------------------------------
function main() {

    :> elapsed.times.txt

    sudo usermod -a -G microk8s "$USER"
    mkdir -p /home/bobb/.kube
    sudo chown -f -R "$USER" /home/bobb/.kube

    k8s.reinit_nodes
    k8s.add_nodes_to_cluster
    k8s.enable_micrk8s_modules
    k8s.customize_content
    k8s.generate_token
    k8s.capture_config
    k8s.capture_ips_for_gui
    k8s.capture_status
}

# -----------------------------------------------------------------------------------

START=$(date +%s)

# declarations of MUST HAVE globals
PROGRAM_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
BASHLIB_DIR='/home/bobb/.bin/utilities/bashlib'
PROGRAM_NAME="$(basename "${BASH_SOURCE[0]}" | sed 's|.sh$||')"
LOGFILE="$(pwd)/${PROGRAM_NAME}.log"

DEBUG=1
LASTTIME="$START"
VERSION=1.23

# Use the Unofficial Bash Strict Mode
set -o errexit
set -o nounset
set -o pipefail
IFS=$'\n\t'
source "${BASHLIB_DIR}/trap.bashlib"
source "${BASHLIB_DIR}/timer.bashlib"
source "${PROGRAM_DIR}/k8s.bashlib"
trap.__init
trap k8s.onexit EXIT



cd /home/bobb/workspace
main "$@" | tee "${LOGFILE}"
