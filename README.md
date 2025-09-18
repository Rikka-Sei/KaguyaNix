# KaguyaNix

基于 flake-parts 的模块化 NixOS 配置管理系统。

## 概述

本框架实现了一套声明式的 NixOS 配置管理方案，通过一定的抽象来隐藏底层的复杂性，提供简化的配置语法。

框架采用分层架构设计，将系统配置、用户环境和硬件特定配置分离管理。

设计中，使用了 “约定优于配置” 和 “显式优于隐式” 的思想

## 框架设计

### 目录结构

```
.
├── flake.nix              # flake-parts 配置入口
├── systems/               # 系统配置定义
├── users/                 # 用户配置框架
│   └── {username}/
│       ├── base.nix       # 基础用户配置
│       ├── profiles/      # 可组合的用户环境
│       └── per-system/    # 系统特定覆盖
├── modules/               # 可复用系统模块
│   ├── core/             # 核心系统组件
│   ├── desktop/          # 桌面环境配置
│   ├── services/         # 系统服务配置
│   └── development/      # 开发环境配置
├── hardware/             # 硬件特定配置
├── deploy/               # 远程部署配置
└── lib/                  # 框架核心实现
```

### 系统配置
`systems` 目录存储着所有的系统配置，一个最基础的配置如下所示：

```nix
{
  networking.hostName = "laptop-asus-tx4-personal";

  systemConfig = {
    architecture = "x86_64-linux";
    hardware = "asus-tianxuan4";

    users = {
      rikki.profiles = [
        "development"
        "software"
        "gaming"
      ];
    };

    modules = [
      "desktop/gnome"
      "services/docker"
      "services/flatpak"
      "services/vm"
      "core/fonts"
      "core/input"
      "development/base"
    ];
  };

  # 系统级配置
  time.timeZone = "Asia/Shanghai";

  networking = {
    networkmanager.enable = true;
    firewall.enable = false;
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "rikki"
    ];
  };

  system.stateVersion = "24.05";
}
```

在本框架中，如果文件 `systems/${name}.nix`（如：`systems/laptop-asus-tx4-personal.nix`） 存在，就可以使用 `make use ${name}` 来应用该配置。

其他配置项均来自 nixpkgs，可以通过查阅 https://search.nixos.org/options 来了解。

在示例中， `systemConfig` 是本框架专属的配置项目。

关于 `systemConfig` ：

+ `architecture` 用于指定该配置所适用的硬件架构
  + 出于 “显式优于隐式” 的设计，尽管硬件架构和硬件配置应该是强相关的，但是并没有让这个配置放入 `hardware/${hardware-name}/configuration.nix` 中

+ `hardware` 用于指定硬件配置名称
  + 框架会自动将字符串映射到 `hardware/${hardware-name}/configuration.nix` 路径
  + 例如 `hardware = "asus-tianxuan4"` 会加载 `hardware/asus-tianxuan4/configuration.nix`
  + 硬件配置目录还应包含 `hardware-configuration.nix`（由 nixos-generate-config 生成）

+ `users` 用于定义系统用户及其配置档案
  + 每个用户可以指定多个 profiles，这些 profiles 会按顺序组合加载
  + 框架会自动加载 `users/{username}/base.nix` 作为基础配置
  + profiles 从 `users/{username}/profiles/{profile}.nix` 加载
  + 系统特定配置可放在 `users/{username}/per-system/{hostname}.nix`

+ `modules` 用于指定要加载的系统功能模块
  + 支持字符串路径，框架会自动解析为实际文件路径
  + 例如 `"desktop/gnome"` 解析为 `modules/desktop/gnome.nix` 或 `modules/desktop/gnome/default.nix`
  + 模块按功能分类组织，便于复用和维护

`systemConfig` 是本系统的核心，它实现了一套组合系统，通过声明式配置，根据约定，从对应文件夹加载相应配置。


### 用户环境配置

#### 基础配置 (`users/{username}/base.nix`)

```nix
{ pkgs, inputs, ... }:
let
  userName = "username";
in {
  users.users.${userName} = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  home-manager.users.${userName} = {
    home.username = userName;
    home.homeDirectory = "/home/${userName}";
    home.stateVersion = "24.05";
    programs.home-manager.enable = true;
  };
}
```

#### 配置档案 (`users/{username}/profiles/{profile}.nix`)

```nix
{ pkgs, inputs, ... }:
let
  userName = "username";
in {
  home-manager.users.${userName} = {
    programs.git = {
      enable = true;
      userName = "User Name";
      userEmail = "user@example.com";
    };
  };
}
```

#### 特定系统配置的特调文件 (`users/{username}/per-system/{system-profile}.nix`)

当用户需要在特定系统上覆盖或调整配置时，可以使用系统特定配置文件。这些文件会在基础配置和 profiles 之后加载，具有最高优先级。

