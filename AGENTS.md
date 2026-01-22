# KaguyaNix Development Guide

## Build/Check/Format Commands

- `make list` - 列出所有可用的系统配置
- `make use <system-name>` - 构建并切换到指定的系统配置
- `make update [input]` - 更新 flake inputs (可指定特定 input)
- `make format` - 格式化代码
- `make clean-garbage` - 清理垃圾
- `make eval-time <system>` - 评估构建时间
- `make check <system-name>` - 检查配置语法和依赖（可选参数）
- `make deploy-list` - 列出所有可用的部署配置
- `make deploy <name>` - 部署到指定目标
- `make kaguya upgrade <path>` - 升级目标仓库的 KaguyaNix 框架（保留用户数据）

## Code Style Guidelines

- 使用中文进行注释和文档编写
- 保持严肃正式的语气，禁止使用 emoji
- 函数参数分行书写，使用尾随逗号
- 使用 `let ... in` 进行局部绑定
- 路径拼接使用 `+` 操作符，不要用字符串插值
- 使用 `lib.mkForce` 处理配置冲突，使用 `lib.mkIf` 进行条件配置
- 命名约定：系统使用 `{设备类型}-{硬件型号}-{用途}` 格式

## 项目概述

KaguyaNix 是一个基于 flake-parts 的模块化 NixOS 配置管理系统，通过声明式配置语法和模块化设计，简化了 NixOS 配置的复杂性。

## 核心设计原则

### 1. 声明式配置
采用纯声明式配置语法，用户只需要描述"想要什么"，框架处理"如何实现"：
```nix
systemConfig = {
  architecture = "x86_64-linux";
  hardware = "asus-tianxuan4";
  users.rikki.profiles = [ "development" "gaming" "software" ];
  modules = [ "desktop/gnome" "services/docker" "core/fonts" ];
};
```

### 2. 分层架构设计
- **硬件配置**：`hardware/` - 设备特定的硬件配置
- **系统模块**：`modules/` - 可复用的功能模块，按功能分类
- **自定义包**：`packages/` - 按需加载的自定义包，支持 overlay 和 options
- **用户配置**：`users/` - 用户特定配置，支持 profiles 和系统覆盖
- **系统定义**：`systems/` - 声明式系统配置文件
- **部署配置**：`deploy/` - 远程部署配置，基于 deploy-rs

### 3. 约定优于配置
通过合理的目录结构和命名约定，减少显式配置：
- `users/{username}/base.nix` - 自动作为基础配置
- `users/{username}/profiles/{profile}.nix` - 按需加载的配置档案
- `users/{username}/per-system/{hostname}.nix` - 系统特定配置
- `modules/{category}/{name}.nix` - 按类别组织的模块
- `deploy/{target}.nix` - 部署目标配置，自动发现和生成

## 架构设计

### 目录结构
```
.
├── flake.nix                    # 基于 flake-parts 的主配置
├── systems/                     # 系统配置（声明式）
│   └── laptop-asus-tx4-personal.nix
├── hardware/                    # 硬件配置
│   └── asus-tianxuan4/
│       ├── configuration.nix
│       └── hardware-configuration.nix
├── modules/                     # 可复用模块
│   ├── core/                   # 核心系统模块
│   ├── desktop/                # 桌面环境
│   ├── services/               # 系统服务
│   └── development/            # 开发环境
├── packages/                   # 自定义包（按需加载）
│   └── AI-wrapper/         # AI 编程助手环境管理器
├── users/                      # 用户配置框架
│   ├── rikki/
│   │   ├── base.nix           # 基础配置
│   │   ├── profiles/          # 配置档案
│   │   └── per-system/        # 系统特定配置
│   └── root/
│       └── base.nix           # root 用户配置
├── deploy/                     # 部署配置
│   └── hk2-export.nix         # 远程部署目标配置
├── lib/                       # 框架核心
│   ├── utils.nix              # 通用工具函数
│   ├── arch.nix               # 架构判断工具
│   └── packages.nix           # 包加载器
└── parts/                     # flake-parts 模块
    ├── systems.nix            # 系统发现和生成
    └── deploy.nix             # 部署配置管理
```

### 核心框架组件

#### 1. Packages Framework (`lib/packages.nix`)
智能包管理系统：
- **自动扫描** - 扫描 `packages/` 目录，支持目录和单文件形式
- **Overlay 注入** - 自动将包注入到 `pkgs` 命名空间
- **Options 集成** - 合并所有包的 options 和 config
- **按需加载** - 只有被引用或 enable 的包才会构建
- **无感使用** - 用户可以直接使用 `pkgs.<package-name>` 或配置 `programs.<package-name>.enable`

#### 2. User Framework (`lib/utils.nix`)
智能用户配置管理：
- 自动加载用户基础配置
- 按需加载 profiles
- 系统特定配置覆盖
- 完全无侵入式设计

