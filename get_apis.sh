#!/bin/bash

# declarations of MUST HAVE globals
PROGRAM_DIR='/home/bobb/GIT/k8s'
BASHLIB_DIR='/home/bobb/.bin/utilities/bashlib'

source "${PROGRAM_DIR}/k8s.bashlib"
k8s.__init

cd /home/bobb/workspace

k8s.dump_apis
