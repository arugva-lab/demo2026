#!/bin/bash
source ./lib.sh
source ./env.sh

#ANSIBLE

#ssh at hq,br-rtr
CMD_SSH_TEST='
apt-get update && apt-get install openssh-server -y
systemctl daemon-reload
cat >> /etc/ssh/sshd_config <<EOF
Port 2026
MaxAuthTries 2
PermitRootLogin no
AllowUsers net_admin
EOF
systemctl restart sshd
'
vm_exec $ID_HQ_RTR "$CMD_SSH_TEST" "ssh hq-rtr"
vm_exec $ID_BR_RTR "$CMD_SSH_TEST" "ssh br-rtr"

#ssh hq-cli
CMD_SSH_CLI='
apt-get update && apt-get install openssh-server -y
systemctl daemon-reload
useradd sshuser -u 2026
echo "sshuser:P@ssw0rd" | chpasswd
usermod -aG wheel sshuser
cat >> /etc/openssh/sshd_config <<EOF
Port 2026
MaxAuthTries 2
PermitRootLogin no
AllowUsers sshuser
EOF
systemctl restart sshd
touch /etc/sudoers.d/wheel
echo "WHEEL_USERS	ALL=(ALL:ALL) NOPASSWD:ALL"
'
vm_exec $ID_HQ_CLI "$CMD_SSH_CLI" "ssh hq-cli" >> /etc/sudoers.d/wheel

#BR-SRV ansible
CMD_ANS_TEST='
apt-get update && apt-get install ansible sshpass -y
cat >> /etc/ansible/hosts <<EOF
[clients]
hq-rtr	ansible_host=192.168.1.1	ansible_user=net_admin	ansible_port=2026
br-rtr	ansible_host=192.168.3.1	ansible_user=net_admin	ansible_port=2026
hq-srv	ansible_host=192.168.1.2	ansible_user=sshuser	ansible_port=2026
hq-cli	ansible_host=192.168.2.2	ansible_user=sshuser	ansible_port=2026
EOF

ssh-keygen <<EOF




EOF
echo "y"
sshpass -p "P@ssw0rd" ssh-copy-id -o StrictHostKeyChecking=no -p 2026 net_admin@192.168.1.1
sshpass -p "P@ssw0rd" ssh-copy-id -o StrictHostKeyChecking=no -p 2026 net_admin@192.168.3.1
sshpass -p "P@ssw0rd" ssh-copy-id -o StrictHostKeyChecking=no -p 2026 sshuser@192.168.1.2
sshpass -p "P@ssw0rd" ssh-copy-id -o StrictHostKeyChecking=no -p 2026 sshuser@192.168.2.2
rm -f /etc/ansible/ansible.cfg
touch /etc/ansible/ansible.cfg
cat >> /etc/ansible/ansible.cfg <<EOF
[defaults]
interpreter_python = python3
EOF
ansible all -m ping
'
vm_exec $ID_BR_SRV "$CMD_ANS_TEST" "test ansible"
