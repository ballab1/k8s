#!/bin/bash

# declarations of MUST HAVE globals
PROGRAM_DIR=~/GIT/k8s
PROGRAM_NAME="$(basename "${BASH_SOURCE[0]}" | sed 's|.sh$||')"
WORKSPACE='/home/bobb/workspace'
LOGFILE="${WORKSPACE}/current/${PROGRAM_NAME}.log"
cd "${WORKSPACE}" ||:
mkdir -p current ||:
source "${PROGRAM_DIR}/k8s.bashlib"
(
  {
    k8s.__init
    k8s.restore_postgres "$@"

  } 2>&1
) | tee "${LOGFILE}"

sed -i -E -e "${k8s_NO_ASCII}" "${LOGFILE}"
exit 0
