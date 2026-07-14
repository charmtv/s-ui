@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

echo ========================================
echo S-UI Windows 安装程序
echo ========================================

REM Check if running as Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo 错误：必须以管理员身份运行此脚本。
    echo 请右键单击文件并选择“以管理员身份运行”。
    pause
    exit /b 1
)

cd /d "%~dp0"
REM Set installation directory
set "INSTALL_DIR=C:\Program Files\s-ui"
set "SERVICE_NAME=s-ui"

echo S-UI 安装目录：%INSTALL_DIR%

REM Create installation directory
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
if not exist "%INSTALL_DIR%\db" mkdir "%INSTALL_DIR%\db"
if not exist "%INSTALL_DIR%\logs" mkdir "%INSTALL_DIR%\logs"
if not exist "%INSTALL_DIR%\cert" mkdir "%INSTALL_DIR%\cert"

REM Copy files
echo 正在复制文件...
copy "sui.exe" "%INSTALL_DIR%\" >nul
copy "s-ui-windows.xml" "%INSTALL_DIR%\" >nul
copy "s-ui-windows.bat" "%INSTALL_DIR%\" >nul

REM Check if WinSW is available
set "WINSW_PATH=%INSTALL_DIR%\winsw.exe"
if not exist "%WINSW_PATH%" (
    echo 正在下载 WinSW...
    powershell -Command "& {Invoke-WebRequest -Uri 'https://github.com/winsw/winsw/releases/download/v2.12.0/WinSW-x64.exe' -OutFile '%WINSW_PATH%'}"
    if exist "%WINSW_PATH%" (
        echo WinSW 下载成功。
    ) else (
        echo 警告：WinSW 下载失败，将跳过服务安装。
        echo 可手动下载：https://github.com/winsw/winsw/releases
    )
)

REM Install Windows Service
if exist "%WINSW_PATH%" (
    echo 正在安装 Windows 服务...
    cd /d "%INSTALL_DIR%"
    copy "winsw.exe" "s-ui-service.exe" >nul
    copy "s-ui-windows.xml" "s-ui-service.xml" >nul
        
    REM Install service
    s-ui-service.exe install
    if %errorLevel% equ 0 (
        echo 服务安装成功。
    ) else (
        echo 警告：服务安装失败，可稍后手动安装。
    )
)

REM Run migration
echo 正在迁移数据库...
cd /d "%INSTALL_DIR%"
sui.exe migrate
if %errorLevel% equ 0 (
    echo 数据库迁移完成。
) else (
    echo 提示：迁移未执行或当前为新数据库。
)

REM Get network configuration
echo.
echo ========================================
echo 网络配置
echo ========================================

REM Get local IP addresses
echo 可用 IP 地址：
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    echo   %%i
)

REM Get panel configuration
echo.
set /p panel_port="请输入面板端口（默认 2095）："
if "%panel_port%"=="" set "panel_port=2095"

set /p panel_path="请输入面板路径（默认 /app/）："
if "%panel_path%"=="" set "panel_path=/app/"

set /p sub_port="请输入订阅端口（默认 2096）："
if "%sub_port%"=="" set "sub_port=2096"

set /p sub_path="请输入订阅路径（默认 /sub/）："
if "%sub_path%"=="" set "sub_path=/sub/"

REM Apply settings
echo.
echo 正在应用设置...
cd /d "%INSTALL_DIR%"
sui.exe setting -port %panel_port% -path "%panel_path%" -subPort %sub_port% -subPath "%sub_path%"

REM Get admin credentials
echo.
echo ========================================
echo 管理员配置
echo ========================================

set /p admin_username="请输入管理员账号（默认 admin）："
if "%admin_username%"=="" set "admin_username=admin"

set /p admin_password="请输入管理员密码："
if "%admin_password%"=="" (
    echo 错误：密码不能为空。
    pause
    exit /b 1
)

REM Set admin credentials
echo 正在设置管理员信息...
sui.exe admin -username "%admin_username%" -password "%admin_password%"

REM Start service
echo 正在启动 S-UI 服务...
net start %SERVICE_NAME%
if %errorLevel% equ 0 (
    echo 服务启动成功。
) else (
    echo 警告：服务启动失败，可稍后手动启动。
)

REM Create desktop shortcut
echo 正在创建桌面快捷方式...
set "DESKTOP=%USERPROFILE%\Desktop"
if exist "%DESKTOP%" (
    powershell -Command "& {$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%DESKTOP%\S-UI.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\s-ui-windows.bat'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'S-UI Control Panel'; $Shortcut.Save()}"
    echo 桌面快捷方式已创建。
)

REM Create Start Menu shortcut
echo 正在创建开始菜单快捷方式...
set "START_MENU=%APPDATA%\Microsoft\Windows\Start Menu\Programs"
if exist "%START_MENU%" (
    if not exist "%START_MENU%\S-UI" mkdir "%START_MENU%\S-UI"
    powershell -Command "& {$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%START_MENU%\S-UI\S-UI Control Panel.lnk'); $Shortcut.TargetPath = '%INSTALL_DIR%\s-ui-windows.bat'; $Shortcut.WorkingDirectory = '%INSTALL_DIR%'; $Shortcut.Description = 'S-UI Control Panel'; $Shortcut.Save()}"
    echo 开始菜单快捷方式已创建。
)

REM Set permissions
echo 正在设置目录权限...
icacls "%INSTALL_DIR%" /grant "Users:(OI)(CI)RX" /T >nul
icacls "%INSTALL_DIR%\db" /grant "Users:(OI)(CI)F" /T >nul
icacls "%INSTALL_DIR%\logs" /grant "Users:(OI)(CI)F" /T >nul

REM Create environment variable
echo 正在设置环境变量...
setx SUI_HOME "%INSTALL_DIR%" /M >nul

REM Show final configuration
echo.
echo ========================================
echo 安装完成！
echo ========================================
echo.
echo S-UI 已安装到：%INSTALL_DIR%
echo.
echo 当前配置：
echo   面板端口：%panel_port%
echo   面板路径：%panel_path%
echo   订阅端口：%sub_port%
echo   订阅路径：%sub_path%
echo   管理员账号：%admin_username%
echo.
echo 访问地址：
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    set "ip=%%i"
    set "ip=!ip: =!"
    echo   面板：http://!ip!:%panel_port%%panel_path%
    echo   订阅：http://!ip!:%sub_port%%sub_path%
)
echo.
echo 服务名称：%SERVICE_NAME%
echo.
echo 常用命令：
echo   net start %SERVICE_NAME%    - 启动服务
echo   net stop %SERVICE_NAME%     - 停止服务
echo   sc query %SERVICE_NAME%     - 查看服务状态
echo.
echo 也可以通过桌面或开始菜单快捷方式打开管理面板。
echo.
pause
