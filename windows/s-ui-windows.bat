@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM S-UI Windows 管理脚本

cd /d "%~dp0"
set "SERVICE_NAME=s-ui"
set "INSTALL_DIR=%SUI_HOME%"
if "%INSTALL_DIR%"=="" set "INSTALL_DIR=C:\Program Files\s-ui"

:menu
cls
echo ========================================
echo S-UI Windows 管理面板
echo ========================================
echo.
echo 安装目录：%INSTALL_DIR%
echo.
echo 1. 启动 S-UI 服务
echo 2. 停止 S-UI 服务
echo 3. 重启 S-UI 服务
echo 4. 查看服务状态
echo 5. 查看服务日志
echo 6. 在浏览器中打开面板
echo 7. 手动运行 S-UI
echo 8. 安装或卸载服务
echo 9. 打开安装目录
echo 10. 查看配置
echo 11. 查看访问地址
echo 0. 退出
echo.
echo ========================================

set /p choice="请选择 [0-11]："

if "%choice%"=="1" goto start_service
if "%choice%"=="2" goto stop_service
if "%choice%"=="3" goto restart_service
if "%choice%"=="4" goto check_status
if "%choice%"=="5" goto view_logs
if "%choice%"=="6" goto open_panel
if "%choice%"=="7" goto run_manual
if "%choice%"=="8" goto service_management
if "%choice%"=="9" goto open_directory
if "%choice%"=="10" goto show_config
if "%choice%"=="11" goto show_urls
if "%choice%"=="0" goto exit
goto invalid_choice

:start_service
echo 正在启动 S-UI 服务...
net start %SERVICE_NAME%
if %errorLevel% equ 0 (
    echo 服务启动成功！
) else (
    echo 服务启动失败，错误代码：%errorLevel%
)
pause
goto menu

:stop_service
echo 正在停止 S-UI 服务...
net stop %SERVICE_NAME%
if %errorLevel% equ 0 (
    echo 服务停止成功！
) else (
    echo 服务停止失败，错误代码：%errorLevel%
)
pause
goto menu

:restart_service
echo 正在重启 S-UI 服务...
net stop %SERVICE_NAME% >nul 2>&1
timeout /t 2 /nobreak >nul
net start %SERVICE_NAME%
if %errorLevel% equ 0 (
    echo 服务重启成功！
) else (
    echo 服务重启失败，错误代码：%errorLevel%
)
pause
goto menu

:check_status
echo 正在检查 S-UI 服务状态...
sc query %SERVICE_NAME%
echo.
echo 服务状态详情：
for /f "tokens=3 delims=: " %%i in ('sc query %SERVICE_NAME% ^| find "STATE"') do (
    echo 当前状态：%%i
)
pause
goto menu

:view_logs
echo 正在打开 S-UI 日志目录...
if exist "%INSTALL_DIR%\logs" (
    start "" "%INSTALL_DIR%\logs"
) else (
    echo 未找到日志目录：%INSTALL_DIR%\logs
)
pause
goto menu

:open_panel
echo 正在浏览器中打开 S-UI 面板...
start http://localhost:2095
echo 已使用默认浏览器打开面板。
pause
goto menu

:run_manual
echo 正在手动运行 S-UI...
if exist "%INSTALL_DIR%\sui.exe" (
    cd /d "%INSTALL_DIR%"
    echo S-UI 将在当前窗口运行...
    echo 按 Ctrl+C 停止
    echo.
    sui.exe
) else (
    echo 未找到 S-UI 程序：%INSTALL_DIR%\sui.exe
    echo 请先运行安装程序。
)
pause
goto menu

:service_management
cls
echo ========================================
echo Windows 服务管理
echo ========================================
echo.
echo 1. 安装 Windows 服务
echo 2. 卸载 Windows 服务
echo 3. 返回主菜单
echo.
set /p service_choice="请选择 [1-3]："

if "%service_choice%"=="1" goto install_service
if "%service_choice%"=="2" goto uninstall_service
if "%service_choice%"=="3" goto menu
goto invalid_choice

:install_service
echo 正在安装 Windows 服务...
if exist "%INSTALL_DIR%\s-ui-service.exe" (
    cd /d "%INSTALL_DIR%"
    s-ui-service.exe install
    if %errorLevel% equ 0 (
        echo 服务安装成功！
        echo 正在启动服务...
        net start %SERVICE_NAME%
    ) else (
        echo 服务安装失败，错误代码：%errorLevel%
    )
) else (
    echo 未找到服务包装程序，请先运行安装程序。
)
pause
goto service_management

:uninstall_service
echo 正在卸载 Windows 服务...
if exist "%INSTALL_DIR%\s-ui-service.exe" (
    cd /d "%INSTALL_DIR%"
    net stop %SERVICE_NAME% >nul 2>&1
    s-ui-service.exe uninstall
    if %errorLevel% equ 0 (
        echo 服务卸载成功！
    ) else (
        echo 服务卸载失败，错误代码：%errorLevel%
    )
) else (
    echo 未找到服务包装程序。
)
pause
goto service_management

:open_directory
echo 正在打开安装目录...
if exist "%INSTALL_DIR%" (
    start "" "%INSTALL_DIR%"
) else (
    echo 未找到安装目录：%INSTALL_DIR%
)
pause
goto menu

:show_config
echo.
echo ========================================
echo S-UI 配置
echo ========================================
if exist "%INSTALL_DIR%\sui.exe" (
    cd /d "%INSTALL_DIR%"
    echo 当前设置：
    sui.exe setting -show
    echo.
    echo 管理员信息：
    sui.exe admin -show
) else (
    echo 未找到 S-UI 程序，请先运行安装程序。
)
pause
goto menu

:show_urls
echo.
echo ========================================
echo 访问地址
echo ========================================
echo.
echo 本机访问：
echo   面板：http://localhost:2095
echo   订阅：http://localhost:2096
echo.
echo 局域网访问：
for /f "tokens=2 delims=:" %%i in ('ipconfig ^| findstr /i "IPv4"') do (
    set "ip=%%i"
    set "ip=!ip: =!"
    echo   面板：http://!ip!:2095
    echo   订阅：http://!ip!:2096
)
echo.
pause
goto menu

:invalid_choice
echo 无效选项，请重新选择。
pause
goto menu

:exit
echo 感谢使用 S-UI Windows 管理面板！
exit /b 0
