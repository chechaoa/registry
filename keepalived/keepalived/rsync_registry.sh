#!/bin/bash
#set -x
sync=`date +%F`
mkdir -p /var/log/keepalived
SYNC_LOG_DIR=/var/log/keepalived
touch ${SYNC_LOG_DIR}/$sync.log

KEEPALIVED_STATE_PATH=/opt
# 
KEEPALIVED_IPS=${KEEPALIVED_STATE_PATH}/.keepalived_ips
CHECK_KEEPALIVED_STATE=${KEEPALIVED_STATE_PATH}/.check_keepalived_state
REGISTRY_DOMAIN="https://regsitry.io:443"
MASTER_IP=`ifconfig | grep -w inet | grep -v "127.0.0.1" | awk '{ print $2}'| tr -d "addr" |awk  'NR==1'`
# This policy is based on dynamically acquired provider policy by check_keepalived_state.sh 
BACKUP_IP=`grep 'backup' ${KEEPALIVED_IPS} |more |awk '{print $2}'`
IMAGE_LIST=$(curl --silent -X GET ${REGISTRY_DOMAIN}/v2/_catalog |jq -rc '.repositories[]')

/usr/bin/curl -s -k --connect-timeout 5 https://${BACKUP_IP}:443/v2/ -o /dev/null


function http_check()
{
  status_code=$(curl -k --write-out "%{http_code}" --silent --output /dev/null "${1}")

  if [[ "${status_code}" == "200" ]] ; then
    echoinfo "The ${1} website is running, and the status code is ${status_code}."
  else
    echoerr "Error: the ${1} website is not running, and the status code is ${status_code}!"
    exit 1
  fi
}


function sync_registry()
{
    RESULT=`grep 'MASTER' ${CHECK_KEEPALIVED_STATE} |more`
    if [ "${RESULT}" == "MASTER" ];then
      for image in ${IMAGE_LIST};do
        tags=$(curl --silent -X GET ${REGISTRY_DOMAIN}/v2/${image}/tags/list |jq -rc '.tags[]')
        tags_count=$(echo ${tag} |wc -w)       
        if [[ ${tags_count} != 1 ]];then
          for current_tag in ${tags};do
            skopeo copy --insecure-policy --src-tls-verify=false --dest-tls-verify=false \
            docker://${MASTER_IP}/${image}:${current_tag} docker://${BACKUP_IP}/${image}:${current_tag} --retry-times 3  > ${SYNC_LOG_DIR}/$sync.log
            echo  "***Progress: sync ${image}/${current_tag}  from ${MASTER_IP} to ${BACKUP_IP} successful!!!***"
          done
        else
          echo "${image}:${tags}"
          skopeo copy --insecure-policy --src-tls-verify=false --dest-tls-verify=false \
          docker://${MASTER_IP}/${image}:${tags} docker://${BACKUP_IP}/${image}:${tags} --retry-times 3  > ${SYNC_LOG_DIR}/$sync.log
          echo  "***Progress: sync ${image}/${current_tag}  from ${MASTER_IP} to ${BACKUP_IP} successful!!!***"
        fi
      done
    else
      echo -e "*** Please Check keepalived state \n whether or not cat ${CHECK_KEEPALIVED_STATE} equal to MASTER ***"
    fi
}

sync_registry