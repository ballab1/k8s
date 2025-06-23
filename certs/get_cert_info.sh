#!/usr/bin/bash
# get_cert_info.sh

#------------------------------------------------------------------------------------


declare -ir START_TIME="$(date '+%s')"

#shellcheck disable=SC1091
source "$(dirname "$0")/get_cert_info.bashlib"
trap get_cert_info::onExit EXIT
IFS=$'\n\t'

get_cert_info::main
