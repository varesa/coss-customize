#version=RHEL8
# Use graphical install
graphical

repo --name="AppStream" --baseurl=file:///run/install/sources/mount-0000-cdrom/AppStream
repo --name="custom" --baseurl=file:///run/install/sources/mount-0000-cdrom/custom_rpm

%packages
@^minimal-environment
kexec-tools

# Extras:
frr
nmstate

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
# Partition clearing information
clearpart --none --initlabel
# Disk partitioning information
part raid.11 --fstype="mdmember" --ondisk=sdb --size=601
part raid.12 --fstype="mdmember" --ondisk=sda --size=601

part raid.21 --fstype="mdmember" --ondisk=sda --size=1025
part raid.22 --fstype="mdmember" --ondisk=sdb --size=1025

part raid.31 --fstype="mdmember" --ondisk=sdb --size=50000
part raid.32 --fstype="mdmember" --ondisk=sda --size=50000

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
