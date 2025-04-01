@echo off
:: Author: 旧事凝
:: 定义本地网卡和无线网卡名称

:: 设置代码页为 UTF-8
chcp 65001 >nul

setlocal DisableDelayedExpansion
set local_lan=以太网
set local_wlan=wlan

:: 检查是否以管理员身份运行
fltmc >nul 2>&1 || (
    echo 此脚本需要管理员权限.
    echo 正在尝试以管理员身份重新运行...
    PowerShell Start-Process "%~f0" -Verb RunAs
    exit /b
)

echo 快速设置windows电脑的ip地址
set /p interface="设置无线网卡还是本地网卡(w/l): "
set "interface=%interface: =%"  :: 清除输入值中的空格

:: 根据用户输入选择网络接口
if "%interface%"=="w" set "current_interface=%local_wlan%"
if "%interface%"=="l" set "current_interface=%local_lan%"

:: 如果用户输入无效，退出脚本
if not defined current_interface (
    echo 无效的选择，请输入 w 或 l！
    pause
    exit /b
)

if "%interface%"=="w" goto WLAN
if "%interface%"=="l" goto LOCAL

:LOCAL
    echo 本地网卡设置中...
    set /p protocl="设置自动获取还是静态地址(d/s/home): "
    if "%protocl%"=="d" goto dhcp
    if "%protocl%"=="s" goto static
    if "%protocl%"=="home" goto home

    :: 默认分支：捕获无效输入
    echo 无效的选择，请重新运行脚本！
    pause
    exit /b

:static
    echo 静态地址设置中...
    set /p ip_address="请输入ip地址: "
    set /p netmask="请输入子网掩码（点分十进制）: "
    set /p gateway="请输网关: "
    netsh interface ip set address %current_interface% static %ip_address% %netmask% %gateway%
    if %errorlevel% neq 0 (
        echo 配置失败，请检查网络接口名称或权限。
        pause
        exit /b
    )
    set /p dns="请输入dns地址: "
    if "%dns%"=="" goto nx
    netsh interface ip set dns %current_interface% static %dns%
    goto end

:nx
    netsh interface ip set dns %current_interface% static 114.114.114.114
    goto end

:dhcp
    echo 自动获取IP地址和DNS...
    netsh interface ip set address %current_interface% dhcp
    netsh interface ip set dns %current_interface% dhcp
    goto end

:home
    echo 正在配置home静态地址...
    netsh interface ip set address %current_interface% static 192.168.1.10 255.255.255.0 192.168.1.1
    if %errorlevel% neq 0 (
        echo 配置失败，请检查网络接口名称或权限。
        pause
        exit /b
    )
    goto end


:WLAN
    echo 无线网卡设置中...
    set /p protocl="设置自动获取还是静态地址(d/s/nt/nb): "
    if "%protocl%"=="d" goto dhcp
    if "%protocl%"=="s" goto static
    if "%protocl%"=="nt" goto nt
    if "%protocl%"=="nb" goto nb

    :: 默认分支：捕获无效输入
    echo 无效的选择，请重新运行脚本！
    pause
    exit /b

:end
echo 配置完成！
pause
exit 0
