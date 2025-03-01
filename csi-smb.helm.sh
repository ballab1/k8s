#!/bin/bash -x

NAMESPACE='smb-csi'
HELM_VALUES='csi-smb.helm.yaml'
RELEASE_VERIONS='v1.17.0'
RELEASE_NAME='csi-driver-smb'
CHART_NAME='csi-driver-smb/csi-driver-smb'

if [ "${1:-install}" != 'install' ]; then
  microk8s.kubectl  delete -f ~/GIT/k8s/apps/recipes
  microk8s.kubectl  delete -f ~/GIT/k8s/apps/stormshot
  microk8s.kubectl  delete -f ~/GIT/k8s/apps/versions
  microk8s.kubectl  delete -f ~/GIT/k8s/apps/web
  microk8s.kubectl  delete -f ~/GIT/k8s/production/pv-smb-volumes
  helm uninstall -n "$NAMESPACE" "$RELEASE_NAME"
  microk8s.kubectl  delete namespace "$NAMESPACE"

else

  microk8s.kubectl  create namespace "$NAMESPACE"
  helm install -n "$NAMESPACE" -f "$HELM_VALUES" --version "$RELEASE_VERIONS" "$RELEASE_NAME" "$CHART_NAME"
  microk8s.kubectl  create -f ~/GIT/k8s/production/pv-smb-volumes
  microk8s.kubectl  create -f ~/GIT/k8s/apps/recipes
  microk8s.kubectl  create -f ~/GIT/k8s/apps/stormshot
  microk8s.kubectl  create -f ~/GIT/k8s/apps/versions
  microk8s.kubectl  create -f ~/GIT/k8s/apps/web

fi