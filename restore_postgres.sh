#!/bin/bash

# declarations of MUST HAVE globals
PROGRAM_DIR=~/GIT/k8s
PROGRAM_NAME="$(basename "${BASH_SOURCE[0]}" | sed 's|.sh$||')"
WORKSPACE='/home/bobb/workspace'
LOGFILE="${WORKSPACE}/current/${PROGRAM_NAME}.log"
SQL_FILE='2024-12-29.postgres.sql'

cd "${WORKSPACE}" ||:
mkdir -p current ||:
source "${PROGRAM_DIR}/k8s.bashlib"
(
  {
    k8s.__init
    k8s.restore_hostpath "$@"

  } 2>&1
) | tee "${LOGFILE}"

sed -i -E -e "${k8s_NO_ASCII}" "${LOGFILE}"
exit 0
