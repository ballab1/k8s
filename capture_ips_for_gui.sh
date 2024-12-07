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
#    k8s.separator k8s.reinit_nodes
#    k8s.separator k8s.add_nodes_to_cluster
#    k8s.separator k8s.set_config
#    k8s.separator k8s.enable_microk8s_modules
#    k8s.separator k8s.customize_content
#    k8s.separator k8s.add_new_content
#    k8s.separator k8s.generate_token
#    k8s.separator k8s.capture_config
#    k8s.separator k8s.update_jenkins
    k8s.separator k8s.capture_ips_for_gui
#    k8s.separator k8s.capture_status

  } 2>&1
) | tee "${LOGFILE}"

sed -i -E -e "${k8s_NO_ASCII}" "${LOGFILE}"
exit 0