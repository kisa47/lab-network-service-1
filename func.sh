#!/bin/bash
set -e

# settings
LAB_NAME="lab-network-service-1"
NETWORK_NAME="${LAB_NAME}-net"
GATEWAY_IP="192.168.200.1"
ROOT_PASSWORD="password"
VM_IMAGE_DIR="/home/b415/images"
BASE_IMAGE_NAME="debian-13-generic-amd64.qcow2"

RESIZE=+150M

create_thin_clone() {
    local vm_name=$1
    local mac=$2
    local userdata_file=$3

    local disk_path="${VM_IMAGE_DIR}/${vm_name}.qcow2"

    if ! virsh --connect qemu:///system dominfo "${vm_name}" >/dev/null 2>&1; then
        echo "Создаю тонкий клон для ${vm_name}..."
        
        # Создаем overlay-диск (копия при записи)
        qemu-img create -f qcow2 -b "${VM_IMAGE_DIR}/${BASE_IMAGE_NAME}" -F qcow2 "${disk_path}"

        cat << EOF > $userdata_file
#cloud-config
hostname: $vm_name

users:
  - name: student
    groups: users
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
chpasswd:
  list: |
    root:password
    student:password
  expire: False
runcmd:
  - [ mkdir, /etc/network/interfaces ]
EOF

        virt-install \
            --name "${vm_name}" \
            --memory 1024 --vcpus 1 \
            --os-variant debian13 \
            --network network="${NETWORK_NAME},mac=${mac}" \
            --disk path="${disk_path}",format=qcow2 \
            --import \
            --cloud-init user-data="${userdata_file}" \
            --autostart \
            --noautoconsole \
            --wait 3 || true
    else
        echo "ВМ ${vm_name} уже существует."
    fi
}

create_network() {
    if ! virsh --connect qemu:///system net-info "${NETWORK_NAME}" >/dev/null 2>&1; then
        echo "Создаю изолированную сеть ${NETWORK_NAME}..."
        cat << EOF > /tmp/${NETWORK_NAME}.xml
<network>
<name>${NETWORK_NAME}</name>
<forward mode='nat'/>
<bridge name='virbr100' stp='on' delay='0'/>
<ip address='${GATEWAY_IP}' netmask='255.255.255.0'>
</ip>
</network>
EOF
    virsh --connect qemu:///system net-define /tmp/${NETWORK_NAME}.xml
    virsh --connect qemu:///system net-start "${NETWORK_NAME}"
    virsh --connect qemu:///system net-autostart "${NETWORK_NAME}"
    rm /tmp/${NETWORK_NAME}.xml
else
    echo "Сеть ${NETWORK_NAME} уже существует."
fi
}