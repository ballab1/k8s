#!/bin/bash

VERSION=1.23

# -----------------------------------------------------------------------------------
function add_nodes_to_cluster() {

    echo 'join nodes into cluster'
    local cmd
    for h in {6..8}; do
        cmd="$(sudo microk8s add-node | grep '10.3.1.14' | head -1)"
        echo "ssh s$h '$cmd'"
        run ssh "s$h" "sudo $cmd"
        run ssh "s$h" "microk8s status --wait-ready"
    done
    logElapsed "${FUNCNAME[0]}"
}

# -----------------------------------------------------------------------------------
function customize_content() {

    echo 'customizing content'
    run microk8s.kubectl apply -f ./production/corends.ConfigMap.yml
    run microk8s.kubectl apply -f ./production/nginx-ingress.DaemonSet.yml
    run microk8s.kubectl apply -f ./production/grafana.Deployment.yml
    run microk8s.kubectl apply -f ./production/grafana.Service.yml
    run microk8s.kubectl apply -f ./production/kubernetes-dashboard.Deployment.yml
    run microk8s.kubectl apply -f ./production/kubernetes-dashboard.Service.yml
    run microk8s.kubectl apply -f ./production/kubernetes-dashboard-ingress.Ingress.yml

    run microk8s.kubectl create -f ./production/local-hd.StorageClass.yml
    run microk8s.kubectl create -f ./production/s5-local.PersistentVolume.yml
    run microk8s.kubectl create -f ./production/s6-local.PersistentVolume.yml
    run microk8s.kubectl create -f ./production/s7-local.PersistentVolume.yml
    run microk8s.kubectl create -f ./production/s8-local.PersistentVolume.yml
#    run microk8s.kubectl create -f ./production/my-claim.persistentVolumeClaim.yml

    run microk8s.kubectl create -f ./production/jenkins.Namespace.yml
    run microk8s.kubectl create -f ./production/jenkins-root-ca.Secret.yml
    run microk8s.kubectl create -f ./production/jenkins-server-ca.Secret.yml
    logElapsed "${FUNCNAME[0]}"
}

# -----------------------------------------------------------------------------------
function capture_config() {

    echo 'capturing config content'
    microk8s config > kube.config
    cp kube.config /home/bobb/.kube/config
    microk8s.kubectl api-versions ||: > ./api-api-versions.txt
    microk8s.kubectl api-resources -o wide ||: > ./api-resources.txt
    logElapsed "${FUNCNAME[0]}"
}

# -----------------------------------------------------------------------------------
function capture_ips_for_gui() {

    echo 'capturing IPs for s3.ubuntu.home'
    microk8s.kubectl get services -A | awk '{if (substr($4,0,4) == '10.1') {sub(/\/[TCP|UDP].+$/,"",$6);sub(/:.*$/,"",$6); print "{|title|:|" $2 "|,|host|:|" $4 "|,|port|:|" $6 "|}" }}'|sed -e 's/|/"/g'|jq -s > services_ips.json
    scp services_ips.json s3:production/workspace.production/www/
    logElapsed "${FUNCNAME[0]}"
}

# -----------------------------------------------------------------------------------
function capture_status() {

    echo 'capturing status'
    sudo snap alias microk8s.kubectl kubectl 
    run microk8s.kubectl cluster-info
    run microk8s.kubectl get nodes
    run microk8s.kubectl get all -A

#    ./get_apis.sh &

    logElapsed "${FUNCNAME[0]}"
}

# -----------------------------------------------------------------------------------
function enable_micrk8s_modules() {

    echo 'enable microk8s modules'
    for module in dashboard dashboard-ingress dns fluentd ingress 'metallb:10.64.140.43-10.64.140.49' metrics-server prometheus storage; do
        run sudo microk8s enable "$module" ||:
    done
    run microk8s status --wait-ready
    run sudo iptables -P FORWARD ACCEPT
    logElapsed "${FUNCNAME[0]}"
}

# -----------------------------------------------------------------------------------
function generate_token() {

    echo 'generating tokens.inf'
    declare token_file='tokens.inf'
    :> "$token_file"
    for token in default-token admin-user ; do
        declare ref="$(microk8s.kubectl -n kube-system get secret | grep "$token" | awk '{print $1}')"
        [ -z "${ref:-}" ] && continue
        run microk8s.kubectl -n kube-system describe secret "$ref" | tee -a "$token_file"
        break
    done
    logElapsed "${FUNCNAME[0]}"
}

# -----------------------------------------------------------------------------------
function logElapsed() {

    [ "${DEBUG:-0}" -ne 0 ] || return
    local -r text="${1:-}"
    local current=$(timer.getTimestamp)

    {
        timer.logElapsed "$text" $((current - BEGIN)) 
        echo
        BEGIN="$current"
    } | tee -a elapsed.times.txt
}

