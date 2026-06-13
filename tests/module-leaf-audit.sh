#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
for bad in caps/identity caps/business caps/lifetime \
  caps/development/base caps/gaming/base caps/software/workstation \
  caps/software/base-cli caps/software/browser caps/software/communication \
  caps/software/creative caps/software/desktop-tools caps/software/learning \
  caps/software/network-access caps/software/remote-access caps/software/reverse-engineering; do
  if [ -e "$bad" ]; then echo "FAIL: 残留 $bad"; fail=1; fi
done
if find caps -type d \( -name common -o -name base \) | grep -q .; then
  echo "FAIL: caps/ 下仍有 common/base"; fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: module-leaf-audit"
exit "$fail"
