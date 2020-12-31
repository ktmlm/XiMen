# 体验 FreeBSD 之基础篇
FreeBSD 与 Linux 一样，同属“类UNIX”操作系统，两个平台上的很多技术都是通用的。    
本讲分享如下几方面内容：
- 系统安装
- 用户管理
- 软件管理
- 服务管理
- 其它常用功能

# 视频讲座
[B 站](https://space.bilibili.com/393582752/channel/detail?cid=70669)    
[腾讯课堂](https://space.bilibili.com/393582752/channel/detail?cid=70669)    
[网易云课堂](https://space.bilibili.com/393582752/channel/detail?cid=70669)    

# 课堂笔记
## 一、系统安装
#### 获取安装盘
国内访问 [FreeBSD 官网](https://freebsd.org)比较慢，建议从中科大镜像站下载：    
<http://mirrors.ustc.edu.cn/freebsd/releases/ISO-IMAGES/12.0>

#### 虚拟机环境
[Qemu](https://www.qemu.org/download/)、
[VirtualBox](https://www.virtualbox.org/wiki/Downloads) 、
[Vmware](https://my.vmware.com/en/web/vmware/info/slug/desktop_end_user_computing/vmware_workstation_pro/15_0?wd=&eqid=cb1f6a7200029bda000000035ca82858) 等都行，挑自己熟悉的即可。    

## 二、用户管理
#### 向导式
```bash
# 添加用户
<root> adduser

# 删除用户
<root> rmuser

# 修改用户属性，包括密码、过期时间、家目录等
<user> chpass
```

#### 高级定制
> pw 是 FreeBSD 下通用的用户管理工具，提供各种细化的配置选项，功能相当于 Linux 下 `useradd + userdel + usermod` 三者的综合，详情 man pw(8)
```bash
# 添加用户
# 用户名(-n)：zhangsan，备注(-c)：张三，登陆 SHELL(-s)：sh，
# 为其创建家目录(-m)，初始密码随机(-w)
<root> pw useradd -n zhangsan -c "张三" -s /bin/sh -m -w random

# 删除用户
# 同时清除其家目录(-r)
<root> pw userdel -n zhangsan -r

# 锁定用户，禁止登陆
<root> pw lock zhangsan
```

## 三、软件管理
#### 启用国内镜像源
```bash
# pkg 方式
# 编辑：/usr/local/etc/pkg/repos/FreeBSD.conf，文件不存在则创建之
FreeBSD: {
    url: "pkg+http://mirrors.ustc.edu.cn/freebsd-pkg/${ABI}/quarterly",
}

# port 方式
# 编辑：/etc/make.conf，文件不存在则创建之
MASTER_SITE_OVERRIDE?=http://mirrors.ustc.edu.cn/freebsd-ports/distfiles/${DIST_SUBDIR}/
```

#### pkg 方式
```bash
# 安装
<root> pkg install <软件包名称>

# 卸载，同时适用于 ports 及 pkg 两种方式安装的包
<root> pkg delete <软件包名称>

# 清除不再需要的依賴包
<root> pkg autoremove

# 显示当前安装的非系统软件包数量
<user> pkg -N

# 查看已安装的非系统软件列表
<user> pkg info

# 查看指定软件包的详细信息
<user> pkg info <软件包名称>

# 查詢指定文件是由哪个软件包安装的
<user> pkg which <文件路径>

# 检查所有已安装包是否存在依賴缺失问题
<user> pkg check -d -a

# 检查所有已安装包的完整性
<user> pkg check -s -a

# 对所有已安装的软件包进行安全审计
<user> pkg audit
```

#### port 方式
```bash
# 下载最新的软件仓库快照
<root> portsnap fetch

# 首次同步 port 快照时需要
<root> portsnap extract

# 更新本地仓库快照
<root> portsnap update

# 通常组合在一起使用
<root> portsnap fetch extract update

# 软件包管理
# 首先切换到软件包的 port 路径，之后使用 make 操作
<root> make config    # 配置编译选项
<root> make install   # 安装
<root> make clean     # 清理临时文件
<root> make deinstall # 卸载
<root> make reinstall # 重新安装
```

#### 更新系统自身
```bash
# 仅适用于系统自带的 GENERIC 内核
<root> freebsd-update fetch install
```

## 四、服务管理
#### 服务启停
```bash
# 启动
<root> service sshd start
<root> service sshd onestart

# 重启
<root> service sshd restart
<root> service sshd onerestart

# 停止
<root> service sshd stop
```
#### 全局配置文件
```bash
# 优先级递减，通常只在 rc.conf.local 中处理，
# 配置规则详见 man rc.conf(5)
/etc/rc.conf.local
/etc/rc.conf
/etc/default/rc.conf
```

#### 自定义服务
> 通过手写 rc 服务脚本的形式实现，通常置于 /usr/local/etc/rc.d/ 目录下，需要添加可执行权限。
```bash
#!/bin/sh

######## 注意!!! 以下两行内容不是注释 ########
# PROVIDE: <服务名称>
# REQUIRE: <必须在这之前启动的服务列表，逗号分割>

# 服务名称，如 "sshd"
name="<服务名称>"

# 指定用于 /etc/rc.conf.local 等配置文件中的开机启动語法
# 如：此处 $name 设置为 sshd，则自启语法就是 sshd_enable="YES"
rcvar=${name}_enable

# 如： /usr/local/bin/sshd
command="<可执行文件的路径>"

# 可选：指定服务的 pid 文件存储路径，方便管理
# pidfile="<pid 路径>"

# 除 start/restart/onestart/onrestart/stop 等系统预置的子命令外，
# 在此列出用户自定义的其它子命令名称，以空格分割
extra_commands="<自定义子命令-1> <自定义子命令-2>"

# 用户自定义的子命令的具体实现，有两种方式：
# - 比较简单的直接在参数中写内容
# - 相对复杂的在参数中写自定义的函数的名称，并在之后实现该函数
<自定义子命令-1>_cmd="echo Hello World"
<自定义子命令-2>_cmd="do_<自定义子命令-2>"

do_<自定义子命令-2>() {
    echo "Hello World Again"
}

# 以下三项为固定格式，用于设置系统预定义的环境
. /etc/rc.subr
load_rc_config $name
run_rc_command "$1"
```

## 五、其它常用功能
#### 网络配置
```bash
# 查看已建立的网络连接
<user> sockstat -c

# 查看服务端口
<user> sockstat -4 # IPV4
<user> sockstat -6 # IPV6

# 设置 IP
<user> ifconfig <网卡名称> 192.168.1.99 netmask 255.255.225.0

# 配置路由
<root> route add default 192.168.1.1
<root> route change default 192.168.1.1

# 也可以通过修改 /etc/rc.conf.local 实现
# 需要刷新相关服务，才能生效
<root> /etc/netstart
<root> /etc/rc.d/netif restart
<root> /etc/rc.d/routing restart
```

#### 系统参数
> 现代 FreeBSD 的 /proc 伪文件系统默认是关闭的，所有系统参数相关的操作都通过 sysctl 命令完成；若要持久生效，需要修改 /etc/sysctl.conf，详细规则 man sysctl.conf(5)
```bash
# 显示全部可用参数列表
<user> sysctl -a

# 显示所有非只读参数
# 某些参数只能在系统初始化时设置，之后不能修改，称为"只读参数"
# 若要修改，在 /boot/loader.conf 中设置，然后重启生效
# 详情参照 man loader.conf(5)
<user> sysctl -T

# 查询参数含义
<user> sysctl -d hw.pagesize

# 查询参数值
<user> sysctl hw.ncpu
<user> sysctl hw.byteorder
<user> sysctl kern.boottime

# 设置参数值
<root> sysctl kern.maxprocperuid=1000

# 从指定文件中载入配置
# 如：修改 sysctl.conf 之后，使之立刻生效
sysctl -f /etc/sysctl.conf
```

#### 文件保护
> 功能类似于 Linux 下的 chattr 命令
```bash
# 添加"不可删除"标志
<root> chflags sunlink $file

# 添加"完全不可修改"状态，
# 对文件内容或属性的任何增、删、改都是禁止的，
# 通常用于防止系统关键路径被误操作
<root> chflags -R simmutable /sbin

# 以 'no' 开头的参数表示解除对应的状态
<root> chflags nosunlink $file
<root> chflags -R nosimmutable /sbin
```

#### FTP 文件共享
> ftpd 是 FreeBSD 自带的一个精简实用的 ftp 服务器
```bash
# 黑名单
<root> echo "root" >> /etc/ftpusers

# 将所有用户锁定在指定目录(/home/ftp)下，禁止查看外部目录結构
<root> echo "@ /home/ftp" >> /etc/ftpchroot

# 开机自启
<root> echo "ftpd_enable="YES"" >> /etc/rc.conf
```

#### 安全排查
```bash
# 排查结果写出到：/var/log/rkhunter.log
rkhunter -c
```

#### 内核安全等级
> 分为四级：-1、0、1、2、3
> - 级别 -1 或 0：Insecure Mode，适用于桌面环境
> - 级别 1：Secure Mode，不能修改文件的 immutable 和 append-only 标志、不能 load 或 unload 内核模块、不能对 /dev/mem 及 /dev/kmem 执行写操作
> - 级别 2：Highly Secure Mode，在级别 1 之上，額外限制不能将磁盘挂载或重新挂载成可写模式、多用户环境下不能使用 newfs 格式化磁盘
> - 级别 3：Network Secure Mode，在级别 2 之上，額外限制不能修改 ipfw 规则、不能修改 dummynet 与 pf 的配置文件

> 特别注意!!!     
> 内核安全级别被强制限制为只增不减，即使在单用户模式下，也无法降低安全等级，因此，若无确切需求，不要轻易修改。
```bash
# /etc/rc.conf
kern_securelevel_enable=“YES”

# /etc/sysctl.conf
kern.securelevel=0
```

## 其它
全方位操作指南，详见 FreeBSD Handbook:    
<https://www.freebsd.org/doc/en_US.ISO8859-1/books/handbook>
