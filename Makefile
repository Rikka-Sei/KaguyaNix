# 新的 Makefile - 支持自动发现系统配置

# 自动扫描 systems 目录获取所有可用系统
SYSTEMS := $(basename $(notdir $(wildcard systems/*.nix)))

# 自动扫描 deploy 目录获取所有可用部署配置
DEPLOYS := $(basename $(notdir $(wildcard deploy/*.nix)))

# 默认目标
.PHONY: help list use update format clean-garbage eval-time check deploy-list deploy

help:
	@echo "Available commands:"
	@echo "  list                 - 列出所有可用的系统配置"
	@echo "  use <system-name>    - 构建并切换到指定的系统配置"
	@echo "  update [input]       - 更新 flake inputs (可指定特定 input)"
	@echo "  format               - 格式化代码"
	@echo "  clean-garbage        - 清理垃圾"
	@echo "  eval-time <system>   - 评估构建时间"
	@echo "  check                - 检查配置语法和依赖"
	@echo ""
	@echo "Deploy commands:"
	@echo "  deploy-list          - 列出所有可用的部署配置"
	@echo "  deploy <name>        - 部署到指定目标"
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

# 系统构建和切换
use:
	@TARGET="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$TARGET" ]; then \
		echo "Usage: make use <system-name>"; \
		echo "Available systems:"; \
		$(foreach system,$(SYSTEMS),echo "  $(system)";) \
		exit 1; \
	fi; \
	if [ ! -f "systems/$$TARGET.nix" ]; then \
		echo "错误: 系统配置 systems/$$TARGET.nix 不存在"; \
		exit 1; \
	fi; \
	echo "构建并切换到系统: $$TARGET"; \
	echo "正在检测系统类型..."; \
	if nix eval .#darwinConfigurations --apply 'x: builtins.hasAttr "'$$TARGET'" x' 2>/dev/null | grep -q true; then \
		echo "✅ 检测到 Darwin 系统，使用 darwin-rebuild..."; \
		sudo darwin-rebuild switch --flake .#$$TARGET --show-trace; \
	elif nix eval .#nixosConfigurations --apply 'x: builtins.hasAttr "'$$TARGET'" x' 2>/dev/null | grep -q true; then \
		echo "✅ 检测到 NixOS 系统，使用 nixos-rebuild..."; \
		sudo nixos-rebuild switch --flake ./#$$TARGET --show-trace; \
	else \
		echo "❌ 错误: 无法找到系统配置 $$TARGET"; \
		echo "可用的 Darwin 系统:"; \
		nix eval .#darwinConfigurations --apply 'x: builtins.attrNames x' 2>/dev/null || echo "  无"; \
		echo "可用的 NixOS 系统:"; \
		nix eval .#nixosConfigurations --apply 'x: builtins.attrNames x' 2>/dev/null || echo "  无"; \
		exit 1; \
	fi

# 通用命令
update:
	@if [ -n "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "更新指定 flake input: $(filter-out $@,$(MAKECMDGOALS))"; \
		nix flake update $(filter-out $@,$(MAKECMDGOALS)); \
	else \
		echo "更新所有 flake inputs"; \
		nix flake update; \
	fi

format:
	alejandra ./

clean-garbage:
	nix-collect-garbage -d

eval-time:
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "Usage: make eval-time <system-name>"; \
		exit 1; \
	fi; \
	TARGET="$(filter-out $@,$(MAKECMDGOALS))"; \
	if nix eval .#darwinConfigurations.$$TARGET 2>/dev/null >/dev/null; then \
		echo "评估 Darwin 系统构建时间: $$TARGET"; \
		time nix build .#darwinConfigurations.$$TARGET.system --dry-run --show-trace; \
	else \
		echo "评估 NixOS 系统构建时间: $$TARGET"; \
		time nix eval --raw .#nixosConfigurations.$$TARGET.config.system.build.toplevel --show-trace; \
	fi

# 便捷别名（基于常见系统）
.PHONY: laptop desktop server
laptop: laptop-asus-tx4-personal
desktop: desktop-home-rikki
server: server-vps-prod

# 部署相关命令
deploy-list:
	@echo "可用的部署配置:"
	@$(foreach deploy,$(DEPLOYS), \
		if [ -f "deploy/$(deploy).nix" ]; then \
			echo "  $(deploy) - $(shell grep 'hostname.*=' deploy/$(deploy).nix | cut -d '"' -f2)"; \
		fi; \
	)

check:
	@echo "检查所有系统配置..."
	@$(foreach system,$(SYSTEMS), \
		echo "检查系统: $(system)"; \
		if nix eval .#darwinConfigurations.$(system) 2>/dev/null >/dev/null; then \
			echo "  Darwin 系统，检查 darwinConfigurations.$(system)"; \
			nix build .#darwinConfigurations.$(system).system --dry-run --show-trace || exit 1; \
		else \
			echo "  NixOS 系统，检查 nixosConfigurations.$(system)"; \
			nix build .#nixosConfigurations.$(system).config.system.build.toplevel --dry-run --show-trace || exit 1; \
		fi; \
	)

# 通用部署目标
deploy:
	@TARGET="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$TARGET" ]; then \
		echo "Usage: make deploy <target-name>"; \
		echo "Available targets:"; \
		$(foreach deploy,$(DEPLOYS),echo "  $(deploy)";) \
		exit 1; \
	fi; \
	if [ ! -f "deploy/$$TARGET.nix" ]; then \
		echo "错误: 部署配置 deploy/$$TARGET.nix 不存在"; \
		exit 1; \
	fi; \
	echo "部署到目标: $$TARGET"; \
	nix run github:serokell/deploy-rs -- .#$$TARGET

# 防止 make 将别名参数解释为目标
%:
	@: