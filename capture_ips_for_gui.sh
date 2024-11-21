#!/bin/bash

# declarations of MUST HAVE globals
PROGRAM_DIR=~/GIT/k8s
PROGRAM_NAME="$(basename "${BASH_SOURCE[0]}" | sed 's|.sh$||')"
LOGFILE="$(pwd)/${PROGRAM_NAME}.log"
(
  {
    source "${PROGRAM_DIR}/k8s.bashlib"
    k8s.__init
    cd /home/bobb/workspace

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
    jq -r '[.[]|"  \(.title): \(.host):\(.port)"]|sort[]' current/services_ips.json
#    k8s.separator k8s.capture_status

  } 2>&1
) | tee "${LOGFILE}"

sed -i -E -e 's/\x1b\[[0-9;]*m//g' "${LOGFILE}"
exit 0