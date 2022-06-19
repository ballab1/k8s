#!/bin/bash

# declarations of MUST HAVE globals
PROGRAM_DIR=~/GIT/k8s
PROGRAM_NAME="$(basename "${BASH_SOURCE[0]}" | sed 's|.sh$||')"
LOGFILE="$(pwd)/${PROGRAM_NAME}.log"
{
  declare -i status
  (
    source "${PROGRAM_DIR}/k8s.bashlib"
    k8s.__init
    cd /home/bobb/workspace

    k8s.dump_apis

  ) && status=$? || status=$? 2>&1
  [ "$status" -eq 0 ] || echo "exit code ${status}"

} | tee "${LOGFILE}"

sed -i -E -e 's/\x1b\[[0-9;]*m//g' "${LOGFILE}"
exit 0