#### 3. Systems Auto-Discovery (`parts/systems.nix`)
基于 flake-parts 的系统发现机制：
- 自动扫描 `systems/` 目录
- 动态生成 nixosConfigurations 和 darwinConfigurations
- 多架构支持（Linux 和 macOS）
- 集成 packages overlay 和模块系统

## 关键技术实现

### 1. 智能路径解析
```nix
# 框架自动将字符串转换为路径
hardware = "asus-tianxuan4";
# 解析为：../hardware/asus-tianxuan4/configuration.nix

modules = [ "desktop/gnome" "services/docker" ];
# 解析为：[ ../modules/desktop/gnome ../modules/services/docker.nix ]
```

### 2. 用户配置组合算法
```nix
# 对于用户 "rikki" 和系统 "laptop-asus-tx4-personal"
baseConfig = ../users/rikki/base.nix;
profileConfigs = map (p: ../users/rikki/profiles/${p}.nix) profiles;
systemConfig = ../users/rikki/per-system/laptop-asus-tx4-personal.nix;
# 最终：baseConfig ++ profileConfigs ++ systemConfig
```

### 3. 多架构支持
通过 flake-parts 实现原生多架构支持：
```nix
systems = [ "x86_64-linux" "aarch64-linux" ];
```

### 4. 自动化构建和部署系统
基于 Makefile 的统一命令接口：
```makefile
# 自动发现系统和部署配置
SYSTEMS := $(basename $(notdir $(wildcard systems/*.nix)))
DEPLOYS := $(basename $(notdir $(wildcard deploy/*.nix)))
```

**本地系统管理**：
- `make use <system-name>` - 构建并切换到指定系统配置
- `make list` - 列出所有可用系统配置
- `make check` - 检查所有系统配置语法和依赖

**远程部署管理**：
- `make deploy <target>` - 部署到指定目标（基于 deploy-rs）
- `make deploy-list` - 列出所有可用部署配置

### 5. 自定义包管理系统
**设计目标**：在 nixpkgs 之外管理自定义包，同时保持声明式和按需加载。

**核心机制**：
- 自动扫描 `packages/` 目录生成 overlay 和模块
- 包既可通过 `pkgs.<name>` 直接引用，也可通过 options 配置
- Lazy evaluation 确保只有被使用的包才会构建

**典型应用**：AI 编程助手环境管理器，为不同 API 端点提供环境切换功能。

### 6. 部署框架集成
基于 deploy-rs 实现声明式远程部署：
```nix
# deploy/hk2-export.nix
{
  hostname = "156.251.180.234";
  system = "hk2-export";           # 引用 systems/ 中的配置
  sshUser = "root";
  autoRollback = true;             # 自动回滚保护
  magicRollback = true;            # 网络断开回滚
}
```

## 迁移策略

### 1. 渐进式迁移
- 保持原有配置结构不变
- 逐步将配置拆分为模块
- 最后删除旧的配置文件

### 2. 配置分类重组
- **系统级配置** → `modules/`
- **用户级配置** → `users/{username}/profiles/`
- **硬件特定** → `hardware/{device}/`
- **应用软件** → `users/{username}/profiles/software.nix`

### 3. 标签系统设计
采用明确的命名约定：
- `{设备类型}-{硬件型号}-{用途}` 如 `laptop-asus-tx4-personal`
- 避免用户名作为系统标识符，支持多用户场景

## 设计思考与原则

### 1. 复杂性管理
**问题**：NixOS 配置随着功能增加变得复杂难维护
**解决**：将复杂性分层管理
- 用户层：极简声明式配置
- 框架层：复杂的路径解析和模块组合
- 实现层：具体的 NixOS 配置

### 2. 可扩展性设计
**问题**：如何支持不同设备、用户、架构
**解决**：
- 硬件配置分离到独立目录
- 用户配置支持 profiles 组合
- 多架构原生支持

### 3. 用户体验优化
**问题**：配置文件冗长，路径繁琐
**解决**：
- 字符串标识符替代复杂路径
- 约定优于配置
- 自动发现和组合

### 4. 维护性提升
**问题**：模块间依赖复杂，难以重构
**解决**：
- 清晰的模块边界
- 标准化的模块接口
- 自动化的依赖管理

## 经验总结

### 成功经验
1. **框架设计**：无侵入式框架设计，用户配置保持简洁
2. **路径抽象**：字符串标识符大大简化了配置复杂度
3. **分层架构**：清晰的职责分离，便于维护和扩展
4. **自动化工具**：Makefile 自动发现系统，提升使用体验

### 设计挑战
1. **路径解析**：动态路径解析的实现复杂性
2. **配置组合**：用户配置的组合顺序和覆盖逻辑
3. **错误处理**：配置错误的诊断和提示
4. **性能优化**：大量动态导入的性能影响

### 改进方向
1. **错误提示**：增加更友好的配置错误提示
2. **文档生成**：自动生成可用模块和配置选项文档
3. **配置验证**：添加配置语法和语义验证
4. **模板系统**：提供常见配置场景的模板


