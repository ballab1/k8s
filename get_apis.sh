#!/bin/bash

START=$(date +%s)

# declarations of MUST HAVE globals
PROGRAM_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
BASHLIB_DIR='/home/bobb/.bin/utilities/bashlib'
PROGRAM_NAME="$(basename "${BASH_SOURCE[0]}" | sed 's|.sh$||')"
LOGFILE="$(pwd)/${PROGRAM_NAME}.log"

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

k8s.dump_apis
