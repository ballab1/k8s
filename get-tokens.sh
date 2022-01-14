#!/bin/bash

declare token_file='tokens.inf'

:> "$token_file"

for token in default-token admin-user ; do
    set -o verbose
    declare ref="$(microk8s kubectl -n kube-system get secret | grep "$token" | awk '{print $1}')"
    [ -z ${ref:-} ] || microk8s kubectl -n kube-system describe secret "$ref" | tee -a "$token_file"
done
