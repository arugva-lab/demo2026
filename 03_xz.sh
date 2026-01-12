#!/bin/bash
source ./env.sh
source ./lib.sh

#Samba DC on BR-SRV
CMD_DC_BR_SRV='
apt-get update && apt-get install task-samba-dc rng-tools -y
systemctl enable --now rngd
rm -f /etc/samba/smb.conf
samba-tool domain provision --realm=AU-TEAM.IRPO --domain=AU-TEAM --server-role=dc --dns-backend=SAMBA_INTERNAL --adminpass="P@ssw0rd" --use-rfc2307 --host-ip=192.168.1.2 --host-name=br-srv --option="interfaces=lo '$BR_SRV_IF'" --option="bind interfaces only=yes"
systemctl restart samba
systemctl enable --now samba
cp /var/lib/samba/private/krb5.conf /etc/krb5.conf
samba-tool user create hquser1 P@ssw0rd
samba-tool user create hquser2 P@ssw0rd
samba-tool user create hquser3 P@ssw0rd
samba-tool user create hquser4 P@ssw0rd
samba-tool user create hquser5 P@ssw0rd
samba-tool group add hq
samba-tool group addmembers hq hquser1,hquser2,hquser3,hquser4,hquser5
'
vm_exec $ID_BR_SRV "$CMD_DC_BR_SRV" "test samba"

CMD_DC_HQ_CLI='
echo "P@ssw0rd" | /usr/sbin/realm join -U Administrator AU-TEAM.IRPO
echo "session		optional	pam_mkhomedir.so skel=/etc/skel umask=0077" >> /etc/pam.d/system-auth
echo "ad_enable_gc = False" >> /etc/sssd/sssd.conf
sed -i "s/names = True/names = False/" /etc/sssd/sssd.conf
systemctl restart sssd
touch /etc/sudoers.d/hq
echo "%hq       ALL=(ALL) NOPASSWD: /usr/bin/cat, /bin/grep, /usr/bin/id" >> /etc/sudoers.d/hq
control sudo public
'

vm_exec $ID_HQ_CLI "$CMD_DC_HQ_CLI" "test samba"
