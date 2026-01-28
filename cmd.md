# Trivy 命令速查表

本文档汇集了本项目中常用的扫描命令与脚本用法。

## 1. 🚀 推荐方式：自动化全能扫描

我们提供了一个封装脚本 `scan.sh`，它集成了以下功能：
1.  **自动依赖生成**：自动检测源码（Python/C++/Node/Go）并补全锁文件（依赖 `auto_gen_deps.sh`）。
2.  **双重输出**：同时生成详细的 JSON 报告和易读的 Markdown 表格报告。
3.  **全量扫描**：默认启用 漏洞(vuln)、密钥(secret)、配置(misconfig)、许可证(license) 扫描。

### 用法
```bash
./scan.sh <目标> <输出目录>
```

### 示例
```bash
# 1. 扫描本地源码目录 (会自动生成依赖文件)
./scan.sh /home/Gitworks/trivy/Test/NanoLog-master /home/Gitworks/trivy/Output

# 2. 扫描 Docker 镜像
./scan.sh alpine:3.15 /home/Gitworks/trivy/Output
```

**输出结果示例**：
- `/home/Gitworks/trivy/Output/NanoLog-master.json`
- `/home/Gitworks/trivy/Output/NanoLog-master.md`

---

## 2. 🛠 脚本工作原理

### `scan.sh` (主入口)
- 判断输入是文件/目录还是镜像。
- 调用 `auto_gen_deps.sh` 进行预处理。
- 执行两次 `trivy` 扫描（JSON + Table）。

### `auto_gen_deps.sh` (依赖生成器)
当扫描目录时，该脚本会自动运行：
- **Python**: 缺 `requirements.txt` 时，运行 `pipreqs` 生成。
- **C/C++**: 缺 `conan.lock` 时，自动安装 `conan` 并根据源码 include 猜测生成锁文件。
- **Node.js**: 缺 `package-lock.json` 时，运行 `npm install --package-lock-only`。
- **Go**: 缺 `go.sum` 时，运行 `go mod tidy`。

---

## 3. 📖 手动命令参考 (Manual)

如果您需要自定义参数，可以使用原始 `trivy` 命令。

### 3.1 基础扫描
```bash
# 默认输出表格到终端
./trivy fs /path/to/project

# 输出 JSON 到文件
./trivy fs --format json --output result.json /path/to/project

# 同时扫描漏洞、密钥、配置和许可证
./trivy fs --scanners vuln,secret,misconfig,license /path/to/project
```

### 3.2 SBOM 生成
```bash
# 生成 CycloneDX 格式 (通用)
./trivy fs --format cyclonedx --output sbom.cdx.json /path/to/project

# 生成 SPDX JSON 格式 (镜像)
./trivy image --format spdx-json --output sbom.spdx.json alpine:3.15
```

### 3.3 镜像扫描
```bash
# 扫描镜像并输出 JSON
./trivy image --format json --output image-report.json python:3.9
```

---

## 4. 🌐 网络环境配置

如果下载漏洞库（Trivy DB）失败，请使用代理。

```bash
# 开启代理
clashon

# 执行扫描
./scan.sh /path/to/project /Output

# 关闭代理
clashoff
```
