# Trivy 本地部署与复现流程

本文档基于本仓库当前状态编写，按步骤执行即可完成构建与验证。若你的本机 Go 版本低于 go.mod 要求，建议走 Docker 构建路径。

## 0. 环境要求

- Docker 已安装并可用
- Git 已安装
- 可访问 Docker Hub
- 网络可访问 Go 模块代理（如 https://goproxy.cn）

## 1. 获取源码

```bash
git clone https://github.com/aquasecurity/trivy.git
cd trivy
```

## 2. 快速验证 Docker 运行环境

```bash
docker run --rm aquasec/trivy --version
```

若输出版本号，说明 Docker 环境与镜像拉取正常。

## 3. 使用 Docker 完成本地构建

仓库 go.mod 需要较新 Go 版本，推荐通过官方 Golang 容器构建：

```bash
docker pull golang:1.25.0
```

```bash
docker run --rm \
  -e CGO_ENABLED=0 \
  -e GOEXPERIMENT=jsonv2 \
  -e GOPROXY=https://goproxy.cn,direct \
  -v "$PWD":/src \
  -w /src \
  golang:1.25.0 \
  /usr/local/go/bin/go build \
    -ldflags "-s -w -X=github.com/aquasecurity/trivy/pkg/version/app.ver=dev" \
    -o ./trivy ./cmd/trivy
```

构建成功后，当前目录会生成二进制文件 ./trivy。

## 4. 运行与验证

```bash
./trivy --version
```

示例输出：

```
Version: dev
```

## 5. 扫描验证（可选）

扫描本仓库文件系统（包含漏洞、密钥与误配置扫描）：

```bash
./trivy fs --scanners vuln,secret,misconfig .
```

## 6. 作为容器镜像运行（可选）

若你想使用官方镜像直接运行：

```bash
docker run --rm aquasec/trivy fs --scanners vuln,secret,misconfig /root/.trivy
```

## 7. 常见问题处理

### 7.1 Go 模块下载超时

如果构建时出现 proxy.golang.org 连接超时，使用以下代理：

```
GOPROXY=https://goproxy.cn,direct
```

已在第 3 步的构建命令中默认设置。

### 7.2 本机 Go 版本过低

如果本机 go version 低于 go.mod 的版本要求，直接使用第 3 步的 Docker 构建路径即可。

