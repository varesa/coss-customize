#version=RHEL8
text
reboot

repo --name="AppStream" --baseurl=file:///run/install/sources/mount-0000-cdrom/AppStream
repo --name="custom" --baseurl=file:///run/install/sources/mount-0000-cdrom/custom_rpm

%packages
@^minimal-environment
kexec-tools

# Extras:
frr
nmstate
tar
tcpdump
puppet7-release

# For firstboot.py
python3
python3-requests

%end

# Keyboard layouts
keyboard --xlayouts='fi'
# System language
lang en_US.UTF-8

# Network information
network  --hostname=localhost.localdomain

# Use CDROM installation media
cdrom

# Run the Setup Agent on first boot
firstboot --enable

ignoredisk --only-use=sda,sdb
clearpart --initlabel --drives=sda,sdb

# Disk partitioning information
part raid.11 --fstype="mdmember" --ondisk=sda --size=601
part raid.12 --fstype="mdmember" --ondisk=sdb --size=601

part raid.21 --fstype="mdmember" --ondisk=sda --size=1025
part raid.22 --fstype="mdmember" --ondisk=sdb --size=1025

part raid.31 --fstype="mdmember" --ondisk=sda --size=50000
part raid.32 --fstype="mdmember" --ondisk=sdb --size=50000

raid /boot/efi --device=boot_efi --fstype="efi" --level=RAID1 --fsoptions="umask=0077,shortname=winnt" raid.11 raid.12
raid /boot --device=boot --fstype="xfs" --level=RAID1 raid.21 raid.22
raid pv.1 --device=pv00 --fstype="lvmpv" --level=RAID1 raid.31 raid.32

volgroup cl pv.1
logvol / --fstype="xfs" --size=10000 --name=root --vgname=cl

# System timezone
timezone Europe/Helsinki --isUtc --nontp

# Root password
rootpw --iscrypted $6$wY.edbVvTiKQQ9sI$eHxvMlnJU0qiox.5P8w0jqgbK.l8rNlERD/mKNMVTAtS6xB.6qdDdyhlG82Ldt9AiNfFp1.YzfddGH1QJOcQY/

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end

%post
dnf install -y puppet-agent
%end

%post --nochroot --log=/mnt/sysimage/root/ks-post2.log
cp /run/install/sources/mount-0000-cdrom/bootstrap/firstboot.py /mnt/sysimage/usr/local/sbin/firstboot.py
cp /run/install/sources/mount-0000-cdrom/bootstrap/firstboot.service /mnt/sysimage/etc/systemd/system/firstboot.service
ln -s /etc/systemd/system/firstboot.service /mnt/sysimage/etc/systemd/system/multi-user.target.wants/firstboot.service
touch /mnt/sysimage/etc/do-run-firstboot
%end
