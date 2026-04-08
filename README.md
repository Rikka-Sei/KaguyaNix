# KaguyaNix

基于 `flake-parts` 的模块化 NixOS / nix-darwin 配置框架。

## 概述

KaguyaNix 采用“能力图 + 两阶段构建”模型：

- `systems/` 负责声明具体宿主机
- `hardware/` 负责硬件特定配置
- `modules/` 负责可复用 capability
- `packages/` 负责自定义包 overlay 与模块集成
- `deploy/` 负责远程部署配置

用户以宿主机内部实例数据的形式组织，复用单元统一为 capability。

## 目录结构

```text
.
├── flake.nix
├── systems/
│   ├── laptop-asus-tx4-personal/
│   │   ├── meta.nix
│   │   ├── default.nix
│   │   └── users/
│   │       └── rikki/
│   │           ├── meta.nix
│   │           └── default.nix
│   └── laptop-mbpM2/
│       ├── meta.nix
│       ├── default.nix
│       └── users/
│           └── rikki/
│               ├── meta.nix
│               └── default.nix
├── hardware/
│   ├── asus-tianxuan4/
│   │   ├── meta.nix
│   │   ├── configuration.nix
│   │   └── hardware-configuration.nix
│   └── mbpM2/
│       ├── meta.nix
│       └── configuration.nix
├── modules/
│   ├── development/base/{system,user}/
│   ├── desktop/gnome/system/
│   ├── identity/rikki/user/
│   └── services/docker/system/
├── packages/
├── deploy/
├── lib/
└── parts/
```

## 核心模型

### 1. 宿主机入口

每台机器使用一个目录表示：

- `systems/<host>/meta.nix`：第一阶段读取的纯数据声明
- `systems/<host>/default.nix`：第二阶段导入的原生补充模块
- `systems/<host>/users/<name>/meta.nix`：该用户在此宿主机上的实例数据
- `systems/<host>/users/<name>/default.nix`：该用户在此宿主机上的原生补充模块

示例：

```nix
{
  target = {
    platform = "linux";
    arch = "x86_64";
  };

  hardware = "asus-tianxuan4";
  locale = "zh-CN";

  capabilities = [
    "desktop/gnome"
    "services/docker"
    "development/base"
  ];

  users.rikki = import ./users/rikki/meta.nix;
}
```

字段说明：

| 字段 | 作用 | 阶段 |
| --- | --- | --- |
| `target.platform` | 声明目标平台，决定使用 `nixosSystem` 还是 `darwinSystem`，并参与 capability / hardware 支持表校验。 | 第一阶段 |
| `target.arch` | 声明目标架构，参与 capability / hardware 支持表校验，并形成最终 `system` 标识。 | 第一阶段 |
| `hardware` | 指向 `hardware/<name>/` 目录，用于加载硬件支持表与第二阶段的 `configuration.nix`。 | 第一、二阶段 |
| `locale` | 选择错误信息的本地化语言；当前主要影响框架错误输出。 | 第一阶段 |
| `capabilities` | 宿主机级 capability 列表，只能放系统侧复用能力，例如桌面、服务、输入设备支持。 | 第一阶段 |
| `users` | 宿主机上的用户实例集合，值通常来自 `./users/<name>/meta.nix`。 | 第一阶段 |

约束：

- `meta.nix` 必须保持为纯数据入口，不应写原生模块逻辑。
- 宿主机局部但不适合建模为 capability 的补充，应写入 `systems/<host>/default.nix`。

### 2. Capability

一个 capability 对应 `modules/<domain>/<name>/` 一个目录。

capability 可以有两个 facet：

- `system/`：作用于系统模块图
- `user/`：作用于 Home Manager 模块图

每个 facet 必须包含：

- `meta.nix`：支持表、依赖、冲突、默认 option 路径
- `module.nix`：真正的实现模块

示例：

```text
modules/development/base/
├── system/
│   ├── meta.nix
│   └── module.nix
└── user/
    ├── meta.nix
    └── module.nix
```

### 3. 用户模型

用户不再是独立的全局目录层，而是宿主机内部的数据实例：

```nix
{
  enable = true;
  admin = true;
  shell = "fish";
  extraGroups = [ "docker" "libvirtd" ];
  capabilities = [
    "identity/rikki"
    "development/base"
    "software/workstation"
    "software/network-access"
  ];
  overrides = {
    kaguya.programs.git.email = "rikki@member.fsf.org";
  };
}
```

字段说明：

