#!/bin/bash

# declarations of MUST HAVE globals
PROGRAM_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
BASHLIB_DIR='/home/bobb/.bin/utilities/bashlib'

source "${PROGRAM_DIR}/k8s.bashlib"
k8s.__init

cd /home/bobb/workspace

k8s.capture_ips_for_gui