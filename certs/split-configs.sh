#!/usr/bin/bash
# split_config.sh

#------------------------------------------------------------------------------------


declare -ir START_TIME="$(date '+%s')"

#shellcheck disable=SC1091
source "$(dirname "$0")/get_cert_info.bashlib"
trap get_cert_info::onExit EXIT
IFS=$'\n\t'

declare -r WORKDIR='/c/Downloads/work.certs/k8s/config.map.home-1'
cd "$WORKDIR" || exit

declare k8s_type k8s_data_json
for k8s_type in 'configMap' 'secret'; do
    k8s_data_json="all.${k8s_type}.json"
    get_cert_info::extract_k8sdata "$k8s_data_json"
done
