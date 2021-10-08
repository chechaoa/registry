#!/bin/bash

KEEPALIVED_PATH=/etc/keepalived
CHECK_KEEPALIVED_STATE=${KEEPALIVED_PATH}/.check_keepalived_state
KEEPALIVED_IPS=${KEEPALIVED_PATH}/.keepalived_ips

function check_keepalived_state()
{
    if [[ ! -f ${CHECK_KEEPALIVED_STATE} ]];then
        touch ${CHECK_KEEPALIVED_STATE}
    fi
}

case "$1" in
  start )
    echo  -e "master: ${KEEPALIVED_UNICAST_SRC_IP}\nbackup: ${KEEPALIVED_UNICAST_PEER}" > ${KEEPALIVED_IPS}
    echo "MASTER" > ${CHECK_KEEPALIVED_STATE}
  ;;
  stop )
    echo  -e "master: ${KEEPALIVED_UNICAST_PEER}\nbackup: ${KEEPALIVED_UNICAST_SRC_IP}" > ${KEEPALIVED_IPS}
    echo "BACKUP" > ${CHECK_KEEPALIVED_STATE}
  ;;
   * )
    echo "Usage:$0 start|stop"
  ;;
esac