# OpenWrt 配置备忘录
> 文件名：`openwrt-configuration-notes.md`，[网络拓扑图](openwrt-network-topology.png)

## 1、配置时区和NTP服务器，让路由器时间准确，以免影响基于时间控网的准确性
关联文件：`/etc/config/system`
1. 设置时区：
`config system` 节中：
```
option timezone 'CST-8'
option zonename 'Asia/Shanghai'
```
2. 设置NTP服务器：
`config timeserver 'ntp'` 节中：
```
list server ntp.aliyun.com   #阿里云
list server ntp.ntsc.ac.cn   #国家授时中心
```
## 2、配置使用SSH密钥登录路由器，降低密码泄露风险
关联文件：`/etc/dropbear/authorized_keys`
1. 设置`SSH公钥`：使用`PuTTYgen`生成公、私钥对，直接将软件界面最上方的公钥复制到SSH密钥框中，如果是导出的公钥，粘贴的时候，首行要提供加密算法，如`ssh-rsa`，再加一个空格或换行后将密钥放在一行，示例：`ssh-rsa ****** rsa-key-20261030`
2. `SSH软件`中给`root`设置此私钥后就可以免密登录

## 3、使用国内的opkg/apk软件源，让软件安装、升级更快
关联文件：`/etc/opkg/distfeeds.conf` or `/etc/apk/repositories.d/distfeeds.list`
1. 使用阿里云镜像源：将文中 `downloads.openwrt.org` 替换为 `mirrors.aliyun.com/openwrt`
2. 使用上交大镜像源：将文中 `downloads.openwrt.org` 替换为 `mirror.sjtu.edu.cn/openwrt` or `mirrors.sjtug.sjtu.edu.cn/openwrt`

## 4、/etc/init.d 下制定有先后启动顺序（脚本中设置START的值）的脚本，让其在指定的启动时机执行
1. `tvphone`脚本：`\etc\init.d\tvphone`，`START=99`
    - `傻瓜式控网`所使用的`启动初始化`脚本，关联目录：`/etc/config/tvphone`
    - 脚本内容有两类：`自动时段规则脚本`和`全时允许或禁止规则脚本`
2. `firewall_user`脚本：`\etc\init.d\firewall_user`，`START=99`
    - `自定义防火墙规则的启动初始化脚本`，有一些防火墙规则，如使用`ebtables、iptables-mod-tee`制定的规则，这些规则无法通过`LuCI以WebGUI`方式配置，故将这些规则统一放到自定义的`firewall_user启动脚本`中执行，关联脚本目录：`/etc/config/firewall_user`
    - 此处的功能脚本有：
        - 使用`nft bridge`禁止`特定组播流`从`lan1/eth1`流出
        - 使用`ebtables`禁止`无线wlan21/wlan22/wlan51/wlan52接口`的`IPv6通信`
        - 使用`iptables-mod-tee`将`192.168.199.0/24`网段用于投屏的SSDP协议转发至`192.168.99.0/24网段`，以实现`跨网段投屏视频`
        - `DELL笔记本IP：192.168.99.8`和`小天才电话手表IP：192.168.69.218`的`基于时间段`的控网规则
        - 指定`192.168.33.0/24网段`访问`指定的目标域名`（在`SSRP中`设定，叫`强制走代理的域名`）时走代理
        - 指定`192.168.9.0/24、192.168.99.0/24网段`访问`指定的目标域名`（在`Dnsmasq中`指定，IPSet名称叫`epglist`）时走代理
        - 删除`docker`自动添加的`SNAT`，将`docker桥网络`对外访问由`NAT`改为`只路由转发`
3. `ipset_user`脚本：`/etc/init.d/ipset_user`，`START=18`
    - 创建类型为`hash:net`的`IP集合`：`epglist`
4. 初始化脚本里相关联的其他脚本要设置可执行权限

## 5、自定义启动脚本 /etc/rc.local
1. `/etc/rc.local`的启动时机：在 `/etc/init.d/done` 的 `boot() 函数`中执行的 `/etc/rc.local` 脚本，`done`的`START=95`，因此`rc.local不是在所有/etc/init.d中脚本执行完之后才执行的脚本`
2. 有关脚本命令：
    - 重置虚拟内存文件系统大小（非必要）：
    ```bash
    mount -o remount,size=256M /tmp
    ```
    - 关闭`lan1和eth1`两个接口的`rx-gro-list`：
    ```bash
    ethtool -K lan1 rx-gro-list off
    ethtool -K eth1 rx-gro-list off
    ```
