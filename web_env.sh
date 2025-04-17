#!/bin/bash

declare -r MAX_ITER=20
declare -r GREEN='\x1b[32m'
declare -r GREY='\x1b[90m'
declare -r RED='\x1b[31m'
declare -r BLUE='\x1b[94m'
declare -r WHITE='\x1b[33m'
declare -r RESET='\x1b[0m'

declare -r KUBECTL='/snap/bin/kubectl'
declare -r NAMESPACE='web'
declare -i count=0
declare lastlog=''
declare color="${WHITE}"

function log() {
  local line="${1:?}"
  if [ "${line}" != "${lastlog}" ]; then
    echo
    echo -en "$line "
    color="${line# ... *}"
    color="${color:0:8}"
    lastlog="$line"
  else
    echo -en "${color}.${RESET}"
  fi
}


# copy latest content to Node working dir
declare pod
if [ "$("$KUBECTL" get -n "$NAMESPACE" -o json pods | jq 'length')" -eq 0 ]; then
  log "${GREY}scp -r ~/GIT/app/* s7:/tmp/pv-web/${RESET}"
  scp -r ~/GIT/app/* s7:/tmp/pv-web/
else
  pod="$("$KUBECTL" get -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' pods)"
  log "${GREY}kc cp ~/GIT/app ${NAMESPACE}/${pod}:/usr/src${RESET}"
  "$KUBECTL" cp ~/GIT/app "${NAMESPACE}/${pod}:/usr/src"
fi

while true; do

  if [ "$("$KUBECTL" get -n "$NAMESPACE" -o jsonpath='{range .items[*]}{.metadata.name}{":"}{.status.phase}{"\n"}{end}' pods | wc -l)" -eq 1 ]; then
    # restart deployment if there is only a single pod
    if [ "$("$KUBECTL" get -n "$NAMESPACE" -o jsonpath='{.items[0].status.phase}' pods)" = 'Running' ]; then
      log "${BLUE}restarting deployment${RESET}\\n"
      "$KUBECTL" rollout restart -n "$NAMESPACE" deployment/web
      sleep 5
      continue
    fi
  fi

  # wait until there is only a single pod
  while [ "$($KUBECTL get -n web pods -o json | jq '.items|length')" -ne 1 ]; do
    log " ... ${RED}multiple pods detected${RESET}"
    sleep 3
    continue
  done
  pod="$("$KUBECTL" get -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' pods)"
  log " ... ${GREEN}only pod running is: ${WHITE}${pod}${RESET}"


  # wait until single pod only has 1 line
  count="$(while read -r pod;do
    "$KUBECTL" logs -n "$NAMESPACE" "pod/$pod"
  done < <( "$KUBECTL" get pods --namespace web -o=jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}') | wc -l)"
  if [ "$count" -ne 1 ]; then
    # single pod has multiple lines: like some error occurred. Go back and 'restart deployment'
    log " ... ${RED}running pod(s) have multiple lines${RESET}"
    sleep 3
    continue
  fi

  if [ "$("$KUBECTL" get -n "$NAMESPACE" -o jsonpath='{.items[0].status.phase}' pods)" != 'Running' ]; then
    log " ... ${RED}running pod is not in 'Running' state${RESET}"
    continue
  fi

  pod="$("$KUBECTL" get -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}' pods)"
  if [ "$("$KUBECTL" logs -n "$NAMESPACE" "pod/$pod" | wc -l)" -ne 1 ]; then
    log " ... ${RED}running pod has multiple lines${RESET}"
    sleep 3
    continue
  fi
  break
done

log "${GREY}kc logs -n ${NAMESPACE} ${pod}${RESET}\\n"
"$KUBECTL" logs -n "$NAMESPACE" "$pod"
