# 阿里云盘下载修复版

> 修改自 [tickstep/aliyunpan](https://github.com/tickstep/aliyunpan)

## 🐛 问题原因

阿里云盘API升级到 **OSS V4签名**，URL格式从绝对时间戳改为相对秒数：

```diff
- 旧格式: x-oss-expires=1719306000 (Unix时间戳)
+ 新格式: x-oss-date=20260625T080444Z & x-oss-expires=900 (相对秒数)
```

原代码将相对秒数误判为时间戳，导致下载速度永远为 0B/s。

---

## 🚀 快速修复

### 1️⃣ 编译

```bash
# 编译所有平台
./all_build.sh

# 只编译Linux平台
./all_build.sh linux

# 只编译Windows平台
./all_build.sh windows

# 只编译macOS平台
./all_build.sh macos
```

**输出位置**：`dist/` 目录

**生成文件**：
- `aliyunpan-linux-amd64` - Linux 64位
- `aliyunpan-windows-amd64.exe` - Windows 64位
- `aliyunpan-macos-amd64` - macOS Intel
- `aliyunpan-macos-arm64` - macOS M1/M2/M3
- 更多平台版本...

### 2️⃣ 替换系统程序

```bash
# 查找安装位置（如果不确定）
which aliyunpan

# 备份原程序
sudo cp /usr/local/bin/aliyunpan /usr/local/bin/aliyunpan.bak

# 替换为修复后的程序
sudo cp dist/aliyunpan-linux-amd64 /usr/local/bin/aliyunpan
```

---

## ✅ 修复效果

| 修复前 | 修复后 |
|-------|-------|
| `↓ 0B/412MB(0.00%) 0B/s` ❌ | `↓ 45MB/412MB(11%) 3.2MB/s` ✅ |

---

## 🔧 手动编译单个平台

### Linux

```bash
# 64位 Intel/AMD
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o aliyunpan-linux-amd64 .

# 32位
GOOS=linux GOARCH=386 go build -ldflags="-s -w" -o aliyunpan-linux-386 .

# ARM64 (树莓派4/5)
GOOS=linux GOARCH=arm64 go build -ldflags="-s -w" -o aliyunpan-linux-arm64 .

# ARM32 (树莓派3)
GOOS=linux GOARCH=arm go build -ldflags="-s -w" -o aliyunpan-linux-arm .
```

### Windows

```bash
# 64位
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w" -o aliyunpan-windows.exe .

# 32位
GOOS=windows GOARCH=386 go build -ldflags="-s -w" -o aliyunpan-windows-32bit.exe .
```

### macOS

```bash
# Intel Mac
GOOS=darwin GOARCH=amd64 go build -ldflags="-s -w" -o aliyunpan-macos-intel .

# Apple Silicon (M1/M2/M3)
GOOS=darwin GOARCH=arm64 go build -ldflags="-s -w" -o aliyunpan-macos-m1 .
```

**参数说明**：
- `-ldflags="-s -w"` - 减小程序体积（去除调试信息）
- `GOOS` - 目标操作系统
- `GOARCH` - 目标CPU架构


---

**修复日期**: 2026-06-25 | **版本**: 基于 v0.3.7

---