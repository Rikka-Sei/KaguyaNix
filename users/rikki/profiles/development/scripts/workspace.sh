#!/usr/bin/env bash
# 创建和管理 macOS 稀疏捆绑包工作区

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认值
DEFAULT_SIZE="64g"
DEFAULT_FS="Case-sensitive APFS"

# 显示帮助信息
show_help() {
    cat << EOF
工作区管理工具 - 创建和管理 macOS 稀疏捆绑包

用法:
    workspace                           启动交互式菜单
    workspace --name "名称" [选项]      直接创建工作区

选项:
    --name <名称>        工作区名称(必需)
    --store <路径>       存储路径(默认: 当前目录)
    --size <大小>        磁盘大小(默认: 64g)
    --fs <文件系统>      文件系统类型(默认: Case-sensitive APFS)
    --mount              创建后立即挂载
    -h, --help           显示此帮助信息

示例:
    workspace --name "大学课程文件-大三上"
    workspace --name "项目开发" --store ~/Documents --size 128g
    workspace --name "工作区" --store ~/Desktop --mount

文件系统选项:
    - Case-sensitive APFS (区分大小写)
    - APFS (不区分大小写)
    - Case-sensitive HFS+ (区分大小写,旧格式)
    - HFS+ (不区分大小写,旧格式)
EOF
}

# 错误处理
error() {
    echo -e "${RED}错误: $1${NC}" >&2
    exit 1
}

# 成功信息
success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# 警告信息
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# 信息输出
info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# 验证工作区名称
validate_name() {
    local name="$1"
    if [ -z "$name" ]; then
        error "工作区名称不能为空"
    fi

    # 检查是否包含非法字符
    if [[ "$name" =~ [/\\:] ]]; then
        error "工作区名称不能包含 / \\ : 字符"
    fi
}

# 验证磁盘大小格式
validate_size() {
    local size="$1"
    if ! [[ "$size" =~ ^[0-9]+[gmGM]$ ]]; then
        error "无效的磁盘大小格式，应为: 数字+单位(g/m), 例如: 64g, 128g, 512m"
    fi
}

# 创建工作区
create_workspace() {
    local name="$1"
    local store_path="$2"
    local size="$3"
    local fs="$4"
    local auto_mount="$5"

    # 验证参数
    validate_name "$name"
    validate_size "$size"

    # 确定存储路径
    if [ -z "$store_path" ]; then
        store_path="$(pwd)"
    fi

    # 展开 ~ 符号
    store_path="${store_path/#\~/$HOME}"

    # 确保存储目录存在
    if [ ! -d "$store_path" ]; then
        error "存储路径不存在: $store_path"
    fi

    # 构建完整路径
    local full_path="${store_path}/${name}.sparsebundle"

    # 检查是否已存在
    if [ -e "$full_path" ]; then
        error "工作区已存在: $full_path"
    fi

    info "正在创建工作区..."
    echo "  名称: $name"
    echo "  路径: $full_path"
    echo "  大小: $size"
    echo "  文件系统: $fs"
    echo ""

    # 创建稀疏捆绑包
    if hdiutil create -size "$size" -fs "$fs" -volname "$name" -type SPARSEBUNDLE "$full_path"; then
        success "工作区创建成功: $full_path"

        # 自动挂载
        if [ "$auto_mount" = "yes" ]; then
            echo ""
            info "正在挂载工作区..."
            if hdiutil attach "$full_path"; then
                success "工作区已挂载"
            else
                warning "挂载失败，请手动挂载"
            fi
        fi
    else
        error "创建工作区失败"
    fi
}

# 列出现有工作区
list_workspaces() {
    local search_path="${1:-$(pwd)}"
    search_path="${search_path/#\~/$HOME}"

    info "搜索工作区: $search_path"
    echo ""

    local count=0
    while IFS= read -r -d '' bundle; do
        count=$((count + 1))
        local name=$(basename "$bundle" .sparsebundle)
        local size=$(du -sh "$bundle" | cut -f1)
        echo "  $count. $name"
        echo "     路径: $bundle"
        echo "     大小: $size"
        echo ""
    done < <(find "$search_path" -maxdepth 2 -name "*.sparsebundle" -print0 2>/dev/null)

    if [ $count -eq 0 ]; then
        warning "未找到工作区"
    else
        success "找到 $count 个工作区"
    fi
}

