#!/bin/bash


### Run the script with the vul name after to search for specific vul
### For example ./script.sh CVE-2021-44228
RED='\033[0;31m'
NC='\033[0m'

OLDIFS="$IFS"
IFS=$'\n'
VULN=$1

# $1 arg is the CVE number to check
if [ -z $1 ]; then
  echo -e "usage: $0 CVE-NUMBER (i.e: './vuln_k8s.sh CVE-2021-44228')"
  exit
fi

# Check command existence before using it
if ! command -v trivy &> /dev/null; then
  echo "trivy not found, please install it"
  exit
fi
if ! command -v kubectl &> /dev/null; then
  echo "kubectl not found, please install it"
  exit
fi

# CVE-2021-44228
echo "Scanning $1..."

namespaces=`kubectl get ns | cut -d' ' -f 1 | tail -n+2`
for ns in ${namespaces}; do
  echo "- scanning in namespace ${ns}"
  imgs=`kubectl get pods -n ${ns} -o jsonpath='{range .items[*]}{.spec.containers[*].image}{" "}' | tr " " "\n" | sort -u`
  for img in ${imgs}; do
    echo "  scanning ${img}"
    result=`trivy -q image --light --no-progress --severity CRITICAL ${img}`
    if echo ${result} | grep -q "$1" ; then
      echo -e "  ${RED}${img} is vulnerable, please patch!${NC}"
    fi
  done
done

IFS="$OLDIFS"
