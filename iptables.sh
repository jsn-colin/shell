#!/bin/bash
#this script is iptables firewall setting


ipt=/sbin/iptables

#先备份原来的防火墙配置文件
function backup_old_filewall(){
    if  [ -f /etc/sysconfig/iptables.back.$(date +%y%m%d) ];then
        echo "yes"  
    else
        /bin/cp /etc/sysconfig/iptables  /etc/sysconfig/iptables.back.$(date +%y%m%d)
fi
}

#私有化部署服务需要放开的端口函数
function open_server(){
    declare -A server_port
    server_port=([accountauth]=20133
                 [accountauthgw]=21133
                 [aicloud]=20193
                 [aicloudgw]=21193
                 [bind]=20203
                 [bindgw]=21203
                 [clink]=22013,19335
                 [clinkgw]=23013
                 [comgateway]=20243
                 [comgatewaygw]=21243
                 [dbmanage]=28021,28023
                 [dbap]=28556
                 [dbproxy]=28546
                 [device]=20033
                 [devicegw]=21033
                 [devicenotice]=20063
                 [devicenoticegw]=21063
                 [groupcache]=20053
                 [groupcachegw]=21053
                 [idcache]=20013
                 [idstun]=20023
                 [managegwout]=27183
                 [natstun]=22023
                 [natstun_udp]=22024,22025,22026,22027
                 [payload]=20141,20143
                 [push]=20081,20083
                 [pushgw]=21083
                 [prepush]='无端口监听'
                 [tsgwout]=27083
                 [zone]=20183
                 [user]=20043
                 [usergw]=21043
                 [usernotice]=20073
                 [usernoticegw]=21073
                 [appletpush]=20281,20283
                 [appletpushgw]=21283
                 [httpcloud]=27051
	)

	#判断服务是natstun，则开放tcp和udp
	if [ $1 == 'natstun' ];then
	    $ipt -A INPUT -p tcp -m multiport --dport ${server_port[$1]} -j ACCEPT
	    $ipt -A INPUT -p udp -m multiport --dport ${server_port[${1}_udp]} -j ACCEPT
	elif [ $1 == 'prepush' ];then
	    continue
	else
	    $ipt -A INPUT -p tcp -m multiport --dport ${server_port[$1]} -j ACCEPT
	fi

}

#执行命令清除原来防火墙的配置
systemctl start iptables
$ipt -Z 
$ipt -X
$ipt -F

#配置允许ssh登录端口
$ipt -A INPUT -p tcp  -m multiport --dport 22,65022  -j ACCEPT
#设置允许lo 接口的流出和流入
$ipt -A INPUT -i lo -j ACCEPT
$ipt -A OUTPUT -o lo -j ACCEPT

#设置开启信任网段
$ipt -A INPUT -s 192.168.0.0/24 -p all -j ACCEPT

#设置icmp服务通过
$ipt -A INPUT -p icmp -j ACCEPT

#允许关联的状态包通过
$ipt -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT




########设置服务放开端口#######
server_list=(clink natstun)

for svc in ${server_list[@]}
    do
	    open_server ${svc}
    done

#mysql
$ipt -A INPUT -p tcp -m multiport --dport 3306,33060 -j ACCEPT
#apollo
$ipt -A INPUT -p tcp -m multiport --dport 28070,28080 -j ACCEPT

##############################

#设置禁止防火墙规则，output都为允许，forward和input都默认drop
$ipt -A OUTPUT -j ACCEPT 
$ipt -A INPUT -j DROP  
$ipt -A FORWARD -j DROP 

#将配置永久保存
/usr/sbin/iptables-save
