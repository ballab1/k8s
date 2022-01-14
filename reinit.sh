#!/bin/bash

VERSION=1.23

# -----------------------------------------------------------------------------------
function onRemote() {
    cat << "EOF"
#!/bin/bash
echo "## $(hostname -f) ####################################################################"

function add_registries() {

    cat << "REGISTRY"
       [plugins."io.containerd.grpc.v1.cri".registry.mirrors."s2.ubuntu.home:5000"]
         endpoint = ["http://s2.ubuntu.home:5000"]
       [plugins."io.containerd.grpc.v1.cri".registry.mirrors."10.3.1.12:5000"]
        endpoint = ["http://10.3.1.12:5000"] 
REGISTRY
}
# -----------------------------------------------------------------------------------
function create_registry_defs() {

    local SNAP_DATA="${1:-/etc/containerd/config.toml}"
    local version="${2:-}"
    local config_path="${SNAP_DATA}/args/certs.d"

    for reg in "http://s2.ubuntu.home:5000" "http://10.3.1.12:5000"; do
        local host="${reg#*//}"
        run mkdir -p "${config_path}/$host"
        cat << REGISTRY > "${config_path}/${host}/hosts.toml"
server = "$reg"

[host."$reg"]
  capabilities = ["pull", "resolve"]
REGISTRY
    done
}
# -----------------------------------------------------------------------------------
function run() {
  {
      echo
      printf '\e[90m%s\e[0m ' "$@"
      echo
  } >&2
  "$@"
}

# -----------------------------------------------------------------------------------
EOF
    # start new HEREDOC with substitution
    cat << EOF

# Use the Unofficial Bash Strict Mode
set -o errexit
set -o nounset
set -o pipefail
IFS=\$'\n\t'
source /home/bobb/.bin/trap.bashlib
trap.__init

run snap remove microk8s
run snap install microk8s --channel "${VERSION}/stable" --classic

run microk8s stop
declare SNAP='/var/snap/microk8s/current'
echo 'add k8s.home to csr.conf.template'
sed -i -e '/cluster.local/aDNS.6 = k8s.home' "\${SNAP}/certs/csr.conf.template"

if [ "$VERSION" = '1.23' ]; then
    echo "create_registry_defs for ${VERSION}"
    run create_registry_defs "\$SNAP" "${VERSION}"
else
    echo "add_registries for ${VERSION}"
    run add_registries "${VERSION}" >> "\${SNAP}/args/containerd-template.toml"
fi
run microk8s start
echo 'waiting for K8s to be ready'
run microk8s status --wait-ready
echo "## $(hostname -f) ############################################################## END #"
EOF
}

# -----------------------------------------------------------------------------------
function main() {

    # Use the Unofficial Bash Strict Mode
    set -o errexit
    set -o nounset
    set -o pipefail
    IFS=$'\n\t'
    source /home/bobb/.bin/trap.bashlib
    trap.__init

    sudo usermod -a -G microk8s "$USER"
    mkdir -p /home/bobb/.kube
    sudo chown -f -R "$USER" /home/bobb/.kube

    local -r script='/tmp/reinit'
    local -r tmp_script="$(mktemp)"
    onRemote > "$tmp_script"
    echo '-- remote_script: /tmp/reinit --------------------------------------------------------'
    cat "$tmp_script"
    echo '-- remote_script: /tmp/reinit -------------------------------------------------- EOF -'

    for h in {5..8}; do
        run scp "$tmp_script" "s$h:$script"
        ssh "s$h" "chmod 755 $script"
        run ssh "s$h" "sudo $script"
        ssh "s$h" "rm $script"
    done
    rm "$tmp_script"

    local cmd
    for h in 6 7 8; do
        cmd="$(sudo microk8s add-node | grep '10.3.1.14' | head -1)"
        echo "ssh s$h '$cmd'"
        run ssh "s$h" "sudo $cmd"
        run ssh "s$h" "microk8s status --wait-ready"
    done

    for module in dashboard dashboard-ingress dns fluentd ingress 'metallb:10.64.140.43-10.64.140.49' metrics-server prometheus storage; do
        run sudo microk8s enable "$module" ||:
    done
    run microk8s status --wait-ready
    run sudo iptables -P FORWARD ACCEPT

    echo 'creating custom content'
    run microk8s.kubectl apply -f ./production/nginx-ingress.yml
    run microk8s.kubectl apply -f ./production/corends.yml
    run microk8s.kubectl apply -f ./production/grafana.yml
    run microk8s.kubectl apply -f ./production/dashboard.yml

    run microk8s.kubectl create -f ./production/local-hd-storage.yml
    run microk8s.kubectl create -f ./production/s5-local-hd.yml
    run microk8s.kubectl create -f ./production/s6-local-hd.yml
    run microk8s.kubectl create -f ./production/s7-local-hd.yml
    run microk8s.kubectl create -f ./production/s8-local-hd.yml
#    run microk8s.kubectl create -f ./production/persistentVolumeClaim.yml

    run microk8s.kubectl create -f ./production/jenkins-ns.yml
    run microk8s.kubectl create -f ./production/jenkins-root-ca.yml
    run microk8s.kubectl create -f ./production/jenkins-server-ca.yml

    microk8s config > kube.config
    cp kube.config /home/bobb/.kube/config
    microk8s.kubectl api-resources -wide > ./api-resources.txt
    microk8s api-versions > ./api-api-versions.txt
    echo

    declare token_file='tokens.inf'
    :> "$token_file"
    for token in default-token admin-user ; do
        declare ref="$(microk8s.kubectl -n kube-system get secret | grep "$token" | awk '{print $1}')"
        [ -z "${ref:-}" ] && continue
        run microk8s.kubectl -n kube-system describe secret "$ref" | tee -a "$token_file"
        break
    done

    microk8s.kubectl get services -A | awk '{if (substr($4,0,4) == '10.1') {sub(/\/[TCP|UDP].+$/,"",$6);sub(/:.*$/,"",$6); print "{|title|:|" $2 "|,|param|:|" $4 ":" $6 "|}" }}'|sed -e 's/|/"/g'|jq -s > services_ips.json
    scp services_ips.json s3:production/workspace.production/www/
    run ./get_apis.sh

    sudo snap alias microk8s.kubectl kubectl 
    run microk8s.kubectl cluster-info
    run microk8s.kubectl get nodes
    run microk8s.kubectl get all -A
}
# -----------------------------------------------------------------------------------
function run() {
  {
      echo
      printf '\e[90m%s\e[0m ' "$@"
      echo
  } >&2
  "$@"
}
# -----------------------------------------------------------------------------------

cd /home/bobb/workspace
main "$@" | tee ./update.log
