# 指定接口禁用IPv6：Wireless Interface Forbid IPv6
ebtables -I FORWARD -o wlan21 -p ipv6 -j DROP
ebtables -I FORWARD -o wlan22 -p ipv6 -j DROP
ebtables -I FORWARD -o wlan51 -p ipv6 -j DROP
ebtables -I FORWARD -o wlan52 -p ipv6 -j DROP
ebtables -I FORWARD -o lan2 -p ipv6 -j DROP
#ebtables -I FORWARD -o lan4 -p ipv6 -j DROP

ebtables -I INPUT -i wlan21 -p ipv6 -j DROP
ebtables -I INPUT -i wlan22 -p ipv6 -j DROP
ebtables -I INPUT -i wlan51 -p ipv6 -j DROP
ebtables -I INPUT -i wlan52 -p ipv6 -j DROP
ebtables -I INPUT -i lan2 -p ipv6 -j DROP
#ebtables -I INPUT -i lan4 -p ipv6 -j DROP

ebtables -I OUTPUT -o wlan21 -p ipv6 -j DROP
ebtables -I OUTPUT -o wlan22 -p ipv6 -j DROP
ebtables -I OUTPUT -o wlan51 -p ipv6 -j DROP
ebtables -I OUTPUT -o wlan52 -p ipv6 -j DROP
ebtables -I OUTPUT -o lan2 -p ipv6 -j DROP
#ebtables -I OUTPUT -o lan4 -p ipv6 -j DROP


# 跨网段视频投屏：SSDP Cross-Subnet Screen Mirroring
iptables -t mangle -A PREROUTING -i br-lan -s 192.168.199.0/24 -d 239.255.255.250/32 -p udp --dport 1900 -m comment --comment "by_firewall_user" -j TEE --gateway 192.168.99.255


# 电话手表和戴尔电脑定时断网：ACL for Z5Q&DELL
iptables -I FORWARD 1 -s 192.168.99.8 -m time --kerneltz --timestart 22:00:00 --timestop 07:00:00 -m comment --comment "by_firewall_user" -j DROP
iptables -I FORWARD 1 -s 192.168.69.218 -m time --kerneltz --timestart 22:00:00 --timestop 07:00:00 -m comment --comment "by_firewall_user" -j DROP


#手工添加源IP访问指定网络使用代理：Allow Proxy Access for Domain blacklist
#iptables -t nat -A PREROUTING -s 192.168.33.3/32 -m set --match-set blacklist dst -p tcp -m comment --comment "by_firewall_user_docker" -j DNAT --to-destination 192.168.199.1:1234
#iptables -t nat -A PREROUTING -s 192.168.33.3/32 -m set --match-set blacklist dst -p tcp -m comment --comment "by_firewall_user_docker" -j REDIRECT --to-port 1041


#允许两个网段通过代理访问epglist（在/etc/init.d/ipset_user里创建，在“网络-DHCP/DNS-IP集”里添加）：Allow Proxy Access for Domain epglist
#iptables -t nat -A PREROUTING -s 192.168.9.0/24 -m set --match-set blacklist dst -p tcp --dport 443 -m comment --comment "by_firewall_user_epgshu" -j DNAT --to-destination 192.168.199.1:1234
#iptables -t nat -A PREROUTING -s 192.168.99.0/24 -m set --match-set blacklist dst -p tcp --dport 443 -m comment --comment "by_firewall_user_epgke" -j DNAT --to-destination 192.168.199.1:1234
iptables -t nat -A PREROUTING -s 192.168.9.0/24 -m set --match-set epglist dst -p tcp --dport 443 -m comment --comment "by_firewall_user_epgshu" -j REDIRECT --to-port 1041
iptables -t nat -A PREROUTING -s 192.168.99.0/24 -m set --match-set epglist dst -p tcp --dport 443 -m comment --comment "by_firewall_user_epgke" -j REDIRECT --to-port 1041


#Docker网络默认SNAT，删除，注意修改 -o 接口名称：Remove SNAT from Docker Bridge Network
iptables -t nat -D POSTROUTING -s 192.168.66.0/24 ! -o docker0 -j MASQUERADE
iptables -t nat -D POSTROUTING -s 192.168.33.0/24 ! -o br-c801e2b1b336 -j MASQUERADE
#iptables -t nat -D POSTROUTING -s 192.168.88.0/24 ! -o br-0b8fb4db26fb -j MASQUERADE

#特定终端（L480笔记本有线网卡）DNS重定向
# iptables -t nat -A PREROUTING -s 192.168.69.199/32 -p tcp --dport 53 -m comment --comment "by_firewall_user_dnsredirect" -j REDIRECT --to-port 5336
# iptables -t nat -A PREROUTING -s 192.168.69.199/32 -p udp --dport 53 -m comment --comment "by_firewall_user_dnsredirect" -j REDIRECT --to-port 5336
