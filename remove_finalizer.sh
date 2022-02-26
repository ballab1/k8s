#!/bin/bash

if [ -z "${1:-}" ] ; then
  echo -e "\nUsage: ${0} <name_of_the_namespace_to_remove_the_finalizer_from>\n"
  echo "Valid cluster names, based on your kube config:"
  microk8s.kubectl config view -o jsonpath='{"Cluster name\tServer\n"}{range .clusters[*]}{.name}{"\t"}{.cluster.server}{"\n"}{end}'
  exit 1
fi

microk8s.kubectl proxy --port=8901 &
PID=$!
sleep 1

echo -n 'Current context : '
microk8s.kubectl config current-context 
read -p "Are you sure you want to remove the finalizer from namespace ${1}? Press Ctrl+C to abort."

microk8s.kubectl get namespace "${1}" -o json \
            | jq '.spec.finalizers = [ ]' \
            | curl -k \
                   -H "Content-Type: application/json" \
                   -X PUT --data-binary @- "http://localhost:8901/api/v1/namespaces/${1}/finalize"

kill -15 $PID

