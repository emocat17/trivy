# Trivy 使用指南

## 0. 前置要求：支持的语言与文件
Trivy 的漏洞检测依赖于项目的依赖配置文件。为确保扫描有效，请确保项目包含以下文件之一：

| 语言/环境 | 必须存在的文件 (任选其一) | 备注 |
| :--- | :--- | :--- |
| **Java** | `pom.xml`, `*.jar`, `*.war`, `*.ear` | Maven 项目需 `pom.xml`，构建后产物也可扫描 |
| **Node.js** | `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml` | `package.json` 也能扫描但准确度较低 |
| **Python** | `requirements.txt`, `Pipfile.lock`, `poetry.lock` | |
| **Go** | `go.mod` (源代码), 二进制文件 | 二进制需保留构建信息 |
| **C/C++** | `conan.lock` | 仅源码无法扫描，必须使用 Conan 包管理 |
| **Rust** | `Cargo.lock` | |
| **Ruby** | `Gemfile.lock` | |
| **PHP** | `composer.lock` | |
| **.NET** | `packages.lock.json`, `*.deps.json` | |

> **提示**：如果您的项目中只有源码（如 `.c`, `.java`）而没有上述文件，Trivy 将无法分析第三方依赖漏洞，仅能扫描 **密钥泄漏 (Secret)** 和 **配置错误 (Misconfig)**。

---

本文档介绍如何使用本项目（Trivy）进行代码和镜像安全扫描。

## 1. 快速开始：扫描 Test 目录并输出结果

根据你的需求，我们已经在 `\home\Gitworks\trivy\Test` 目录下准备了测试代码（`requirements.txt`），并使用 `\home\Gitworks\trivy\Output` 目录保存结果。

**执行命令（Linux 环境）：**

```bash
# 1. 开启代理（解决漏洞库下载问题）
clashon

# 2. 执行扫描（扫描文件系统，输出 JSON 格式）
./trivy fs \
  --format json \
  --output /home/Gitworks/trivy/Output/trivy-report.json \
  /home/Gitworks/trivy/Test

# 3. 关闭代理
clashoff
```

> **注意**：
> - `clashon` 和 `clashoff` 是你环境中的代理开关命令。
> - 如果首次运行，Trivy 会自动下载漏洞数据库（需几百兆），请确保网络通畅。
> - 扫描结果将保存在 `/home/Gitworks/trivy/Output/trivy-report.json`。

---

## 2. 常用功能与命令

以下命令假设你已在 trivy 二进制文件所在目录。

### 2.1 扫描文件系统 (FileSystem)

扫描本地项目目录中的漏洞、密钥泄漏和配置错误。

```bash
# 基础扫描
./trivy fs /path/to/project

# 仅扫描高危及严重漏洞
./trivy fs --severity HIGH,CRITICAL /path/to/project

# 启用所有扫描器（漏洞、敏感信息、配置错误、许可证）
./trivy fs --scanners vuln,secret,misconfig,license /path/to/project
```

### 2.2 扫描容器镜像 (Image)

```bash
# 扫描 Docker 镜像
./trivy image python:3.4-alpine

# 扫描本地 tar 格式镜像
./trivy image --input /path/to/image.tar
```

### 2.3 输出格式控制

支持 `table`（默认）、`json`、`sarif`、`cyclonedx`、`spdx-json` 等格式。

```bash
# 输出 JSON
./trivy fs --format json --output result.json .

# 输出表格（直接打印到终端）
./trivy fs --format table .
```

### 2.4 SBOM 生成（官方教程）

SBOM 通过在 `image` 或 `fs` 子命令中指定 `--format` 生成：

```bash
./trivy image --format spdx-json --output /home/Gitworks/trivy/Output/sbom-image.spdx.json alpine:3.15
```

```bash
./trivy fs --format cyclonedx --output /home/Gitworks/trivy/Output/sbom-fs.cdx.json /home/Gitworks/trivy/Test
```

项目语言示例（与官方支持范围一致）：

