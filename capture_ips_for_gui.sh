#!/bin/bash

# declarations of MUST HAVE globals
PROGRAM_DIR="$(readlink -f ~/GIT/k8s)"
PROGRAM_NAME="$(basename "${BASH_SOURCE[0]}" | sed 's|.sh$||')"
WORKSPACE='/home/bobb/workspace'
LOGFILE="${WORKSPACE}/${PROGRAM_NAME}.log"

cd "${WORKSPACE}" ||:
mkdir -p current ||:
source "${PROGRAM_DIR}/k8s.bashlib"
{
  declare -i status
  (
    k8s::__init
    k8s::__separator k8s.capture_ips_for_gui

  ) && status=$? || status=$? 2>&1
  [ "$status" -eq 0 ] || echo "exit code ${status}"

} 2>&1 | tee "${LOGFILE}"

sed -i -E -e "${k8s_NO_ASCII}" "${LOGFILE}" > "${WORKSPACE}/current/${PROGRAM_NAME}.log"
rm "${LOGFILE}"
exit 0