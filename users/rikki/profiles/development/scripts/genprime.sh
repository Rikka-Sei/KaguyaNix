#!/usr/bin/env bash
# 生成大素数 - 使用米勒-拉宾素性测试

digits="${1:-10}"  # 默认生成10位素数

if ! [[ "$digits" =~ ^[0-9]+$ ]]; then
    echo "错误: 请输入有效的位数"
    echo "用法: genprime [位数]"
    exit 1
fi

if [ "$digits" -lt 1 ]; then
    echo "错误: 位数必须大于0"
    exit 1
fi

echo "正在生成 $digits 位素数..."

# 使用 openssl 生成大素数
# openssl 使用米勒-拉宾素性测试
bits=$((digits * 4))  # 粗略估算需要的比特数

# 生成素数并确保它在正确的位数范围内
min=$((10 ** (digits - 1)))
max=$((10 ** digits - 1))

attempts=0
max_attempts=1000

while [ $attempts -lt $max_attempts ]; do
    # 使用 openssl 生成素数
    prime=$(openssl prime -generate -bits $bits -hex 2>/dev/null | head -1)

    if [ -z "$prime" ]; then
        echo "错误: openssl 生成素数失败"
        exit 1
    fi

    # 将十六进制转换为十进制
    prime=$(printf "%d" "0x$prime" 2>/dev/null)

    if [ -z "$prime" ]; then
        attempts=$((attempts + 1))
        continue
    fi

    # 检查位数是否符合要求
    prime_digits=${#prime}

    if [ "$prime_digits" -eq "$digits" ]; then
        echo ""
        echo "========== 生成成功 =========="
        echo "素数: $prime"
        echo "位数: $prime_digits"
        echo "============================"

        # 验证是否为素数
        echo ""
        echo "验证中..."
        if openssl prime "$prime" 2>/dev/null | grep -q "is prime"; then
            echo "✓ 验证通过: 确认为素数"
        else
            echo "✗ 验证失败"
        fi

        exit 0
    fi

    # 如果位数不对，调整比特数
    if [ "$prime_digits" -lt "$digits" ]; then
        bits=$((bits + 1))
    else
        bits=$((bits - 1))
    fi

    attempts=$((attempts + 1))

    # 每100次尝试显示进度
    if [ $((attempts % 100)) -eq 0 ]; then
        echo "尝试中... ($attempts/$max_attempts)"
    fi
done

echo "错误: 超过最大尝试次数，无法生成指定位数的素数"
echo "建议: 尝试使用不同的位数或重新运行"
exit 1
