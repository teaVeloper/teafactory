systemctl start sshd
passwd
mkdir -p /host/arch-setup
mount -t 9p -o trans=virtio,version=9p2000.L archsetup /host/arch-setup

# ssh -p 2222 root@127.0.0.1