## 6、计划任务配置文件 /etc/crontabs/root
1. 计划任务由 `/etc/init.d/cron` 执行，定时执行的任务都可以放到这里
2. `傻瓜式控网`需要在`临时控网时间`到`时段控网时间`时自动恢复到`时段控网`，因此添加`时段控网`各个时间点的计划任务。这里执行的关联脚本也需要`设置可执行权限`

## 7、配置自动挂载交换分区和移动硬盘
1. 关联软件：`block-mount`；关联配置文件：`/etc/config/fstab`
2. 使用`block-mount`可`自动挂载`未配置的`Swap分区`（包含交换分区和交换文件）、交换分区、磁盘等；自动挂载交换分区前，使用`mkswap格式化交换分区`
3. 使用`blkid`或`lsblk -f`查看磁盘分区的`UUID`，然后以`UUID挂载方式`将移动硬盘挂载到`/mnt/u32g`，固态硬盘使用的文件系统是`f2fs`

## 8、系统升级或备份时要保留的文件或目录
关联文件：`/etc/sysupgrade.conf`
1. 目录`/etc/config/`内更改过的文件以及部分其他配置会被自动保存
2. 添加以下需保留的文件或目录：
    - USB串口控制台、USB摄像头、USB可视化资源查看器的热插拔响应脚本（USB HUB自左向右依次接摄像头、USB串口线、移动硬盘、SD2）：
      ```
      /etc/hostplus.d/usb/10-usb-device-hotplug
      ```
    - 傻瓜式控网和禁止或启用大小电视的IPv6通信和查看CPU温度和IPv6下打开USB摄像头的LuCI Web程序：
      ```
      /usr/lib/lua/luci/controller/ewangsoft/
      /usr/lib/lua/luci/view/ewangsoft/
      ```
    - 自启动：
      ```
      /etc/init.d/firewall_user
      /etc/init.d/ipset_user
      /etc/init.d/tvphone
      /etc/init.d/phtunnel
      ```
    - 软件仓库源：
      ```
      /etc/opkg/distfeeds.conf
      ```
    - 花生壳文件：
      ```
      /usr/bin/phtunnel
      /etc/phtunnel.json
      ```
    - SmartDNS：
      ```
      /etc/smartdns/
      ```
## 9、自定义Web应用的相关操作链接
1. `傻瓜式控网`登录页面：
2. 禁用/启用大(接lan2)/小(接lan3)电视IPv6通信的页面：涉及`ipv6_int_action.sh`及两个电视连接openwrt的设备接口名称
3. 查看CPU温度页面：
4. 通过IPv6打开USB摄像头的页面(配置脚本`/etc/config/getv6address.sh`，wan接口名称为br-wan，MJPG-streamer使用 * 端口)：

## 10、Docker配置：来源= immortalwrt/luci/applications/luci-app-dockerman
1. 配置文件：
    - `/etc/config/docker` & `/etc/config/dockerd`
2. 创建CustomBrNet网络：`192.168.33.0/24`，网关`192.168.33.1`，创建后会自动创建一个网桥
    创建TailscaleBrNet网络：`192.168.88.0/24`，网关`192.168.88.1`，创建后会自动创建一个网桥
3. 创建第2步生成网桥的三层接口网络，分别命名为CustomBrNet/TailscaleBrNet，不配置协议，加入docker防火墙区域，docker防火墙区域允许访问wan及wan6区域
4. Docker镜像：
    ```
    mp=jxxghp/moviepilot:latest
    qb=linuxserver/qbittorrent:latest
    jf=jellyfin/jellyfin:latest
    epg=taksss/php-epg:latest
    npm=jc21/nginx-proxy-manager:latest
    tvgate=juestnow/tvgate:latest
    tailscale=tailscale/tailscale:latest
    ```
