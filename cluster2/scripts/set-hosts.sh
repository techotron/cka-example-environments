#!/bin/bash
#set -e
#IFNAME=$1
#ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
#sed -e "s/^.*${HOSTNAME}.*/${ADDRESS} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts
#
## remove ubuntu-bionic entry
#sed -e '/^.*ubuntu-bionic.*/d' -i /etc/hosts

# Update /etc/hosts about other hosts
cat >> /etc/hosts <<EOF
192.168.57.101  cluster2-master1
192.168.57.201  cluster2-worker1
192.168.57.202  cluster2-worker2
EOF
