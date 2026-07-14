# S-UI 简体中文版

基于 [alireza0/s-ui](https://github.com/alireza0/s-ui) 的简体中文定制版。

- 项目仓库：`https://github.com/charmtv/s-ui`
- 当前版本：`1.5.3`
- 上游同步：`2be943e5d8e298120eeaad0f4bc1e339a7b67d9c`
- 界面语言：固定为简体中文
- 前端源码：已合并到主仓库，不再使用 Git 子模块

> 本项目仅供学习与交流，请遵守所在地区法律法规。

## 一键安装

使用 root 用户执行：

```bash
bash <(curl -Ls https://raw.githubusercontent.com/charmtv/s-ui/main/install.sh)
```

也可以使用 Cloudflare 域名：

```bash
bash <(curl -Ls https://sui.813099.xyz/install.sh)
```

域名命令由 Cloudflare Worker 提供，并实时读取本仓库 `main` 分支中的安装脚本。GitHub 原始命令继续保留，两种方式功能相同。

安装指定版本：

```bash
VERSION=1.5.3
bash <(curl -Ls https://raw.githubusercontent.com/charmtv/s-ui/main/install.sh) "$VERSION"
```

域名方式安装指定版本：

```bash
VERSION=1.5.3
bash <(curl -Ls https://sui.813099.xyz/install.sh) "$VERSION"
```

安装完成后运行管理菜单：

```bash
s-ui
```

常用命令：

```bash
s-ui start
s-ui stop
s-ui restart
s-ui status
s-ui log
s-ui update
```

只更新中文管理脚本：

```bash
curl -fLs https://sui.813099.xyz/s-ui.sh -o /usr/bin/s-ui
chmod +x /usr/bin/s-ui
```

## 默认配置

| 项目 | 默认值 |
| --- | --- |
| 面板端口 | `2095` |
| 面板路径 | `/app/` |
| 订阅端口 | `2096` |
| 订阅路径 | `/sub/` |
| 默认账号 | `admin` |

建议安装后立即修改账号、密码、端口和访问路径。

## Docker

```bash
docker compose up -d
```

默认镜像：

```text
ghcr.io/charmtv/s-ui:latest
```

## 本地开发

环境要求：Go、Node.js、npm。

```bash
git clone https://github.com/charmtv/s-ui.git
cd s-ui
./runSUI.sh
```

单独构建前端：

```bash
cd frontend
npm install
npm run build
```

后端检查：

```bash
go test ./...
go build ./...
```

## 发布说明

一键安装优先下载 `charmtv/s-ui` 的 Release。仓库尚未发布二进制时，会临时回退到上游发布包。

在 GitHub 中发布 `v1.5.3` 或推送同名标签后，Release 工作流会自动构建 Linux 和 Windows 安装包。

## 许可证

本项目遵循 [GPL-3.0](LICENSE)。