## 实施过程中的挑战与解决方案

### 主要技术挑战

#### 1. NixOS 模块系统限制
**问题**：不能在 `config` 块中动态设置 `imports`，这会导致无限递归。
```nix
# ❌ 错误的做法
config = {
  imports = lib.flatten (
    lib.mapAttrsToList (username: userCfg: [...]) config.systemConfig.users
  );
};
```

**解决方案**：将动态模块生成移到 `parts/systems.nix` 中，在 `nixosSystem` 调用时静态生成模块列表。
```nix
# ✅ 正确的做法
modules = [
  ../lib/system-framework.nix
  ../lib/user-framework.nix
  ../systems/${systemFile}
] ++ systemModules ++ userModules;
```

#### 2. 路径解析问题
**问题**：字符串路径不能直接用于 Nix imports，需要是真正的路径类型。
```nix
# ❌ 错误
hardwareModule = "../hardware/${config.hardware}/configuration.nix";
```

**解决方案**：使用路径连接操作符 `+` 来构造真正的路径。
```nix
# ✅ 正确
hardwareModule = ../hardware + "/${systemConfig.hardware}/configuration.nix";
```

#### 3. 配置冲突处理
**问题**：用户配置在不同层级定义相同选项时产生冲突。
```
error: The option `home-manager.users.rikki.programs.git.userEmail' has conflicting definition values
```

**解决方案**：使用 `lib.mkForce` 在系统特定配置中覆盖基础配置。
```nix
programs.git = {
  userEmail = lib.mkForce "rikki@laptop.local";
};
```

#### 4. Flake 输出格式变化
**问题**：不同版本的 flake 有不同的输出结构，`defaultPackage` 可能不存在。
```nix
# ❌ 旧格式
inputs.nil.defaultPackage.${pkgs.system}

# ✅ 新格式
inputs.nil.packages.${pkgs.system}.default
```

#### 5. Packages 框架的 Overlay-Config 循环依赖
**问题**：Overlay 阶段需要构建包，但无法访问 `config`（模块系统尚未初始化）。

**解决方案**：函数封装 + 分阶段构建
- Overlay 阶段：生成使用默认参数的包
- Config 阶段：根据用户配置动态构建包
- 通过提取构建逻辑为函数，避免代码重复

这种设计保证了既能提供默认包（`pkgs.<name>`），又能根据用户配置定制。

### 架构演进记录

#### 第一次尝试：直接在框架中设置 imports
- **方法**：在 `lib/user-framework.nix` 的 `config` 块中动态设置 `imports`
- **结果**：失败，NixOS 模块系统不允许这种循环依赖
- **教训**：必须理解 NixOS 模块系统的评估顺序

#### 第二次尝试：在顶层设置 imports
- **方法**：将 imports 移到模块的顶层
- **结果**：仍然失败，因为依赖于配置选项的值
- **教训**：`imports` 必须是静态的，不能依赖配置

#### 最终方案：外部生成模块列表
- **方法**：在 `parts/systems.nix` 中静态生成所有模块
- **结果**：成功，符合 Nix 的评估模型
- **优势**：清晰的依赖关系，易于调试

## 技术债务与反思

### 已解决的技术债务
1. **模块系统理解不足** ✅ - 通过实践深入理解了 NixOS 模块系统的限制
2. **路径处理错误** ✅ - 正确使用 Nix 路径连接操作符
3. **配置冲突处理** ✅ - 建立了优先级机制

### 当前技术债务
1. **配置验证不足**：缺乏运行时配置验证
2. **错误信息不友好**：Nix 原生错误信息对用户不够友好
3. **文档生成缺失**：需要自动化文档生成机制

### 架构反思
1. **过度抽象的风险**：需要平衡抽象程度和灵活性
2. **约定的一致性**：需要确保所有约定的一致性和文档化
3. **性能考虑**：大量动态导入可能影响评估性能
4. **调试复杂性**：动态生成的模块增加了调试难度


## 结论

本次重构虽然遇到了一些 NixOS 模块系统的深层技术挑战，但成功地将一个传统的 NixOS 配置转换为现代化的、高度可复用的配置框架。

通过这次实践，我们深入理解了：
- NixOS 模块系统的评估顺序和限制
- Nix 语言中路径处理的正确方式
- 如何在复杂系统中处理配置冲突
- flake 生态系统的演进和兼容性问题

这个框架不仅解决了当前的配置复杂性问题，还为未来的扩展和演进奠定了坚实的基础。更重要的是，它展示了如何在面对技术挑战时系统性地分析问题、迭代解决方案，为社区提供了一个值得参考的配置管理方案。

**核心价值**：
- 🎯 **声明式配置** - 用户只需要描述"想要什么"，框架处理"如何实现"
- 🔧 **模块化设计** - 清晰的职责分离，易于维护和扩展
- 🚀 **自动化流程** - 从配置编写到系统构建的全自动化流程
- 📚 **知识沉淀** - 详细记录设计思路和解决方案，便于传承