# -----------------------------------------------------------------------------------
function main() {

    START=$(date +%s)
    BEGIN="$START"
    DEBUG=1
    :> elapsed.times.txt

    # Use the Unofficial Bash Strict Mode
    set -o errexit
    set -o nounset
    set -o pipefail
    IFS=$'\n\t'
    source /home/bobb/.bin/trap.bashlib
    source /home/bobb/.bin/utilities/bashlib/timer.bashlib
    trap.__init
    trap onexit EXIT

    sudo usermod -a -G microk8s "$USER"
    mkdir -p /home/bobb/.kube
    sudo chown -f -R "$USER" /home/bobb/.kube

    reinit_nodes
    add_nodes_to_cluster
    enable_micrk8s_modules
    customize_content
    generate_token
    capture_config
    capture_ips_for_gui
    capture_status
}

# -----------------------------------------------------------------------------------
function onexit() {

    find /tmp -maxdepth 1 -mindepth 1 -name 'ssh.s?.txt' -type f -delete
    for h in {5..8}; do
        ssh "s$h" "[ -e '$SCRIPT' ] && rm '$SCRIPT'"
    done

    local current=$(timer.getTimestamp)
    {
        timer.logElapsed 'Total Elapse time: ' $((current - START)) 
        echo
    } | tee -a elapsed.times.txt
}

# -----------------------------------------------------------------------------------
function onRemote() {
    cat << "EOF"
#!/bin/bash
function add_registries() {

    cat << "REGISTRY"
       [plugins."io.containerd.grpc.v1.cri".registry.mirrors."s2.ubuntu.home:5000"]
         endpoint = ["http://s2.ubuntu.home:5000"]
       [plugins."io.containerd.grpc.v1.cri".registry.mirrors."10.3.1.12:5000"]
        endpoint = ["http://10.3.1.12:5000"] 
REGISTRY
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
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
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function main() {

    START=$(date +%s)
    DEBUG=1

    local host="${1:?}"
    local version="${2:?}"
    echo "## ${host} ###########################################################################"

    # Use the Unofficial Bash Strict Mode
    set -o errexit
    set -o nounset
    set -o pipefail
    IFS=$'\n\t'
    source /home/bobb/.bin/trap.bashlib
    source /home/bobb/.bin/utilities/bashlib/timer.bashlib
    trap.__init
    trap onexit EXIT

    run snap remove microk8s
    run snap install microk8s --channel "${version}/stable" --classic

    run microk8s stop
    local SNAP='/var/snap/microk8s/current'
    echo 'add k8s.home to csr.conf.template'
    sed -i -e '/cluster.local/aDNS.6 = k8s.home' "${SNAP}/certs/csr.conf.template"

    if [ "$version" = '1.23' ]; then
        echo "create_registry_defs for ${version}"
        run create_registry_defs "$SNAP" "${version}"
    else
        echo "add_registries for ${version}"
        run add_registries "${version}" >> "${SNAP}/args/containerd-template.toml"
    fi
    run microk8s start
    run microk8s refresh-certs
    echo 'waiting for K8s to be ready'
    run microk8s status --wait-ready
    echo "## ${host} ##################################################################### END #"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function onexit() {

    [ "${DEBUG:-0}" -ne 0 ] || return

    local current=$(timer.getTimestamp)
    local -i elapsed=$((current - START)) 
        printf 'Elapsed time: %s\n' "$(timer.fmtElapsed $elapsed)" 
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
function run() {
  {
      echo
      printf '\e[90m%s\e[0m ' "$@"
      echo
  } >&2
  "$@"
}
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
EOF
    # start new HEREDOC with substitution
    cat << EOF
SCRIPT="\$0"
main "\$(hostname)" "$VERSION"
EOF
}

# -----------------------------------------------------------------------------------
function reinit_nodes() {

    SCRIPT="$(mktemp)"
    onRemote > "$SCRIPT"

    local -r script='/tmp/reinit'
#    echo "-- remote_script: $script --------------------------------------------------------"
#    cat "$SCRIPT"
#    echo "-- remote_script: $script -------------------------------------------------- EOF -"

    echo 'reinit each node'
    for h in {5..8}; do
      (
        run scp "$SCRIPT" "s$h:$script"
        ssh "s$h" "chmod 755 $script"
        run ssh "s$h" "sudo $script"
        ssh "s$h" "[ -e "$script" ] && rm $script"
      ) &> /tmp/ssh.s$h.txt &
    done

    echo '  wait for all reinit commands to complete'
    while true; do
        wait
        [ "$(jobs)" ] || break
    done

    echo '  output log of each reinit'
    for h in {5..8}; do
        cat /tmp/ssh.s$h.txt
        rm /tmp/ssh.s$h.txt
    done
    rm "$SCRIPT"
    logElapsed "${FUNCNAME[0]}"
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
