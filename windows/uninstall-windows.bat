@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo S-UI Windows 卸载程序
echo ========================================

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 错误：必须以管理员身份运行此脚本。
    echo 请右键单击文件并选择“以管理员身份运行”。
    pause
    exit /b 1
)

REM Set installation directory
set "INSTALL_DIR=C:\Program Files\s-ui"
set "SERVICE_NAME=s-ui"

echo 正在从以下目录卸载 S-UI：%INSTALL_DIR%

REM Stop and remove Windows Service
if exist "%INSTALL_DIR%\s-ui-service.exe" (
    echo 正在停止并删除 Windows 服务...
    net stop %SERVICE_NAME% >nul 2>&1
    cd /d "%INSTALL_DIR%"
    s-ui-service.exe uninstall >nul 2>&1
    if %errorLevel% equ 0 (
        echo 服务删除成功。
    ) else (
        echo 警告：服务删除失败或服务尚未安装。
    )
)

REM Remove desktop shortcut
echo 正在删除桌面快捷方式...
set "DESKTOP=%USERPROFILE%\Desktop"
if exist "%DESKTOP%\S-UI.lnk" (
    del "%DESKTOP%\S-UI.lnk" >nul 2>&1
    echo 桌面快捷方式已删除。
)

REM Remove Start Menu shortcut
echo 正在删除开始菜单快捷方式...
set "START_MENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs\S-UI"
if exist "%START_MENU%" (
    rmdir /s /q "%START_MENU%" >nul 2>&1
    echo 开始菜单快捷方式已删除。
)

REM Remove environment variable
echo 正在删除环境变量...
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v SUI_HOME /f >nul 2>&1

REM Ask user if they want to keep data
echo.
set /p keep_data="是否保留数据库、日志和证书？[y/n]："
if /i "%keep_data%"=="y" (
    echo 正在保留数据文件...
    REM Remove only executable and service files
    if exist "%INSTALL_DIR%\sui.exe" del "%INSTALL_DIR%\sui.exe" >nul 2>&1
    if exist "%INSTALL_DIR%\s-ui-service.exe" del "%INSTALL_DIR%\s-ui-service.exe" >nul 2>&1
    if exist "%INSTALL_DIR%\s-ui-service.xml" del "%INSTALL_DIR%\s-ui-service.xml" >nul 2>&1
    if exist "%INSTALL_DIR%\winsw.exe" del "%INSTALL_DIR%\winsw.exe" >nul 2>&1
    if exist "%INSTALL_DIR%\*.bat" del "%INSTALL_DIR%\*.bat" >nul 2>&1
    if exist "%INSTALL_DIR%\*.xml" del "%INSTALL_DIR%\*.xml" >nul 2>&1
    if exist "%INSTALL_DIR%\*.md" del "%INSTALL_DIR%\*.md" >nul 2>&1
    echo 数据文件已保留在：%INSTALL_DIR%
) else (
    echo 正在删除全部文件...
    REM Remove entire installation directory
    if exist "%INSTALL_DIR%" (
        rmdir /s /q "%INSTALL_DIR%" >nul 2>&1
        if exist "%INSTALL_DIR%" (
            echo 警告：部分文件无法删除，请手动删除：%INSTALL_DIR%
        ) else (
            echo 全部文件已删除。
        )
    )
)

REM Remove firewall rules
echo 正在删除防火墙规则...
netsh advfirewall firewall delete rule name="S-UI Panel" >nul 2>&1
netsh advfirewall firewall delete rule name="S-UI Subscription" >nul 2>&1

echo.
echo ========================================
echo 卸载完成！
echo ========================================
echo.
echo S-UI 已从系统中卸载。
echo.
if /i "%keep_data%"=="y" (
    echo 数据已保留在：%INSTALL_DIR%
    echo 不再需要数据时可手动删除该目录。
)
echo.
echo 感谢使用 S-UI！
echo.
pause
