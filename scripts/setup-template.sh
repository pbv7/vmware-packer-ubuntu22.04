#!/usr/bin/bash

# Cleanup script.
echo '> Creating cleanup script ...'
sudo cat <<EOF > /tmp/cleanup.sh
#!/bin/bash

# Update system
echo '> Upgrading system ...'
apt update
apt upgrade -y

# Clear audit logs.
echo '> Cleaning all audit logs ...'
if [ -f /var/log/audit/audit.log ]; then
cat /dev/null > /var/log/audit/audit.log
fi
if [ -f /var/log/wtmp ]; then
cat /dev/null > /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
cat /dev/null > /var/log/lastlog
fi

# Cleanup persistent udev rules.
echo '> Cleaning persistent udev rules ...'
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
rm /etc/udev/rules.d/70-persistent-net.rules
fi

# Cleanup /tmp directories.
echo '> Cleaning /tmp directories ...'
rm -rf /tmp/*
rm -rf /var/tmp/*

# Cleanup existed ssh keys.
echo '> Cleaning SSH keys ...'
rm -f /etc/ssh/ssh_host_*

# Set hostname to localhost.
echo '> Setting hostname to localhost ...'
cat /dev/null > /etc/hostname
hostnamectl set-hostname localhost

# Cleanup package management system.
echo '> Cleaning apt package management system ...'
apt autoremove --purge
apt clean


# Reset machine-id.
echo '> Resetting machine-id ...'
truncate -s 0 /etc/machine-id
rm /var/lib/dbus/machine-id
ln -s /etc/machine-id /var/lib/dbus/machine-id

# Cleanup shell history.
echo '> Cleaning shell history ...'
unset HISTFILE
history -cw
echo > ~/.bash_history
rm -fr /root/.bash_history

# Allow Guest OS Customization with cloud-init engine.
# https://kb.vmware.com/s/article/80934
echo '> Setting Guest OS Customization options ...'
rm -rf /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm -rf /etc/cloud/cloud.cfg.d/99-installer.cfg

# Switch to cloud-init based customization engine by enabling Guest OS Customization with cloud-init.
# https://kb.vmware.com/s/article/59557
echo "disable_vmware_customization: false" >> /etc/cloud/cloud.cfg
echo "# to update this file, run dpkg-reconfigure cloud-init
datasource_list: [ VMware, OVF, None ]" > /etc/cloud/cloud.cfg.d/90_dpkg.cfg

# Set boot options to not override what we are sending in cloud-init
echo `> Modifying grub ...`
sed -i -e "s/GRUB_CMDLINE_LINUX_DEFAULT=\"\(.*\)\"/GRUB_CMDLINE_LINUX_DEFAULT=\"\"/" /etc/default/grub
update-grub
EOF

# Make script executable.
echo '> Make script executable ...'
sudo chmod +x /tmp/cleanup.sh

# Run the cleanup.
echo '> Executing the cleanup script ...'
sudo /tmp/cleanup.sh

# All done. 
echo '> Done.'  

echo '> Packer Template Build Completed'