```nix
{ pkgs, inputs, lib, ... }:
let
  userName = "username";
in {
  # 覆盖基础配置中的 Git 邮箱
  home-manager.users.${userName} = {
    programs.git = {
      userEmail = lib.mkForce "user@work.com";  # 工作环境使用工作邮箱
    };

    # 系统特定的环境变量
    home.sessionVariables = {
      WORK_ENV = "production";
      DATABASE_URL = "postgresql://localhost/work_db";
    };

    # 只在特定系统启用的程序
    programs.vscode = {
      enable = true;
      extensions = with pkgs.vscode-extensions; [
        ms-vscode-remote.remote-ssh
      ];
    };
  };

  # 系统级的特定配置
  networking.extraHosts = ''
    192.168.1.100 internal-server.local
  '';
}
```

**使用场景：**
- **工作环境特定配置**：不同的邮箱、代理设置、SSH 密钥等
- **硬件特定调优**：针对特定硬件的性能调优配置
- **网络环境适配**：不同网络环境的代理、DNS 配置
- **开发环境差异**：开发、测试、生产环境的不同配置

**文件命名规则：**
文件名必须与系统配置文件名（去掉 `.nix` 后缀）完全一致，例如：
- 系统配置文件：`systems/laptop-asus-tx4-personal.nix`
- 对应文件：`users/rikki/per-system/laptop-asus-tx4-personal.nix`

**注意**：这与系统的 `networking.hostName` 通常是一致的，但不是严格要求。框架是基于配置文件名而不是 hostName 来查找 per-system 文件。


### 硬件配置

在 `hardware/{device-name}/` 目录存放硬件特定配置：

- `configuration.nix`: 硬件相关的系统配置
- `hardware-configuration.nix`: nixos-generate-config 生成的硬件配置

### 系统模块

在 `modules/` 相应分类目录下创建功能模块：

```nix
{ pkgs, ... }: {
  services.example.enable = true;
  
  environment.systemPackages = with pkgs; [
    example-package
  ];
}
```

## 框架实现

### 路径解析机制

框架自动将字符串标识符转换为 Nix 路径：

```nix
# 输入
hardware = "asus-tianxuan4";
modules = [ "desktop/gnome" "services/docker" ];

# 解析结果
../hardware/asus-tianxuan4/configuration.nix
[ ../modules/desktop/gnome ../modules/services/docker.nix ]
```

### 用户配置组合

用户配置按以下顺序组合，后加载的配置覆盖前面的配置：

1. `users/{username}/base.nix` - 基础配置
2. `users/{username}/profiles/{profile}.nix` - 档案配置（按列表顺序）
3. `users/{username}/per-system/{hostname}.nix` - 系统特定配置

### 系统发现机制

基于 flake-parts 的自动系统发现：

- 扫描 `systems/` 目录下的 `.nix` 文件
- 动态生成 `nixosConfigurations` 输出

## 配置管理

### 添加新系统

1. 在 `systems/` 创建配置文件
2. 定义 `systemConfig` 属性
3. 设置系统级配置选项

### 添加新用户

1. 在 `users/` 创建用户目录
2. 创建 `base.nix` 基础配置
3. 根据需要创建 profiles
4. 在系统配置中引用用户和档案

### 创建模块

1. 在 `modules/` 相应分类下创建模块文件
2. 实现模块功能配置
3. 在系统配置的 `modules` 列表中引用

### 支持新硬件

1. 在目标系统运行 `nixos-generate-config`
2. 将生成配置复制到 `hardware/{device-name}/`
3. 在系统配置中设置对应的 `hardware` 值

### 配置远程部署

在 `deploy/` 目录创建部署配置文件：

```nix
# deploy/example.nix
{
  # 部署配置：香港 VPS hk2-export
  hostname = "131.24.21.234"; # 也可以是 Domain
  system = "hk2-export"; # systems 目录下的 profile 名

  # SSH 配置
  sshUser = "root";
  sshOpts = [
    "-o"
    "StrictHostKeyChecking=no"
  ];

  # 部署选项
  fastConnection = false; # 海外服务器，网络可能较慢
  autoRollback = true; # 自动回滚
  magicRollback = true; # 魔法回滚（网络断开时）
}
```

**配置步骤：**
1. 在 `deploy/` 创建部署配置文件
2. 设置目标主机信息和 SSH 配置
3. 指定要部署的系统配置名称
4. 使用 `make deploy <target-name>` 进行部署


## 构建和部署

### 本地系统管理

```bash
# 列出可用系统配置
make list

# 构建并切换到指定系统
make use <system-name>

# 检查所有系统配置
make check

# 更新依赖
make update

# 代码格式化
make format

# 垃圾回收
make clean-garbage
```

### 远程部署管理

基于 deploy-rs 实现声明式远程部署：

```bash
# 列出可用部署配置
make deploy-list

# 部署到指定目标
make deploy <target-name>
```


