#!/bin/bash
#
# This script assumes that you've already populated swarm00 with docker(+ compose) installed.
#
#

rgrp=ehirdoy-sim
azdomain=westeurope.cloudapp.azure.com
vmdisk=https://vhd1484224552579.blob.core.windows.net/vhds/osdisk14842256291960.vhd # swarm00 disk image
maxvm=2 # number of worker VM

function az_vm_delete {
    n=$(az vm list -g $rgrp --output table | grep "swarm" | wc -l)
    [ $n == 1 ] && return 0
    for x in $(seq 1 $maxvm); do
	az vm delete -g $rgrp -n swarm$(printf "%02d" $x) &
    done
    while true; do
	n=$(az vm list -g $rgrp --output table | grep "swarm" | wc -l)
	[ $n == 1 ] && break
	sleep 3
    done
}

function az_vm_populate {
    for x in $(seq 1 $maxvm); do
	n=swarm$(printf "%02d" $x);
	az vm create -g $rgrp -n $n \
	    --public-ip-address-dns-name $n \
	    --custom-os-disk-type linux \
	    --image $vmdisk &
    done
    while true; do
	n=$(az vm list -g $rgrp  --output table | grep "swarm" | wc -l)
	[ $n == $(($maxvm + 1)) ] && break
	sleep 3
    done
    while true; do
	n=$(az vm list -g $rgrp  --output table | grep "Succeeded" | wc -l)
	[ $n == $(($maxvm + 1)) ] && break
	sleep 3
    done
}

function local_ssh_key_cleanup {
    for x in $(seq 1 $maxvm); do
	n=swarm$(printf "%02d" $x).$azdomain
	ssh-keygen -f "$HOME/.ssh/known_hosts" -R $n
    done
}

function swarm_init {
    mgvm=swarm00.$azdomain
    ssh $mgvm "docker swarm leave --force; docker swarm init"
    token=$(ssh $mgvm "docker swarm join-token worker -q")
    mgip=$(dig +short $mgvm)
    for x in $(seq 1 $maxvm); do
	n=swarm$(printf "%02d" $x).$azdomain
	ssh -o StrictHostKeyChecking=no $n \
	    "docker swarm leave --force; docker swarm join --token $token $mgip:2377"
    done
    while true; do
	n=$(ssh $mgvm "docker node ls -q | wc -l")
	[ $n == $(($maxvm + 1)) ] && break
	sleep 3
    done
}

#az vm restart -g $rgrp -n swarm00
time az_vm_delete	&& echo "VMs deleted" || { echo "Failed to delete VMs" && exit 123; }
time az_vm_populate	&& echo "VMs populated " || { echo "Failed to populate VMs" && exit 123; }
local_ssh_key_cleanup
time swarm_init		&& echo "Swarm initialized" || { echo "Failed to init Swarms" && exit 123; }
