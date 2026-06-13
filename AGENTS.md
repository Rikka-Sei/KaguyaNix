# KaguyaNix Development Guide

## Build / Check Commands

- `make list` - 列出所有可用系统
- `make use <system-name>` - 构建并切换到指定系统
- `make update [input]` - 更新 flake inputs
- `make format` - 格式化代码
- `make clean-garbage` - 清理垃圾
- `make eval-time <system>` - 评估构建时间
- `make check <system-name>` - 检查配置语法与依赖
- `make deploy-list` - 列出部署目标
- `make deploy <name>` - 部署到指定目标
- `make kaguya upgrade <path>` - 升级目标仓库的 KaguyaNix 框架

## Code Style

- 使用中文编写注释和文档
- 保持严肃正式语气
- 函数参数分行书写，使用尾随逗号
- 使用 `let ... in` 进行局部绑定
- 路径拼接使用 `+`
- 使用 `lib.mkForce` 处理配置冲突
- 使用 `lib.mkIf` 做条件配置
- 系统命名采用 `{设备类型}-{硬件型号}-{用途}`

## 架构概览

KaguyaNix 采用"能力图（cap graph）+ 两阶段构建"模型。

顶层结构：

- `systems/` - 宿主机定义
- `hardware/` - 硬件配置与支持表
- `caps/` - 叶子能力（cap）实现，每个目录为单一职责的原子模块
- `views/` - 聚合视图（view），纯数据，通过 `includes` / `caps` 组合叶子能力
- `packages/` - 自定义包
- `deploy/` - 部署目标
- `lib/` - 能力图（`lib/capGraph.nix`）、错误模型、框架工具
- `parts/` - flake-parts 入口

## 核心约定

### 1. System Layout

每台机器是一个目录：

```text
systems/<host>/
├── meta.nix
├── default.nix
└── users/
    └── <name>/
        ├── meta.nix
        └── default.nix
```

- `meta.nix`：第一阶段读取的纯数据入口
- `default.nix`：第二阶段导入的原生补充模块
- `users/<name>/meta.nix`：该用户在此宿主机上的实例数据
- `users/<name>/default.nix`：该用户在此宿主机上的宿主机局部补充

用户身份默认值（如 Git 配置）写在 `systems/shared/users/<name>/default.nix`，框架自动导入 home-manager，不建模为 cap。

### 2. Cap Layout（叶子能力）

```text
caps/<domain>/<name>/
├── system/
│   ├── meta.nix
│   └── module.nix
└── user/
    ├── meta.nix
    └── module.nix
```

- cap 是唯一复用实现单元
- `system` / `user` 是 facet，不是顶层分类
- `meta.nix` 负责支持表、依赖、冲突、optionPath
- `module.nix` 负责实现
- `caps/` 只允许叶子能力，不允许聚合入口或用户身份模块

### 3. View Layout（聚合视图）

```text
views/<domain>/<name>/
├── system.nix
└── user.nix
```

- view 只含纯数据，无 `module.nix`，无 `optionPath`
- 通过 `includes` 引用其他视图，通过 `caps` 引用叶子能力
- `base` / `workstation` 这类聚合名称只允许出现在 `views/` 层

示例（`views/development/base/system.nix`）：

```nix
{
  support = {
    platform = [ "linux" "darwin" ];
    arch = [ "x86_64" "aarch64" ];
  };
  includes = [ ];
  caps = [
    "development/toolchain"
    "core/cli-utils"
    "operations/network-tools"
    "operations/system-diagnostics"
  ];
}
```

### 4. User Model

用户实例数据写在宿主机内部，显式区分聚合视图与叶子能力：

```nix
{
  enable = true;
  admin = true;
  shell = "fish";
  extraGroups = [ "docker" "libvirtd" ];
  views = [
    "development/base"
    "software/workstation"
  ];
  caps = [
    "core/user-cli"
    "software/firefox"
    "software/xray"
    "software/sing-box"
  ];
}
```

用户长期偏好通过聚合视图或叶子能力复用，例如：

- 视图：`development/base`、`software/workstation`、`gaming/base`
- 叶子能力：`services/docker`、`software/firefox`、`core/user-cli`

## Two-Phase Build

### 阶段一：预构建

读取：

- `systems/*/meta.nix`
- `systems/*/users/*/meta.nix`
- `hardware/*/meta.nix`
- `caps/**/meta.nix`
- `views/**/{system,user}.nix`

完成：

- view 展开（先展开视图，得到叶子 caps，与显式 caps 合并去重）
- cap 展开与依赖解析
- 支持表校验
- 依赖 / 冲突检测
- i18n 错误生成
- `buildPlan` 冻结

### 阶段二：真实构建

导入：

- `hardware/<name>/configuration.nix`
- cap 的 `system/module.nix`
- cap 的 `user/module.nix`
- `systems/<host>/default.nix`
- `systems/<host>/users/*/default.nix`
- `systems/shared/users/*/default.nix`

## 开发要求

- 不要再引入 `systemConfig`
- 不要再创建 `profiles` 或 `per-system`
- 新的原子复用需求建模为叶子 cap（置于 `caps/`）
- 新的聚合复用需求建模为 view（置于 `views/`，纯数据）
- 用户身份默认值写在 `systems/shared/users/<name>/default.nix`，不建模为 cap
- cap 的支持范围必须写入 `meta.nix`
- 用户相关的宿主机局部补充应写在 `systems/<host>/users/<name>/default.nix`

## 验证要求

修改框架时，至少应保持以下检查通过：

- `./tests/framework-smoke.sh` 通过
- `./tests/host-user-layout.sh` 通过
- `./tests/migration-equivalence.sh` 通过
- `./tests/cleanup-check.sh` 通过
- `./tests/makefile-smoke.sh` 通过
- `./tests/deploy-smoke.sh` 通过
- `./tests/software-capabilities.sh` 通过
- `./tests/darwin-etc-compat.sh` 通过