# 挂载工作区
mount_workspace() {
    local path="$1"
    path="${path/#\~/$HOME}"

    if [ ! -e "$path" ]; then
        error "工作区不存在: $path"
    fi

    info "正在挂载: $path"
    if hdiutil attach "$path"; then
        success "挂载成功"
    else
        error "挂载失败"
    fi
}

# 卸载工作区
unmount_workspace() {
    local volume_name="$1"

    info "正在卸载: $volume_name"
    if hdiutil detach "/Volumes/$volume_name"; then
        success "卸载成功"
    else
        error "卸载失败"
    fi
}

# 交互式菜单
interactive_menu() {
    while true; do
        clear
        echo "=========================================="
        echo "        工作区管理工具"
        echo "=========================================="
        echo ""
        echo "  1. 创建新工作区"
        echo "  2. 列出现有工作区"
        echo "  3. 挂载工作区"
        echo "  4. 卸载工作区"
        echo "  5. 退出"
        echo ""
        echo "=========================================="
        read -p "请选择操作 [1-5]: " choice

        case $choice in
            1)
                echo ""
                read -p "工作区名称: " name
                read -p "存储路径 (留空使用当前目录): " store
                read -p "磁盘大小 (默认: 64g): " size
                size="${size:-$DEFAULT_SIZE}"

                echo ""
                echo "选择文件系统:"
                echo "  1. Case-sensitive APFS (推荐)"
                echo "  2. APFS"
                echo "  3. Case-sensitive HFS+"
                echo "  4. HFS+"
                read -p "选择 [1-4, 默认: 1]: " fs_choice

                case ${fs_choice:-1} in
                    1) fs="Case-sensitive APFS" ;;
                    2) fs="APFS" ;;
                    3) fs="Case-sensitive HFS+" ;;
                    4) fs="HFS+" ;;
                    *) fs="Case-sensitive APFS" ;;
                esac

                read -p "创建后立即挂载? [y/N]: " mount_choice
                auto_mount="no"
                if [[ "$mount_choice" =~ ^[Yy]$ ]]; then
                    auto_mount="yes"
                fi

                echo ""
                create_workspace "$name" "$store" "$size" "$fs" "$auto_mount"
                ;;

            2)
                echo ""
                read -p "搜索路径 (留空使用当前目录): " search_path
                echo ""
                list_workspaces "$search_path"
                ;;

            3)
                echo ""
                read -p "工作区路径: " path
                echo ""
                mount_workspace "$path"
                ;;

            4)
                echo ""
                read -p "卷名称: " volume
                echo ""
                unmount_workspace "$volume"
                ;;

            5)
                echo ""
                info "再见!"
                exit 0
                ;;

            *)
                echo ""
                error "无效的选择，请重试"
                ;;
        esac

        echo ""
        read -p "按回车键继续..."
    done
}

# 命令行参数解析
main() {
    # 如果没有参数,启动交互式菜单
    if [ $# -eq 0 ]; then
        interactive_menu
        exit 0
    fi

    # 解析命令行参数
    local name=""
    local store=""
    local size="$DEFAULT_SIZE"
    local fs="$DEFAULT_FS"
    local auto_mount="no"

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            --name)
                name="$2"
                shift 2
                ;;
            --store)
                store="$2"
                shift 2
                ;;
            --size)
                size="$2"
                shift 2
                ;;
            --fs)
                fs="$2"
                shift 2
                ;;
            --mount)
                auto_mount="yes"
                shift
                ;;
            *)
                error "未知参数: $1\n使用 --help 查看帮助"
                ;;
        esac
    done

    # 检查必需参数
    if [ -z "$name" ]; then
        error "缺少必需参数: --name\n使用 --help 查看帮助"
    fi

    # 创建工作区
    create_workspace "$name" "$store" "$size" "$fs" "$auto_mount"
}

# 运行主函数
main "$@"
