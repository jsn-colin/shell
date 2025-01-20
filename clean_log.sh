#!/bin/bash

########配置参数########
LogPath='/data/logs' 
LogName='*.log'
# 单位GB
MaxSize=80
########################

function clean_log()
{
    file_list=$(find ${LogPath} -type f -name "${LogName}" )  # $file_list是'1 2 3 4 5' 形式的列表

    # 对${file_list}判断是否为空，不为空则按照ctime反向顺序排列（从远到近），为空则退出
    if [[ ${file_list} == '' ]];then
        echo "没有符合清理规则的文件，退出"
        exit 2
    fi

    rm_file=$(echo ${file_list} | xargs ls -rtc)
    for i in ${rm_file}
    do
        # 判断文件是否被占用，如果被占用则放弃操作，否则删除
        lsof ${i} >/dev/null 2>&1 # $? 0表示被占用，1表示未被占用
        if [[ $? -eq 0 ]];then
            echo "[ ${i} ] 正在被占用，停止处理！"
            continue  # continue跳过不可删除的。

        elif [[ $? -eq 1 ]];then
            echo "--------------------------------->"
            echo "清理文件 [ ${i} ]"
            rm -rf ${i}
            break  # break掉for循环，只处理第一个文件后就需要判断容量是否符合限定
        else
            echo "无法判断该文件是否被占用，停止处理"
            continue  # continue跳过不可删除的。
        fi
    done
}

function main()
{

    while true
        do
            current_size_mb=$(du -sm ${LogPath} |awk '{print $1}')
            echo "${LogPath}当前使用：${current_size_mb} /MB"
            if [[ $current_size_mb -gt $max_size_mb ]];then
                    clean_log
            else
                    echo -e "无需清理\n"
                    exit 1
            fi
            sleep 2
    
        done
}

max_size_mb=$(echo "${MaxSize} * 1024" | bc | cut -d '.' -f 1)
t1_current_size_mb=$(du -sm ${LogPath} |awk '{print $1}')

if [[ ${t1_current_size_mb} -gt ${max_size_mb} ]];then
    echo "--------------------------------->"
    echo $(date "+%Y-%m-%d %H:%M:%S")
    echo "${LogPath}限制为: ${max_size_mb} /MB"
    main
else
    exit 1
fi