5. 容器配置：
    - mp：`192.168.33.3:3000`
      环境变量：
      ```
      IYUU_SIGN=*
      SUPERUSER=admin
      API_TOKEN=*
      ```
      挂载点：
      ```
      /mnt:/mnt
      /mnt/u32g/moviepilot/config:/config
      /mnt/u32g/moviepilot/core:/moviepilot/.cache/ms-playwright
      /var/run/docker.sock:/var/run/docker.sock:ro
      ```
    - qb：`192.168.33.6:8080`
      环境变量：
      ```
      TZ=Asia/Shanghai
      PUID=0
      GUID=0
      TORRENTING_PORT=*
      WEBUI_PORT=*
      ```
      挂载点：
      ```
      /mnt/u32g/qbittorrent/appdata:/config
      /mnt:/mnt
      ```
    - jf：`192.168.33.9:8096`
      挂载点：
      ```
      /mnt:/mnt
      /mnt/u32g/jellyfin/config:/config
      /mnt/u32g/jellyfin/cache:/cache
      ```
    - epg：
      - 登录：`[http://192.168.33.2/epg/manage.php](http://192.168.33.2/epg/manage.php)`
      - DIYP使用的链接：`[http://192.168.33.2/epg/index.php](http://192.168.33.2/epg/index.php)`
    - npm：`[http://192.168.33.7:81](http://192.168.33.7:81)`
      挂载点：
      ```
      /mnt/u32g/nginxproxymanager/data:/data
      /mnt/u32g/nginxproxymanager/letsencrypt:/etc/letsencrypt
      ```
    - tailscale: `192.168.88.2`
      环境变量：
      ```
      TS_ROUTES=192.168.0.0/16
      TS_EXTRA_ARGS=--advertise-exit-node --accept-routes --accept-dns=false
      TS_STATE_DIR=/var/lib/tailscale
      TS_AUTHKEY=tskey-auth-*
      PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
      ```
## 11、Shadowsocksr Plus+：来源=fw876/helloworld
1. 配置文件：`/etc/config/shadowsocksr`
2. 服务节点中“本地端口=1234”是代理的本地监听端口，将流量重定向到此端口即可实现访问走代理
3. “访问控制”下的“强制走代理的域名”是手工添加访问走代理的目标域名的地方，也就是`/etc/init.d/firewall_user`中使用blacklist IPSet集的数据来源

## 12、PassWall：来源=openwrt-passwall

## 13、KMS服务器：来源=lean/packages/net/vlmcsd & lean/luci/applications/luci-app-vlmcsd
1. 当PC使用OpenWrt的DNS时，可实现自动激活批量激活版的Windows和Office
2. 配置文件：`/etc/config/vlmcsd`

## 14、MJPG-streamer
1. Linux下的USB摄像头（UVC）的一个应用
2. 配置文件：`/etc/config/mjpg-streamer`

## 15、Phtunnel：来源= lean/packages/net/phtunnel
1. 花生壳的嵌入式版本
2. 配置文件：`/etc/config/phtunnel` 和 `/etc/phtunnel.json`

## 16、SmartDNS
1. 使用SmartDNS的主要目的是构建一个只进行IPv4解析的DNS服务器，解决使用IPv6访问异常的酷狗音乐TV版和Docker镜像拉取
2. 配置smartdns的上游DNS及禁用IPv6解析及监听端口5336
3. 配置文件：`/etc/config/smartdns`

## 17、uHTTPd
1. 启用https方式访问OpenWrt时使用的服务
2. 配置文件：`/etc/config/uhttpd`
3. 启用https时要配置https证书 `/etc/uhttpd.crt` 和私钥 `/etc/uhttpd.key`

## 18、链路层设备接口配置
1. 创建网桥并添加端口：
    - 网桥接口`br-lan`：端口`lan5`
    - 网桥接口`br-ke`：端口`lan2、lan3`
    - 网桥接口`br-shu`：端口`lan4`
    - 网桥接口`br-wlan`：端口`wlan21、wlan51`
    - 网桥接口`br-wan`：端口`eth1、lan1(for CNC)`
2. 网桥接口`br-lan、br-ke、br-shu、br-wan`启用`IGMP嗅探和多播支持`
3. 网桥接口`br-wan`：<mark>其端口eth1和lan1启用`始终多播路由`</mark>
4. 光猫不支持向LAN端添加静态路由，所以需要将光猫`LAN口`的掩码设置为`255.255.0.0`，这样的话，对光猫来说，OpenWrt路由器的各个网段将视为自己LAN口同网段，此时需要`OpenWrt开启arp代理功能`才可保证OpenWrt的各网段以路由转发方式和光猫通信：
    将下面配置添加到 `/etc/sysctl.conf`
    ```
    net.ipv4.conf.br-wan.proxy_arp=1
    net.ipv4.conf.all.arp_ignore=0
    net.ipv4.conf.eth1.arp_ignore=0
    ```
