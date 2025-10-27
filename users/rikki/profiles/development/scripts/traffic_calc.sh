#!/usr/bin/env bash
# 计算流量费用和USDT数量

price="$1"

# 检查价格参数
if [ -z "$price" ]; then
    echo "错误: 请提供价格参数"
    echo "用法: traffic_calc <价格>"
    exit 1
fi

if ! [[ "$price" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo "错误: 请输入有效的价格数字"
    exit 1
fi

# 获取用户输入
read -p "请输入当前流量(G): " traffic

# 验证输入
if [ -z "$traffic" ]; then
    echo "错误: 流量不能为空"
    exit 1
fi

if ! [[ "$traffic" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo "错误: 请输入有效的数字"
    exit 1
fi

echo "正在获取USDT汇率..."

# 获取USDT汇率
usdt_rate=$(curl -s "https://api.coinbase.com/v2/exchange-rates?currency=USDT" | jq -r '.data.rates.CNY')

# 检查汇率获取是否成功
if [ -z "$usdt_rate" ] || [ "$usdt_rate" = "null" ]; then
    echo "错误: 无法获取USDT汇率，请检查网络连接"
    exit 1
fi

# 计算调整后汇率 (减去0.1)
adjusted_rate=$(echo "$usdt_rate - 0.1" | bc -l)

# 计算总费用 CNY (流量 * 传入的价格)
total_cny=$(echo "$traffic * $price" | bc -l)

# 计算需要的USDT数量
usdt_amount=$(echo "scale=6; $total_cny / $adjusted_rate" | bc -l)

# 输出结果
echo ""
echo "========== 计算结果 =========="
echo "流量: $traffic G"
echo "总费用: $total_cny CNY"
echo "USDT汇率: $usdt_rate CNY"
echo "调整后汇率: $adjusted_rate CNY"
echo "需要USDT: $usdt_amount"
echo "============================="
