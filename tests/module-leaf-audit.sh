#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
fail=0
for bad in modules/identity modules/business modules/lifetime \
  modules/development/base modules/gaming/base modules/software/workstation \
  modules/software/base-cli modules/software/browser modules/software/communication \
  modules/software/creative modules/software/desktop-tools modules/software/learning \
  modules/software/network-access modules/software/remote-access modules/software/reverse-engineering; do
  if [ -e "$bad" ]; then echo "FAIL: 残留 $bad"; fail=1; fi
done
if find modules -type d \( -name common -o -name base \) | grep -q .; then
  echo "FAIL: modules/ 下仍有 common/base"; fail=1
fi
[ "$fail" -eq 0 ] && echo "PASS: module-leaf-audit"
exit "$fail"
