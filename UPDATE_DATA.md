# Trivy 漏洞库与检查包手动更新

本文记录手动更新所有数据库（Vuln DB、Java DB、Checks Bundle）的命令，以及本次执行结果。

## 一次性更新全部（含代理）

```bash
clashon
./trivy image --download-db-only
./trivy image --download-java-db-only
./trivy fs --scanners misconfig --skip-db-update --skip-java-db-update /home/Gitworks/trivy/Test
clashoff
```

上述三条命令覆盖当前 Trivy 的三类外部数据：

- Vulnerability DB（trivy-db）
- Java DB（trivy-java-db）
- Checks Bundle（trivy-checks）

其中 Checks Bundle 没有独立的“仅下载”命令，需通过 misconfig 扫描触发更新。

## 可选：强制重新下载（清缓存后更新）

仅在你怀疑数据库损坏或希望完全重拉时使用：

```bash
./trivy clean --vuln-db --java-db --checks-bundle
```

## 更新单项数据库

```bash
./trivy image --download-db-only
```

```bash
./trivy image --download-java-db-only
```

```bash
./trivy fs --scanners misconfig --skip-db-update --skip-java-db-update /home/Gitworks/trivy/Test
```

## 一键更新脚本

```bash
chmod +x /home/Gitworks/trivy/update_trivy_data.sh
/home/Gitworks/trivy/update_trivy_data.sh /home/Gitworks/trivy/Test
```

脚本会在检测到 clashon/clashoff 时自动启用或关闭代理，且即便目录中没有可扫描的配置文件也会正常退出。

## 使用镜像源（可选）

```bash
./trivy image --db-repository mirror.gcr.io/aquasec/trivy-db:2 --download-db-only
```

```bash
./trivy image --java-db-repository mirror.gcr.io/aquasec/trivy-java-db:1 --download-java-db-only
```

```bash
./trivy fs --scanners misconfig --checks-bundle-repository mirror.gcr.io/aquasec/trivy-checks:1 /home/Gitworks/trivy/Test
```

## 本次执行结果

已成功更新：
- Vulnerability DB：mirror.gcr.io/aquasec/trivy-db:2
- Java DB：mirror.gcr.io/aquasec/trivy-java-db:1
- Checks Bundle：mirror.gcr.io/aquasec/trivy-checks:1
