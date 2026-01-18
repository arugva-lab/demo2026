
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
sleep 60
CMD_DC_HQ_CLI='
echo "P@ssw0rd" | kinit Administrator@AU-TEAM.IRPO
echo "P@ssw0rd" | /usr/sbin/realm join -U Administrator
echo "session		optional	pam_mkhomedir.so skel=/etc/skel umask=0077" >> /etc/pam.d/system-auth
echo "ad_enable_gc = False" >> /etc/sssd/sssd.conf
sed -i "s/names = True/names = False/" /etc/sssd/sssd.conf
systemctl restart sssd
touch /etc/sudoers.d/hq
echo "%hq       ALL=(ALL) NOPASSWD: /usr/bin/cat, /bin/grep, /usr/bin/id" >> /etc/sudoers.d/hq
control sudo public
'

vm_exec $ID_HQ_CLI "$CMD_DC_HQ_CLI" "test samba"

#File storage
qm set "$ID_HQ_SRV" --scsi1 local-lvm:1
qm set "$ID_HQ_SRV" --scsi2 local-lvm:1
CMD_RAID_HQ_SRV='
sleep 10
mdadm --create /dev/md0 --level=0 --raid-device=2 /dev/sdb /dev/sdc
fdisk /dev/md0 << EOF
n
p



w
EOF
mkfs.ext4 /dev/md0p1
mkdir /home/raid
mount /dev/md0p1 /home/raid
'
vm_exec $ID_HQ_SRV "$CMD_RAID_HQ_SRV" "test raid"

#nfs
CMD_NFS_HQ_SRV='
apt-get install nfs-server -y
mkdir -p /raid/nfs
chmod 777 /raid/nfs
echo "/raid/nfs       192.168.2.0/28(rw,no_subtree_check)" >> /etc/exports
exports -a
systemctl restart nfs-server
systemctl enable --now nfs-server
'
vm_exec $ID_HQ_SRV "$CMD_NFS_HQ_SRV" "test nfs server"

CMD_NFS_HQ_CLI='
apt-get install nfs-clients
mkdir /mnt/nfs
mount -t nfs HQ-SRV:/raid/nfs /mnt/nfs
echo "HQ-SRV:/raid/nfs      /mnt/nfs      nfs      defaults      0      0" >> /etc/fstab
touch /mnt/nfs/test_demo2026
echo "test" >> /mnt/nfs/test_demo2026
'
vm_exec $ID_HQ_CLI "$CMD_NFS_HQ_CLI" "test nfs client"

#chrony
CMD_ISP_CHRONY='
apt-get install chrony -y
sed -i "s/pool/#pool/" /etc/chrony/chrony.conf
sed -i "s/rtcsync/#rtcsync/" /etc/chrony/chrony.conf
echo "local stratum 5" >> /etc/chrony/chrony.conf
echo "allow all" >> /etc/chrony/chrony.conf
systemctl restart chronyd
'
vm_exec $ID_ISP "$CMD_ISP_CHRONY" "test chrony"

CMD_ASTRA_CHRONY='
apt-get install chrony -y
timedatectl set-ntp false
sed -i "s/pool/#pool/" /etc/chrony/chrony.conf
sed -i "s/rtcsync/#rtcsync/" /etc/chrony/chrony.conf
echo "server 172.16.1.1" >> /etc/chrony/chrony.conf
systemctl restart chronyd
'
vm_exec $ID_HQ_RTR "$CMD_ASTRA_CHRONY" "test chrony"
vm_exec $ID_BR_RTR "$CMD_ASTRA_CHRONY" "test chrony"

CMD_ALT_CHRONY='
apt-get install chrony -y
timedatectl set-ntp false
sed -i "s/pool/#pool/" /etc/chrony.conf
sed -i "s/rtcsync/#rtcsync/" /etc/chrony.conf
echo "server 172.16.1.1" >> /etc/chrony.conf
systemctl restart chronyd
'

vm_exec $ID_HQ_SRV "$CMD_ALT_CHRONY" "test chrony"
vm_exec $ID_BR_SRV "$CMD_ALT_CHRONY" "test chrony"
vm_exec $ID_HQ_CLI "$CMD_ALT_CHRONY" "test chrony"
