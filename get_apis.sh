#!/bin/bash

function main() {

    set -o errexit
    set -o nounset
    set -o pipefail
    IFS=\$'\n\t'
    source /home/bobb/.bin/trap.bashlib
    trap.__init 


    local mode object
    local -a modes=('wide' 'json' 'yaml')

    mkdir -p apis
    rm -rf apis/*
    for mode in "${modes[@]}"; do
        mkdir -p "apis/$mode"
    done

    while read -r object; do
        echo "  $object"
        for mode in "${modes[@]}"; do
            declare ext="$mode"
            [ "$mode" = 'wide' ] && ext='txt'
            microk8s kubectl get "$object" -A -o "$mode" &> "apis/${mode}/${object}.$ext" ||:
        done
    done < <(microk8s.kubectl api-resources --no-headers=false -o=name --sort-by=name)
}

main "$@"