| 字段 | 作用 | 阶段 |
| --- | --- | --- |
| `enable` | 控制该用户实例是否参与构建。关闭后，框架不会为该用户生成用户模块。 | 第一阶段 |
| `admin` | 声明该用户是否应具备管理员权限；框架会在第二阶段映射到系统用户配置。 | 第一、二阶段 |
| `shell` | 声明用户登录 shell，当前允许值由框架固定枚举控制。 | 第一阶段 |
| `extraGroups` | 用户需要加入的额外系统组，例如 `docker`、`libvirtd`。 | 第一、二阶段 |
| `capabilities` | 用户态 capability 列表，用于展开 Home Manager 侧复用能力。 | 第一阶段 |
| `overrides` | 注入到 `kaguya.*` 命名空间的覆写值，用于宿主机实例对 capability 默认值做局部修正。 | 第二阶段 |
| `stateVersion` | 该用户实例的 Home Manager 状态版本，默认值为 `24.05`。 | 第一、二阶段 |
| `homeDirectory` | 显式指定用户主目录；未填写时按平台自动推导。 | 第一、二阶段 |

用户的长期偏好通过 capability 复用，例如：

- `identity/rikki`
- `software/workstation`
- `software/network-access`
- `development/base`

## 两阶段构建

### 阶段一：预构建解析

输入：

- `systems/<host>/meta.nix`
- `systems/<host>/users/*/meta.nix`
- `hardware/*/meta.nix`
- `modules/**/meta.nix`

职责：

- 解析目标平台与架构
- 校验 capability 是否存在
- 校验 facet 是否存在
- 校验 capability / hardware 的平台与架构支持表
- 展开 capability 依赖图
- 检测冲突与循环
- 生成冻结的 `buildPlan`
- 输出本地化错误

### 阶段二：真实构建

输入：

- 第一阶段生成的 `buildPlan`
- `systems/<host>/default.nix`
- `systems/<host>/users/*/default.nix`
- `hardware/<name>/configuration.nix`
- capability 的 `module.nix`

职责：

- 选择 `nixosSystem` 或 `darwinSystem`
- 导入系统 facet 模块
- 为每个用户导入 user facet 模块
- 注入 `kaguya.*` 覆写
- 进入正常的 Nix 模块 fixed-point

## 元数据约束

每个 facet 的 `meta.nix` 必须返回：

```nix
{
  optionPath = [ "kaguya" "services" "docker" ];

  support = {
    platform = [ "linux" ];
    arch = [ "x86_64" "aarch64" ];
  };

  requires = [ ];
  conflicts = [ ];
}
```

字段说明：

| 字段 | 作用 |
| --- | --- |
| `optionPath` | 该 capability 默认启用时写入的 option 路径。框架会在展开 capability 图后自动注入 `${optionPath}.enable = true`。 |
| `support.platform` | 该 facet 支持的平台列表，构建目标若不在列表内会直接报错。 |
| `support.arch` | 该 facet 支持的架构列表，构建目标若不在列表内会直接报错。 |
| `requires` | 当前 capability 依赖的其他 capability 列表，框架会先展开依赖，再导入当前 capability。 |
| `conflicts` | 当前 capability 不能同时启用的 capability 列表；若同时出现，第一阶段直接报错。 |

补充约定：

- `meta.nix` 只描述 capability 的静态信息，不应放置 `home.packages`、`services.*` 等实现逻辑。
- 聚合 capability 可以只通过 `requires` 组合其他 capability，而在 `module.nix` 中不直接声明配置。

固定枚举：

- `platform = linux | darwin`
- `arch = x86_64 | aarch64`

## 常用命令

- `make list`：列出所有宿主机
- `make use <system-name>`：切换到指定系统
- `make check [system-name]`：检查配置
- `make eval-time <system-name>`：评估构建时间
- `make deploy-list`：列出部署目标
- `make deploy <name>`：执行部署
- `./tests/framework-smoke.sh`：框架烟雾测试
- `./tests/host-user-layout.sh`：宿主机用户布局检查
- `./tests/migration-equivalence.sh`：迁移等价性检查

## 设计原则

- 复用单元是 capability，不是 user profile
- 平台支持必须显式写在 `meta.nix`，不能靠目录猜测
- 宿主机是最终覆盖层
- `meta.nix` 只负责数据，不承担原生模块逻辑
- `default.nix` 是 escape hatch，但不参与 capability 图解析

## 样例系统

- Linux 样例系统：`laptop-asus-tx4-personal`
- Darwin 样例系统：`laptop-mbpM2`

## 验证

- `./tests/framework-smoke.sh`
- `./tests/host-user-layout.sh`
- `./tests/migration-equivalence.sh`
- `./tests/cleanup-check.sh`
- `./tests/makefile-smoke.sh`
- `./tests/deploy-smoke.sh`
- `./tests/software-capabilities.sh`
- `./tests/darwin-etc-compat.sh`
