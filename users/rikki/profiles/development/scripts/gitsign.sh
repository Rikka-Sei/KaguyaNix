#!/usr/bin/env bash
# Git commit with signing

if [ $# -lt 1 ]; then
    echo "用法: gitsign <message> [keyid]"
    exit 1
fi

message="$1"
keyid="${2:-3927D7F5365B0203}"  # 默认密钥

git -c user.signingkey="${keyid}!" commit -S -m "$message"

