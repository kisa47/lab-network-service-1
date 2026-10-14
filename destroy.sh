#!/bin/bash

destroy_domain() {
    local domain_name=$1
    virsh --connect qemu:///system destroy $domain_name
    virsh --connect qemu:///system undefine $domain_name
}

destroy_net() {
    local net_name=$1
    virsh --connect qemu:///system net-destroy $net_name
    virsh --connect qemu:///systemnet-undefine $net_name
}

destroy_domain "dhcp-server"
destroy_domain "client-1"
destroy_domain "client-2"
