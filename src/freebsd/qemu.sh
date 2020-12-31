#!/usr/bin/env bash
ifname="enp5s0"             # 宿主机端口名称
br_name="br0"               # 虚拟网桥名称
br_addr="192.168.1.100/24"  # 给虚拟网桥配置的 IP
br_rtaddr="192.168.1.1"     # 虚拟网桥的网关 IP

iso_path="/tmp/FreeBSD.iso" # 安装盘存放路径
vm_path="/tmp/qemu"         # 虚拟机路径
vm_disk="disk.qcow2"        # 虚拟硬盘文件名

# 配置虚拟网桥
ip link del $br_name 2>/dev/null
ip link add $br_name type bridge || exit 1
ip link set $br_name up || exit 1
ip addr add $br_addr dev $br_name || exit 1
ip route replace default via $br_rtaddr dev $br_name || exit 1
ip addr flush dev $ifname || exit 1
ip route flush dev $ifname || exit 1
ip link set $ifname master $br_name || exit 1

# 按需创建虚拟机路径并进入
mkdir -p $vm_path || exit 1
cd $vm_path || exit 1

# tap 形式联网需要一个回调脚本
echo "#!/usr/bin/env bash
      ip link set \$1 up && sleep 0.1s;
      ip link set \$1 master $br_name" > tap.sh
chmod +x tap.sh

# 按需创建虚拟硬盘
if [[ 0 -eq `find . -name $vm_disk -type f | wc -l` ]]; then
    qemu-img create -f qcow2 -o size=20G disk.qcow2 || exit 1
fi

# 启动虚拟机，参数含义 man qemu-system-x86_64(1)
qemu-system-x86_64 -smbios type=0,uefi=on -enable-kvm \
    -machine q35,accel=kvm -device intel-iommu \
    -cpu host -smp 4,sockets=4,cores=1,threads=1 \
    -m 4096 \
    -netdev tap,ifname=tap0,script=tap.sh,id=vmNic -device virtio-net-pci,netdev=vmNic \
    -drive file=${vm_path}/${vm_disk},if=none,cache=writeback,id=vmDisk -device virtio-blk-pci,drive=vmDisk \
    -drive file=${iso_path},readonly=on,media=cdrom \
    -boot order=cd \
    -name vmFreeBSD \
    -display curses

#    -vnc :99
#    -daemonize

