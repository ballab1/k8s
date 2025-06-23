#!/bin/bash
# get-k8s-certs-config.sh

#------------------------------------------------------------------------

declare -ir START_TIME="$(date '+%s')"

#shellcheck disable=SC1091
source "$(dirname "$0")/get_cert_info.bashlib"
trap get_cert_info::onExit EXIT
IFS=$'\n\t'

declare -r WORKDIR='/c/Downloads/work.certs/k8s'
cd "$WORKDIR" || exit

get_cert_info::get_k8s_certs_config
