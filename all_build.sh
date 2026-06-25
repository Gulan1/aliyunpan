#!/bin/bash

# 阿里云盘修复版 - 全平台编译脚本
# 用法: ./all_build.sh [platform]
# 示例: ./all_build.sh          (编译所有平台)
#      ./all_build.sh linux    (只编译Linux)
#      ./all_build.sh windows  (只编译Windows)
#      ./all_build.sh macos    (只编译macOS)

set -e

# 检查目录
if [ ! -f "main.go" ]; then
    echo "❌ 错误: 请在 aliyunpan 项目根目录下运行"
    exit 1
fi

# 输出目录
OUTPUT_DIR="dist"
mkdir -p "$OUTPUT_DIR"

# 获取目标平台
TARGET_PLATFORM="${1:-all}"

# 定义编译配置
declare -A BUILDS=(
    ["linux-amd64"]="linux amd64"
    ["linux-386"]="linux 386"
    ["linux-arm64"]="linux arm64"
    ["linux-arm"]="linux arm"
    ["windows-amd64"]="windows amd64"
    ["windows-386"]="windows 386"
    ["macos-amd64"]="darwin amd64"
    ["macos-arm64"]="darwin arm64"
)

# 定义平台说明
declare -A DESCRIPTIONS=(
    ["linux-amd64"]="Linux x64"
    ["linux-386"]="Linux x86"
    ["linux-arm64"]="Linux ARM64"
    ["linux-arm"]="Linux ARM32"
    ["windows-amd64"]="Windows x64"
    ["windows-386"]="Windows x86"
    ["macos-amd64"]="macOS Intel"
    ["macos-arm64"]="macOS M1/M2/M3"
)

# 过滤需要编译的平台
FILTERED_BUILDS=()
for platform in "${!BUILDS[@]}"; do
    case "$TARGET_PLATFORM" in
        all)
            FILTERED_BUILDS+=("$platform")
            ;;
        linux)
            [[ $platform == linux-* ]] && FILTERED_BUILDS+=("$platform")
            ;;
        windows)
            [[ $platform == windows-* ]] && FILTERED_BUILDS+=("$platform")
            ;;
        macos|mac|darwin)
            [[ $platform == macos-* ]] && FILTERED_BUILDS+=("$platform")
            ;;
        *)
            echo "❌ 未知平台: $TARGET_PLATFORM"
            echo "支持的平台: all, linux, windows, macos"
            exit 1
            ;;
    esac
done

TOTAL=${#FILTERED_BUILDS[@]}
if [ $TOTAL -eq 0 ]; then
    echo "❌ 没有匹配的平台"
    exit 1
fi

echo "=========================================="
echo "  编译 $TARGET_PLATFORM 平台 ($TOTAL 个)"
echo "=========================================="
echo ""

# 编译
SUCCESS=0
FAILED=0
for i in "${!FILTERED_BUILDS[@]}"; do
    platform="${FILTERED_BUILDS[$i]}"
    CURRENT=$((i + 1))
    
    read -r GOOS GOARCH <<< "${BUILDS[$platform]}"
    
    OUTPUT_NAME="aliyunpan-${platform}"
    [[ $GOOS == "windows" ]] && OUTPUT_NAME="${OUTPUT_NAME}.exe"
    
    echo "[$CURRENT/$TOTAL] ${DESCRIPTIONS[$platform]}"
    
    if GOOS=$GOOS GOARCH=$GOARCH go build -ldflags="-s -w" -o "$OUTPUT_DIR/$OUTPUT_NAME" . 2>/dev/null; then
        SIZE=$(du -h "$OUTPUT_DIR/$OUTPUT_NAME" | cut -f1)
        echo "        ✅ $OUTPUT_NAME ($SIZE)"
        SUCCESS=$((SUCCESS + 1))
    else
        echo "        ❌ 编译失败"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "=========================================="
echo "  完成: $SUCCESS/$TOTAL"
echo "=========================================="
echo ""
echo "输出目录: $OUTPUT_DIR/"
echo ""
ls -lh "$OUTPUT_DIR/" | grep "aliyunpan-" | awk '{print "  " $9 " (" $5 ")"}'
echo ""

# 创建说明文件
cat > "$OUTPUT_DIR/README.txt" << 'EOF'
阿里云盘下载修复版
========================================

📁 平台文件

Linux:
  aliyunpan-linux-amd64   - 64位 Intel/AMD
  aliyunpan-linux-386     - 32位
  aliyunpan-linux-arm64   - ARM64 (树莓派4/5)
  aliyunpan-linux-arm     - ARM32 (树莓派3)

Windows:
  aliyunpan-windows-amd64.exe - 64位
  aliyunpan-windows-386.exe   - 32位

macOS:
  aliyunpan-macos-amd64   - Intel Mac
  aliyunpan-macos-arm64   - M1/M2/M3 Mac

📝 使用方法

Linux/macOS:
  chmod +x 文件名
  ./文件名

Windows:
  双击运行或CMD执行

🔧 替换系统程序(Linux)
  sudo cp 文件名 /usr/local/bin/aliyunpan

========================================
编译: $(date +"%Y-%m-%d %H:%M:%S")
EOF
