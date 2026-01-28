根据代码库分析，Trivy 目前支持以下编程语言和生态系统的漏洞扫描：

## 主要编程语言

**编译型语言**
- **Go** - 支持 Go Modules、Go Sum 和二进制文件分析
- **Rust** - 支持 Cargo lockfile 和二进制文件
- **C/C++** - 通过 Conan 包管理器
- **Swift** - 支持 CocoaPods 和 Swift Package Manager
- **Java** - 支持 JAR、Maven POM、Gradle 和 SBT
- **Scala** - 支持 SBT
- **.NET/C#** - 支持 NuGet 配置、lock 文件和 packages.props

**脚本/解释型语言**
- **JavaScript/Node.js** - 支持 npm、Yarn、pnpm、Bun 和 package.json
- **Python** - 支持 pip、pipenv、Poetry、pyproject、uv、packaging 和 Conda 环境
- **Ruby** - 支持 Bundler、gemspec 和 RubyGems
- **PHP** - 支持 Composer
- **Dart** - 支持 Pub
- **Julia** - 支持 Manifest
- **Elixir/Erlang** - 支持 Hex/Mix

**框架特定**
- **WordPress** - PHP 框架支持

## 操作系统包

同时还支持各类 Linux 发行版的系统包扫描：
- Alpine、Debian/Ubuntu、Red Hat/CentOS/Rocky/Alma、SUSE
- Amazon Linux、Oracle Linux、Azure Linux、Photon OS
- Chainguard、Wolfi、Bottlerocket、CoreOS 等

相关代码实现在 [pkg/dependency/parser](pkg/dependency/parser) 目录下，每个子目录对应特定语言或包管理器的解析器。

如果想了解更多技术细节，可以查看 [漏洞检测系统](10-vulnerability-detection-system) 页面。

[漏洞检测系统](10-vulnerability-detection-system)
[容器镜像扫描](13-container-image-scanning)
[SBOM 生成与分析](11-sbom-generation-and-analysis)