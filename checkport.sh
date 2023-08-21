#!/bin/bash

# autor:colin
# email:740391452@qq.com

# telnet的超时退出时间
TMOUT=3
# 格式对齐的宽度
WIDTH=35
# 默认的线程数
thread=1

# 检查是否安装telnet
function check_cmd(){
if [[ ! -x $(which ${1}) ]];then
    echo "请安装: ${1}"
    exit 1
fi
}

function check_port()
{
    # 传入这个函数的参数是固定的，必须是 ip:port
    ip=$(echo $1 | cut -d ":" -f 1)
    port=$(echo $1 | cut -d ":" -f 2)

    rcode=$(echo -e "\n" |timeout --signal=9 $TMOUT  telnet $ip $port  2> /dev/null | grep Connected | wc -l )


    if [[ $rcode -eq 1 ]];then
        lenth=$(echo ${ip}:${port} | wc -L)
        space_num=$((${WIDTH} - ${lenth}))
        space=' '
        sp=''
        for i in $(seq ${space_num})
            do
                sp="${sp}${space}"
            done
        trap "myexit;" INT TERM
        echo -e "${ip}:${port}${sp}${GREEN}Done${NC}" 2>/dev/null
    else
        lenth=$(echo ${ip}:${port} | wc -L)
        space_num=$((${WIDTH} - ${lenth}))
        space=' '
        sp=''
        for i in $(seq ${space_num})
            do
                sp="${sp}${space}"
            done
        trap "myexit;" INT TERM
        echo -e "${ip}:${port}${sp}${RED}Fail${NC}" 2>/dev/null
    fi
}


function get_ip_port_list(){
    # check_net 192.168.1.1/30 80
    if [[ ${2} == "" ]];then
        localport=$(echo $1 | cut -d ':' -f 2)
    else
        localport=${2}
    fi
    rcode=$(echo ${1} | grep "/" 2>/dev/null)
    if [[ ${rcode} == '' ]];then
        ip=$(echo $1 | cut -d ':' -f 1)
        ip_port_list="${ip_port_list} ${ip}:${localport}"
    else
        # 192.167.1.1/31:80 80
        net_mask=$(echo $1 | cut -d ':' -f 1)
        NETMASK=$(echo ${net_mask} | cut -d "/" -f 2)  # 通配符掩码
        RMASK=$((32 - $NETMASK))              # 反掩码
        let "HOSTS_NUM=2**$RMASK"             # 网段主机数

        NET=$(echo ${net_mask} | cut -d "/" -f 1)      # 传入的ip地址
        NET_4=$(echo $NET | cut -d "." -f 4)
        YUSHU=$((NET_4 % $HOSTS_NUM))
        NET_4=$(($NET_4 - $YUSHU))            # ip地址第四段的网络位（该网段的起始地址）

        NET1_3=$(echo $NET | cut -d '.' -f 1-3)

        BOST_4=$(($NET_4 + $HOSTS_NUM))

        for i in $(seq $NET_4 $BOST_4)
            do
                ip_port_list="${ip_port_list} ${NET1_3}.${i}:${localport}"
            done
    fi
}

function get_port_list(){
    pass
}

function thread_process(){
    tempfifo="checkport_thread.fifo"
    mkfifo ${tempfifo}
    exec 6<> ${tempfifo}
    rm -rf ${tempfifo}

    for ((i=1; i<=${thread}; i++))
    do
        echo
    done >&6
}

function myexit(){
    exec 6>&-
    exit 0
    # exit

}

function usage()
{
   cat << EOF
   $0 Version: 1.1.0

    -h     显示本页信息
    -s     指定目的地址       可以是单个地址，可以是地址段，最大支持一个C类地址，格式 "192.168.1.0/24"
    -p     指定目的端口       1-65535
    -f     指定文件路径       一行一条记录，格式 "192.168.1.1:80"
    -t     指定超时时间       默认：3s
    -T     运行的线程数       默认：单进程

   example:
       $0 -s 192.168.1.8:80
       $0 -s 192.168.1.8 -p 80
       $0 -s 192.168.1.8/30 -p 80
       $0 -f checkport.txt

EOF
}


if [[ $1 == '' ]];then
    usage
    exit 0
fi

while getopts ':f:s:p:t:T:h' opt
    do
        case $opt in
            f)
             iplist=$OPTARG
            ;;
            s)
             dip=$OPTARG
            ;;
            p)
             port=$OPTARG
            ;;
            t)
             TMOUT=$OPTARG
            ;;
            T)
             thread=$OPTARG
            ;;
            h)
             usage
               exit 0
            ;;
            ?)
             echo "未知参数"
             exit 1
        exit 1;;
        esac
    done
# 定义提示颜色
RED="\033[31m"
GREEN="\033[32m"
NC="\033[0m"

#初始化一个空列表
ip_port_list=''
# main
check_cmd telnet

function get_port_list(){
    port_list=''
            port1=$(expr ${1} / 1  2>&1 > /dev/null)
            if [[ ${port1} = ${1} ]];then
        echo ${1}
        return
    else
        start_port=$(echo ${1} | awk -F- '{print $1}')
        stop_port=$(echo ${1} | awk -F- '{print $2}')

        while [[ ${stop_port} -ge ${start_port} ]]
            do
                port_list="${port_list} ${start_port}"
                start_port=$(expr ${start_port} + 1)
            done
    fi
    echo ${port_list}
}

ports=$(get_port_list ${port} )

# 将-s 指定的ip地址加入ip_port_list的列表中
if [[ ${dip} != '' ]];then
    for port in ${ports}
        do
            get_ip_port_list $dip ${port}
        done
fi
# 将-f 指定的文件中的地址和地址段加入ip_port_list的列表中

if [[ ${iplist} != '' ]];then
    for i in $(cat ${iplist} | grep -v '#' | grep -v '^\s*$')
        do
            ip=$(echo ${i} | awk '{print $1}')
            for port in ${ports}
                do
                    get_ip_port_list ${ip} ${port}
                done
        done
fi


# 如果不使用多进程，则不创建fifo文件
if [[ ${thread} == 1 ]];then
    for ip_port in ${ip_port_list}
    do
        check_port ${ip_port}
    done
else
    thread_process
    for ip_port in ${ip_port_list}
        do
            {
                read -u6
                {
                    check_port ${ip_port}
                    echo "" >&6
                } &
            }
        done
        wait
fi
myexit