```bash
./trivy fs --format spdx-json --output /home/Gitworks/trivy/Output/sbom-java.spdx.json /home/Gitworks/trivy/Test/sbom-samples/java
```

```bash
./trivy fs --format cyclonedx --output /home/Gitworks/trivy/Output/sbom-c.cdx.json /home/Gitworks/trivy/Test/sbom-samples/c
```

### 2.5 自动化多格式输出脚本 (scan.sh)

我们提供了一个脚本 `scan.sh`，可以自动检测输入类型（文件/目录或镜像），并同时生成 JSON 和 Markdown 表格报告。

**用法：**

```bash
./scan.sh <目标> <输出目录>
```

**示例：**

```bash
# 扫描目录
./scan.sh /home/Gitworks/trivy/Test/NanoLog-master /home/Gitworks/trivy/Output

# 扫描镜像
./scan.sh alpine:3.15 /home/Gitworks/trivy/Output
```

**输出结果：**
脚本会自动在输出目录生成两个文件：
- `{Filename}.json`：完整的 JSON 格式报告
- `{Filename}.md`：易读的 Markdown 表格报告

---

### 2.6 处理网络问题

如果下载漏洞库（Trivy DB）很慢或失败，可以使用以下方法：

**方法 A：使用代理（推荐）**

```bash
export http_proxy=http://127.0.0.1:7890
export https_proxy=http://127.0.0.1:7890
./trivy image python:3.9
```
*(或者直接使用你的 `clashon` 命令)*

**方法 B：使用 OCI 镜像源**

Trivy v2 默认使用 OCI 镜像源，如果默认源慢，可以指定其他源（通常无需更改，代理更有效）。

**方法 C：跳过 DB 更新（仅限已有缓存）**

如果你已经下载过 DB，且不想每次都检查更新：

```bash
./trivy fs --skip-db-update .
```

---

## 3. 进阶：如何扫描无锁文件的源码项目（自动生成依赖）

**更新：我们已将自动化依赖生成集成到扫描脚本中！**

现在的 `scan.sh` 脚本具备智能预处理功能。当您扫描一个只有源码的目录时，它会尝试自动补全依赖文件：

- **Python**: 自动安装 `pipreqs` 并生成 `requirements.txt`。
- **C/C++**: 自动安装 `conan`，尝试根据源码中的 include 语句（如 openssl, zlib）猜测依赖，并生成 `conan.lock`。
- **Node.js**: 自动运行 `npm install --package-lock-only` 生成锁文件。
- **Go**: 自动运行 `go mod tidy` 生成 `go.sum`。

您无需手动执行任何额外命令，只需正常运行扫描脚本即可：

```bash
./scan.sh /path/to/source-code /Output
```

> **注意**：
> 1. 自动生成是基于启发式推断的（尤其是 C++），可能无法覆盖所有复杂依赖情况，但在大多数标准项目中能有效工作。
> 2. 该功能需要联网下载必要的工具（如 pipreqs, conan）和依赖包。

---

## 4. 高级用法

### 4.1 过滤误报

使用 `.trivyignore` 文件忽略特定漏洞。

1. 在项目根目录创建 `.trivyignore` 文件。
2. 写入漏洞 ID（每行一个）：
   ```text
   CVE-2023-1234
   ```
3. 再次扫描，该漏洞将被忽略。

### 4.2 退出代码（CI/CD 集成）

在 CI/CD 中，如果发现漏洞希望阻断流程：

```bash
# 如果发现 CRITICAL 漏洞，返回退出码 1
./trivy fs --exit-code 1 --severity CRITICAL .
```

## 5. 常见问题排查

- **DB Download Error**: 检查网络或代理设置。确保 `https_proxy` 环境变量已正确设置。
- **Rate Limit**: 如果遇到 GitHub API 限流（下载 DB 时），请设置 `GITHUB_TOKEN` 环境变量。

---

**验证结果查看：**
你可以查看 `/home/Gitworks/trivy/Output/trivy-report.json` 确认刚才的扫描结果。
