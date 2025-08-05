# 新的 Makefile - 支持自动发现系统配置

# 自动扫描 systems 目录获取所有可用系统
SYSTEMS := $(basename $(notdir $(wildcard systems/*.nix)))

# 默认目标
.PHONY: help list $(SYSTEMS) update format clean-garbage eval-time

help:
	@echo "Available commands:"
	@echo "  list                 - 列出所有可用的系统配置"
	@echo "  <system-name>        - 构建指定的系统配置"
	@echo "  update               - 更新 flake inputs"
	@echo "  format               - 格式化代码"
	@echo "  clean-garbage        - 清理垃圾"
	@echo "  eval-time <system>   - 评估构建时间"
	@echo ""
	@echo "Available systems:"
	@$(foreach system,$(SYSTEMS),echo "  $(system)";)

list:
	@echo "可用的系统配置:"
	@$(foreach system,$(SYSTEMS), \
		if [ -f "systems/$(system).nix" ]; then \
			echo "  $(system) - $(shell head -5 systems/$(system).nix | grep -o 'hostName.*' | cut -d '"' -f2)"; \
		fi; \
	)

# 为每个系统创建构建目标
$(SYSTEMS):
	@echo "构建系统: $@"
	sudo nixos-rebuild switch --flake ./#$@ --show-trace

# 通用命令
update:
	nix flake update

format:
	alejandra ./

clean-garbage:
	nix-collect-garbage -d

eval-time:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make eval-time <system-name>"; \
		exit 1; \
	fi
	time nix eval --raw .#nixosConfigurations.$(filter-out $@,$(MAKECMDGOALS)).config.system.build.toplevel --show-trace

# 便捷别名（基于常见系统）
.PHONY: laptop desktop server
laptop: laptop-asus-tx4-personal
desktop: desktop-home-rikki
server: server-vps-prod

# 防止 make 将别名参数解释为目标
%:
	@: