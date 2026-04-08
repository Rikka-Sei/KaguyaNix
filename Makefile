# 新的 Makefile - 支持自动发现系统配置

NIX := nix --extra-experimental-features 'nix-command flakes'
FLAKE_REF := path:./

# 自动扫描 systems 目录获取所有可用系统
SYSTEMS := $(sort $(notdir $(patsubst %/,%,$(dir $(wildcard systems/*/meta.nix)))))

# 自动扫描 deploy 目录获取所有可用部署配置
DEPLOYS := $(basename $(notdir $(wildcard deploy/*.nix)))

# 默认目标
.PHONY: help list use update format clean-garbage eval-time check deploy-list deploy kaguya-upgrade $(SYSTEMS)

help:
	@echo "Available commands:"
	@echo "  list                 - 列出所有可用的系统配置"
	@echo "  use <system-name>    - 构建并切换到指定的系统配置"
	@echo "  update [input]       - 更新 flake inputs (可指定特定 input)"
	@echo "  format               - 格式化代码"
	@echo "  clean-garbage        - 清理垃圾"
	@echo "  eval-time <system>   - 评估构建时间"
	@echo "  check <system-name>  - 检查配置语法和依赖（可选参数）"
	@echo ""
	@echo "Deploy commands:"
	@echo "  deploy-list          - 列出所有可用的部署配置"
	@echo "  deploy <name>        - 部署到指定目标"
	@echo ""
	@echo "KaguyaNix Framework:"
	@echo "  kaguya upgrade <path> - 升级目标仓库的 KaguyaNix 框架（保留用户数据）"
	@echo ""
	@echo "Available systems:"
	@$(foreach system,$(SYSTEMS),echo "  $(system)";)

list:
	@echo "可用的系统配置:"
	@$(foreach system,$(SYSTEMS), \
		if [ -f "systems/$(system)/meta.nix" ]; then \
			echo "  $(system)"; \
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
	if [ ! -f "systems/$$TARGET/meta.nix" ]; then \
		echo "错误: 系统配置 systems/$$TARGET/meta.nix 不存在"; \
		exit 1; \
	fi; \
	echo "构建并切换到系统: $$TARGET"; \
	echo "正在检测系统类型..."; \
	if $(NIX) eval $(FLAKE_REF)#darwinConfigurations --apply 'x: builtins.hasAttr "'$$TARGET'" x' 2>/dev/null | grep -q true; then \
		echo "✅ 检测到 Darwin 系统，使用 nix run nix-darwin..."; \
		sudo env HOME=/var/root USER=root LOGNAME=root XDG_CACHE_HOME=/var/root/.cache $(NIX) run nix-darwin -- switch --flake $(FLAKE_REF)#$$TARGET --show-trace; \
	elif $(NIX) eval $(FLAKE_REF)#nixosConfigurations --apply 'x: builtins.hasAttr "'$$TARGET'" x' 2>/dev/null | grep -q true; then \
		echo "✅ 检测到 NixOS 系统，使用 nixos-rebuild..."; \
		sudo nixos-rebuild switch --flake $(FLAKE_REF)#$$TARGET --show-trace; \
	else \
		echo "❌ 错误: 无法找到系统配置 $$TARGET"; \
		echo "可用的 Darwin 系统:"; \
		$(NIX) eval $(FLAKE_REF)#darwinConfigurations --apply 'x: builtins.attrNames x' 2>/dev/null || echo "  无"; \
		echo "可用的 NixOS 系统:"; \
		$(NIX) eval $(FLAKE_REF)#nixosConfigurations --apply 'x: builtins.attrNames x' 2>/dev/null || echo "  无"; \
		exit 1; \
	fi

# 通用命令
update:
	@if [ -n "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "更新指定 flake input: $(filter-out $@,$(MAKECMDGOALS))"; \
		$(NIX) flake update $(filter-out $@,$(MAKECMDGOALS)); \
	else \
		echo "更新所有 flake inputs"; \
		$(NIX) flake update; \
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
	if $(NIX) eval $(FLAKE_REF)#darwinConfigurations.$$TARGET 2>/dev/null >/dev/null; then \
		echo "评估 Darwin 系统构建时间: $$TARGET"; \
		time $(NIX) build $(FLAKE_REF)#darwinConfigurations.$$TARGET.system --dry-run --show-trace; \
	else \
		echo "评估 NixOS 系统构建时间: $$TARGET"; \
		time $(NIX) eval --raw $(FLAKE_REF)#nixosConfigurations.$$TARGET.config.system.build.toplevel --show-trace; \
	fi

# 便捷别名（基于常见系统）
.PHONY: laptop desktop server
laptop: laptop-asus-tx4-personal
desktop: desktop-home-rikki
server: server-vps-prod

$(SYSTEMS):
	@$(MAKE) use $@

# 部署相关命令
deploy-list:
	@echo "可用的部署配置:"
	@$(foreach deploy,$(DEPLOYS), \
		if [ -f "deploy/$(deploy).nix" ]; then \
			echo "  $(deploy) - $(shell grep 'hostname.*=' deploy/$(deploy).nix | cut -d '"' -f2)"; \
		fi; \
	)

check:
	@TARGET="$(filter-out $@,$(MAKECMDGOALS))"; \
	if [ -z "$$TARGET" ]; then \
		echo "检查所有系统配置..."; \
		$(foreach system,$(SYSTEMS), \
			echo "检查系统: $(system)"; \
			if $(NIX) eval $(FLAKE_REF)#darwinConfigurations.$(system) 2>/dev/null >/dev/null; then \
				echo "  Darwin 系统，检查 darwinConfigurations.$(system)"; \
				$(NIX) build $(FLAKE_REF)#darwinConfigurations.$(system).system --dry-run --show-trace || exit 1; \
			else \
				echo "  NixOS 系统，检查 nixosConfigurations.$(system)"; \
				$(NIX) build $(FLAKE_REF)#nixosConfigurations.$(system).config.system.build.toplevel --dry-run --show-trace || exit 1; \
			fi; \
		) \
	else \
		echo "检查系统: $$TARGET"; \
		if [ ! -f "systems/$$TARGET/meta.nix" ]; then \
			echo "错误: 系统配置 systems/$$TARGET/meta.nix 不存在"; \
			exit 1; \
		fi; \
		if $(NIX) eval $(FLAKE_REF)#darwinConfigurations.$$TARGET 2>/dev/null >/dev/null; then \
			echo "  Darwin 系统，检查 darwinConfigurations.$$TARGET"; \
			$(NIX) build $(FLAKE_REF)#darwinConfigurations.$$TARGET.system --dry-run --show-trace; \
		else \
			echo "  NixOS 系统，检查 nixosConfigurations.$$TARGET"; \
			$(NIX) build $(FLAKE_REF)#nixosConfigurations.$$TARGET.config.system.build.toplevel --dry-run --show-trace; \
		fi; \
	fi

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
	$(NIX) run github:serokell/deploy-rs -- $(FLAKE_REF)#$$TARGET

# KaguyaNix 框架升级工具
kaguya:
	@SUBCMD="$(word 2,$(MAKECMDGOALS))"; \
	if [ "$$SUBCMD" = "upgrade" ]; then \
		$(MAKE) kaguya-upgrade KAGUYA_TARGET="$(word 3,$(MAKECMDGOALS))"; \
	else \
		echo "Unknown kaguya subcommand: $$SUBCMD"; \
		echo "Available subcommands:"; \
		echo "  upgrade <path> - 升级目标仓库的 KaguyaNix 框架"; \
		exit 1; \
	fi

kaguya-upgrade:
	@TARGET_PATH="$(KAGUYA_TARGET)"; \
	if [ -z "$$TARGET_PATH" ]; then \
		echo "Usage: make kaguya upgrade <target-path>"; \
		echo ""; \
		echo "此命令会将当前仓库的 KaguyaNix 框架代码同步到目标仓库"; \
		echo "同时保留目标仓库的业务数据（systems/packages/modules/hardware/deploy）"; \
		echo ""; \
		echo "⚠️  注意: 此操作会删除目标仓库的框架文件，请确保已提交所有更改！"; \
		exit 1; \
	fi; \
	\
	if [ ! -d "$$TARGET_PATH" ]; then \
		echo "❌ 错误: 目标路径不存在: $$TARGET_PATH"; \
		exit 1; \
	fi; \
	\
	if [ ! -d "$$TARGET_PATH/.git" ]; then \
		echo "❌ 错误: 目标路径不是 git 仓库: $$TARGET_PATH"; \
		exit 1; \
	fi; \
	\
	SOURCE_PATH="$$(pwd)"; \
	echo "KaguyaNix 框架升级工具"; \
	echo ""; \
	echo "源路径: $$SOURCE_PATH"; \
	echo "目标路径: $$TARGET_PATH"; \
	echo ""; \
	\
	echo "检查目标仓库状态..."; \
	cd "$$TARGET_PATH" && git status --short > /tmp/kaguya_git_status.tmp; \
	if [ -s /tmp/kaguya_git_status.tmp ]; then \
		echo ""; \
		echo "❌ 错误: 目标仓库有未提交的更改！"; \
		echo ""; \
		echo "检测到以下未提交的文件:"; \
		cat /tmp/kaguya_git_status.tmp; \
		echo ""; \
		echo "⚠️  此操作会删除目标仓库的所有框架文件（除用户数据外）"; \
		echo "为避免数据丢失，请先提交所有更改后再执行升级:"; \
		echo ""; \
		echo "  cd $$TARGET_PATH"; \
		echo "  git add ."; \
		echo "  git commit -m \"保存当前状态\""; \
		echo "  cd -"; \
		echo "  make kaguya upgrade $$TARGET_PATH"; \
		echo ""; \
		rm /tmp/kaguya_git_status.tmp; \
		exit 1; \
	fi; \
	rm -f /tmp/kaguya_git_status.tmp; \
	echo "✅ 目标仓库状态干净"; \
	echo ""; \
	\
	echo "⚠️  警告: 此操作将执行以下步骤:"; \
	echo ""; \
	echo "  1. 保留目标仓库的以下目录:"; \
	echo "     - systems/    (系统定义)"; \
	echo "     - packages/   (自定义包)"; \
	echo "     - modules/    (功能模块)"; \
	echo "     - hardware/   (硬件配置)"; \
	echo "     - deploy/     (部署配置)"; \
	echo ""; \
	echo "  2. 删除目标仓库的所有其他文件（框架文件）:"; \
	echo "     - flake.nix, flake.lock"; \
	echo "     - lib/, parts/"; \
	echo "     - Makefile"; \
	echo "     - README.md 等文档"; \
	echo ""; \
	echo "  3. 从当前仓库复制所有框架文件到目标仓库"; \
	echo ""; \
	read -p "确认要继续吗？[y/N] " -n 1 -r; \
	echo ""; \
	if [[ ! $$REPLY =~ ^[Yy]$$ ]]; then \
		echo "❌ 已取消"; \
		exit 1; \
	fi; \
	\
	echo ""; \
	echo "[步骤 1/4] 创建临时备份..."; \
	TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	BACKUP_DIR="/tmp/kaguya_upgrade_backup_$$TIMESTAMP"; \
	mkdir -p "$$BACKUP_DIR"; \
	for DIR in systems packages modules hardware deploy; do \
		if [ -d "$$TARGET_PATH/$$DIR" ]; then \
			echo "  备份: $$DIR/"; \
			cp -r "$$TARGET_PATH/$$DIR" "$$BACKUP_DIR/"; \
		fi; \
	done; \
	\
	echo ""; \
	echo "[步骤 2/4] 清理目标仓库（保留用户数据和文档）..."; \
	cd "$$TARGET_PATH"; \
	for ITEM in *; do \
		case "$$ITEM" in \
			*.md|*.lock|*.code-workspace) \
				echo "  保留: $$ITEM"; \
				;; \
			users|systems|packages|modules|hardware|deploy|.git|.gitignore) \
				;; \
			*) \
				echo "  删除: $$ITEM"; \
				rm -rf "$$ITEM"; \
				;; \
		esac; \
	done; \
	\
	echo ""; \
	echo "[步骤 3/4] 复制框架文件..."; \
	cd "$$SOURCE_PATH"; \
	for ITEM in *; do \
		case "$$ITEM" in \
			*.md|*.lock|*.code-workspace) \
				echo "  跳过: $$ITEM (保留目标仓库的版本)"; \
				;; \
			users|systems|packages|modules|hardware|deploy|.git|.DS_Store) \
				;; \
			*) \
				echo "  复制: $$ITEM"; \
				cp -r "$$ITEM" "$$TARGET_PATH/"; \
				;; \
		esac; \
	done; \
	\
	if [ -f "$$SOURCE_PATH/.gitignore" ]; then \
		echo "  复制: .gitignore"; \
		cp "$$SOURCE_PATH/.gitignore" "$$TARGET_PATH/"; \
	fi; \
	\
	echo ""; \
	echo "[步骤 4/4] 恢复用户数据..."; \
	for DIR in systems packages modules hardware deploy; do \
		if [ -d "$$BACKUP_DIR/$$DIR" ]; then \
			echo "  恢复: $$DIR/"; \
			rm -rf "$$TARGET_PATH/$$DIR"; \
			cp -r "$$BACKUP_DIR/$$DIR" "$$TARGET_PATH/"; \
		fi; \
	done; \
	\
	echo ""; \
	echo "✅ 升级完成"; \
	echo ""; \
	echo "目标仓库变更:"; \
	cd "$$TARGET_PATH" && git status --short | head -30; \
	echo ""; \
	echo "后续步骤:"; \
	echo "  1. cd $$TARGET_PATH"; \
	echo "  2. git diff        # 检查更改内容"; \
	echo "  3. make check      # 验证配置正确性"; \
	echo "  4. git add .       # 添加更改"; \
	echo "  5. git commit -m \"chore: 升级 KaguyaNix 框架到最新版本\""; \
	echo ""; \
	echo "备份位置: $$BACKUP_DIR"; \
	echo "(可在确认无误后手动删除)"

# 防止 make 将别名参数解释为目标
%:
	@:
