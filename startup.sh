#!/bin/bash

listen_port="8080"  
process_name="jenkins.war"
process_log="./jenkins.log"
work_dir="/app/jenkins"
process_cmd="java -jar ${work_dir}/jenkins.war  -Duser.timezone=Asia/Shanghai --httpPort=8080"

###JAVA_HOME
#export JAVA_HOME=/usr/local/jdk1.8.0_202/
#export PATH=$PATH:$JAVA_HOME/bin
#export CLASSPATH=.:$JAVA_HOME/lib/tools.jar:$JAVA_HOME/lib/dt.jar:$CLASSPATH

###JENKINS_HOME,这里可以取消，这个变量在dockerfile的ENV中指定了
#export JENKINS_HOME=/app/data/.jenkins

###################################################

function checkargs()
{
    # 判断${listen_port}是否存在
    if [[ ${listen_port} == '' ]];then
        echo -e "${YELLOW}listen_port is None ${NC}"
    fi
    
    # 判断${work_dir}是否存在
    if [[ ! -d ${work_dir} ]];then
        echo -e "${YELLOW}work_dir is not define ${NC}"
    fi
    
    # 判断${process_log}是否存在
    if [[ ${process_log} == '' ]];then
        process_log="/dev/null"
    fi
}


function get_pid()
{
    PID=$(ps -ef | grep ${process_name} | grep -v grep | awk '{print $1}')
}

function check_work_dir()
{
    if [[ ${work_dir} != '' ]];then
        if [[ ! -d ${work_dir} ]];then
            echo -e "work directory is not exist: ${YELLOW}${work_dir}${NC}"
        fi
    fi
}

function checkport()
{
    if [[ ${listen_port} != '' ]];then
        get_pid
        netstat -antlu | grep ":${listen_port}" | grep LISTEN >/dev/null 2>&1
    else
        echo "listen port is None"
        return 1
    fi
}


function stop_process()
{
# 获取pid
get_pid
if [[ $PID == '' ]];then
    echo -e "${YELLOW}${process_name} is not Runing!!!${NC}"
else
    if kill -15 "$PID";then
        echo "kill -15 $PID" >> ${process_log}
        printf "%-${WIDTH}s" "${process_name} to stopping !!!" && echo -e "[ ${GREEN}OK${NC} ]"
        while true
        do
            sleep 1
            get_pid
            if [[ $PID == '' ]];then
                printf "%-${WIDTH}s" "${process_name} has stopped !!!" && echo -e "[ ${GREEN}OK${NC} ]"
                break # 需要使用break，而不能使用exit，因为exit，restart动作的start就不能执行
            fi
        done

    else
        printf "%-${WIDTH}s" "${process_name} to stopping !!!" && echo -e "[ ${RED}Faild${NC} ]"
        return 1
    fi
fi
}

function halt_process()
{
# 获取pid
get_pid
if [[ $PID == '' ]];then
    echo -e "${YELLOW}${process_name} is not Runing!!!${NC}"
else
    if kill -9 "${PID}";then
        echo "kill -9 ${PID}" >> ${process_log} 
        printf "%-${WIDTH}s" "${process_name} to stopping !!!" && echo -e "[ ${GREEN}OK${NC} ]"
        while true
        do
            sleep 1
            get_pid
            if [[ $PID == '' ]];then
                printf "%-${WIDTH}s" "${process_name} has stopped !!!" && echo -e "[ ${GREEN}OK${NC} ]"
                break # 需要使用break，而不能使用exit，因为exit，restart动作的start就不能执行
            fi
        done

    else
        printf "%${WIDTH}s" "${process_name} to stopping !!!" && echo -e "[ ${RED}Faild${NC} ]"
        return 1
    fi
fi
}

function start_process()
{
    check_work_dir
    get_pid
    if [[ $PID != "" ]];then
        echo -e "${YELLOW}${process_name} is alread Runing!!!       [ pid: $PID ]${NC}"
    else
        printf "%-${WIDTH}s" "${process_name} to starting !!!" && echo -e "[ ${GREEN}OK${NC} ]"
        # 切换到工作目录，执行
        cd ${work_dir} ;
        echo "$(date "+%Y/%m/%d %H:%M:%S") started ${process_cmd}" >> ${process_log} 
        nohup ${process_cmd} >> ${process_log} 2>&1  &  # 注意： 该行变量不能加引号，加了无法正常工作
        sleep 1 ; get_pid
        if [[ $PID != "" ]];then
            printf "%-${WIDTH}s" "[ $! ] ${process_name} has started !!!" && echo -e "[ ${GREEN}OK${NC} ]"
        else
            printf "%-${WIDTH}s" "${process_name} to starting !!!" && echo -e "[ ${RED}Failed${NC} ]"
            return 1
        fi
    fi
}

function restart()
{
get_pid
if [[ $PID == "" ]];then
    echo -e "${YELLOW}${process_name} is not Runing!!!${NC}"
    start_process
else
    stop_process && start_process
fi
}

function reboot()
{
get_pid
if [[ $PID == "" ]];then
    echo -e "${YELLOW}${process_name} is not Runing!!!${NC}"
    start_process
else
    halt_process && start_process
fi
}

function status_process()
{
    process_result=$(ps -ef | grep ${process_name} | grep -v grep)

    if [[ ${process_result} == "" ]];then
        echo -e "${YELLOW}${process_name} is not Runing!!!${NC}"
        exit 1
    else
        checkport
        if checkport;then
            port_status="${GREEN}OK${NC}"
        else
            port_status="${RED}Failed${NC}"
        fi

        num=$(ps -ef | grep ${process_name} | grep -vc grep )
        echo ""
        echo "${process_result}"
        echo ""
        echo -e "process ${process_name} is Runing , 进程数: [ ${GREEN}${num}${NC} ] , port:[ ${GREEN}${listen_port}${NC} ] is listening [ ${port_status} ]"
        echo ""
        echo ""
    fi
}

function check_port()
{
num=1
while true
do
    checkport
    if checkport;then
        echo "check [ ${listen_port} ] is listening !!!"
        exit 0
    else
        echo "sleep ${num} 's"
        num=$(($num+1))
        sleep 1
    fi
done
}

function watch_dog(){
    check_port
    if checkport;then
        echo "Port [${listen_port}] is listenging"
        exit 0
    else
        echo "端口未监听【${listen_port}】"
        exit1
    fi
}

function usage()
{
cat << EOF
$0 Version 1.0.1
date: 07/29/2021

    -h, --help             显示本页信息
    start                  启动服务
    stop                   停止服务 (等于kill -15)
    restart                重启服务 （等于 stop + start）
    reboot                 重启服务 （强制重启，等于 halt + start）
    status                 查看服务状态
    halt                   强制停止服务 (等于kill -9)
    checkport              检查服务端口是否监听
    
example:
    $0 start|stop|restart|status|halt|checkport

EOF
}

# 定义颜色, 对齐的宽度
RED="\033[31m"
YELLOW="\033[33m"
GREEN="\033[32m"
NC="\033[0m"
WIDTH=60


# main
checkargs
if [[ $1 == "stop" ]];then
    stop_process

elif [[ $1 == "halt" ]];then
    halt_process

elif [[ $1 == "start" ]];then
    start_process

elif [[ $1 == "restart" ]];then
    restart

elif [[ $1 == "reboot" ]];then
    reboot

elif [[ $1 == "status" ]];then
    status_process

elif [[ $1 == "checkport" ]];then
    check_port

elif [[ $1 == "watchdog" ]];then
    watch_dog

elif [[ $1 == "-h" || $1 == "" || $1 == "--help" ]];then
    usage

else
    echo -e "${RED}\"$*\" paramters unkonw${NC}"
fi