## 19、网络层接口配置
1. 创建三层接口：
    - `Lan`接口：`IP=192.168.199.1/24`
    - `Ke`接口：`IP=192.168.99.1/24`
    - `Shu`接口：`IP=192.168.9.1/24`
    - `Shu2`接口：`IP=192.168.91.1/24`
    - `Wlan`接口：`IP=192.168.69.1/24`
    - `Wan`接口：`IP=192.168.1.254/24`（提供DHCPv4 Server）
    - `wan6`接口：`dhcp6客户端`<mark>（当`wan接口提供DHCPv4 Server`时，`/etc/config/dhcp中wan6节一定不能有option ignore '1'`）</mark>
2. lan、ke、shu、wan的IPv6中继配置：
    - `wan`设置为`指定的主接口`
    - `lan、ke、shu、wan接口`的`RA服务`为`中继模式`、`NDP代理`为`中继模式`
    - `lan、ke、shu接口`的`DHCPv6服务`为`服务器模式`，`通告的 IPv6 DNS 服务器`设置为`接口的链路本地地址(fe80开头)`
    - `wan接口`的`DHCPv6服务`为`禁用`
3. `wan接口`的`使用自定义的 DNS 服务器`设置为：`127.0.0.1`；`wan6接口`的`使用自定义的 DNS 服务器`设置为：`::1`

## 20、配置无线
1. 2.4G和5G频段分别添加SSID为`OpenWrt`（使用空网桥）和`OpenWrt-FQ`（桥接到lan接口）的无线接入点
2. 接口的名称：
    - OpenWrt：wlan21和wlan51
    - OpenWrt-FQ：wlan22和wlan52
3. 接口的名称在`/etc/config/firewall_user`脚本中有使用

## 21、访问联通IPTV走联通光猫
1. 添加静态路由：wan接口到`10.0.0.0/8`下一跳`192.168.1.2`
2. 将指定终端重定向到爱快路由器：
```
config rule
option priority '6'
option src '192.168.69.217/32'
option lookup 'main'
option dest '192.168.0.0/16'
option in 'wlan'

config rule
option priority '9'
option src '192.168.69.217/32'
option lookup 'to_iKuaiRouter'
option dest '0.0.0.0/0'
option in 'wlan'

config rule
option dest '192.168.69.217/32'
option lookup 'main'
option priority '6'
option in 'wan'
option src '192.168.0.0/16'

config rule
option dest '192.168.69.217/32'
option lookup 'to_iKuaiRouter2'
option priority '9'
option in 'wan'
option src '0.0.0.0/0'

config route
option target '0.0.0.0/0'
option gateway '192.168.9.254'
option table 'to_iKuaiRouter'

config route
option target '0.0.0.0/0'
option gateway '192.168.91.254'
option table 'to_iKuaiRouter2'
```
## 22、DHCP/DNS配置
1. 设置全局转发：DNS=`222.88.88.88` & `114.114.114.114`
2. 设置部分域名转发到SmartDNS：
    - 酷狗相关域名：`*.kugou.com`、`*.kugou.net`、`*.kugou.com.wswebcdn.com`
    - Docker相关域名：`*.docker.com`、`*.docker.io`
3. 希沃相关域名解析使用腾讯DNS：
    ```
    list server '/*.cvte.com/119.29.29.29'
    list server '/*.seewo.com/119.29.29.29'
    list server '/*.qiniup.com/119.29.29.29'
    list server '/*.jikstatic.com/119.29.29.29'
    list server '/*.kunlunno.com/119.29.29.29'
    list server '/*.qlogo.cn/119.29.29.29'
    list server '/*.cvtestatic.com/119.29.29.29'
    list server '/*.qbox.me/119.29.29.29'
    ```
4. 设置静态地址分配：
    - SONY=`192.168.99.9`
    - NewTVBox=`192.168.9.9`
    - IPTV_shu=`192.168.9.99`
    - XiaoAi=`192.168.10.19`
    - Z6=`192.168.10.108`
    - L480=`192.168.199.202`
    - Dell=`192.168.99.8`
    - Z9=`192.168.69.217`
    - Z5Q=`192.168.69.218`
5. 设置主机名映射：`*.goho.co` 到 `192.168.199.1`
6. 设置SRV（`_vlmcs._tcp OpenWrt 1688 100`）
7. 配置文件：`/etc/config/dhcp`

## 23、配置防火墙
1. 为所有三层接口创建防火墙区域：`lan、ke、shu、wlan、wan、wan6`
2. 去掉`丢弃无效数据包`选项
3. 所有区域间通信不勾选`IP地址动态伪装`和`MSS钳制`

## 24、串口监控程序
涉及 `/etc/hostplus.d/usb/10-usb-device-hotplug` 及其中用到的 `/etc/config/sd2` 目录
