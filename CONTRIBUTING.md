# 参与开发

## 准备环境

需要安装 Go、Node.js、npm 和 Git。

```bash
git clone https://github.com/charmtv/s-ui.git
cd s-ui
```

## 启动项目

```bash
./runSUI.sh
```

也可以分别启动：

```bash
cd frontend
npm install
npm run dev
```

```bash
go run .
```

## 提交前检查

```bash
cd frontend
npm run build
```

```bash
go test ./...
go build ./...
```

请保持改动范围清晰，提交信息简洁，并说明测试结果。
