# 叶子模块与聚合视图设计

> **SUPERSEDED**：由 docs/superpowers/specs/2026-06-11-cap-view-architecture-design.md 及其计划 2026-06-11-cap-view-architecture.md 取代。

## 背景

当前 KaguyaNix 的 `modules/` 同时混杂了三类完全不同的东西：

1. 叶子能力实现
2. 聚合入口
3. 用户身份与个人默认值

这种混合导致几个长期问题：

- `identity/rikki` 将具体用户身份放进了能力层，破坏“模块即能力”的边界。
- `development/base`、`gaming/base`、`software/workstation` 既像能力，又像视图，目录结构无法表达它们不是叶子。
- `business/common`、`lifetime/common`、`software/communication`、`software/creative` 这类命名既不够具体，也掩盖了内部其实是多个不相关软件或单个软件的事实。
- 宿主机与用户实例的真实意图被折叠进模块命名中，人需要先猜模块性质，再猜它到底是叶子还是聚合。

## 设计目标

1. `modules/` 只保留叶子能力。
2. 聚合关系使用独立结构表达，而不是伪装成叶子模块。
3. 用户身份与个人默认值从模块层移出，回到 `systems/` 下的用户实例层。
4. 用户态软件能力优先使用“具体应用名”而非抽象类别名，减少理解负担。
5. 宿主机与用户实例的数据结构显式区分“叶子能力选择”和“聚合视图选择”。

## 非目标

1. 不改动“两阶段构建”这一根本模型。
2. 不引入 profile 或 per-system 旧机制。
3. 不要求所有系统能力在第一轮都完全原子化，但所有“聚合入口”必须结构上与叶子分离。

## 核心原则

### 1. `modules/` 只放叶子

叶子模块必须满足：

- 单一职责
- 直接拥有实现
- 能在不知道调用方是谁的情况下自洽

允许的例子：

- `services/docker`
- `services/tailscale`
- `core/input`
- `software/firefox`
- `software/logseq`
- `development/toolchain`

不允许的例子：

- `identity/rikki`
- `development/base`
- `gaming/base`
- `software/workstation`
- `business/common`
- `lifetime/common`

### 2. 聚合必须结构分离

新增 `views/` 目录承载聚合视图。

建议结构：

```text
views/<domain>/<name>/
├── system.nix
└── user.nix
```

每个视图文件只返回纯数据，例如：

```nix
{
  support = {
    platform = [ "linux" "darwin" ];
    arch = [ "x86_64" "aarch64" ];
  };

  includes = [ ];

  capabilities = [
    "software/thunderbird"
    "software/gimp"
  ];
}
```

其中：

- `includes` 表示其他视图
- `capabilities` 表示叶子能力

视图不再有 `module.nix`，也不再定义 `optionPath`。

### 3. `base` / `workstation` 只允许出现在视图层

一旦引入 `views/`：

- `views/development/base`
- `views/gaming/base`
- `views/software/workstation`

是合理的；

但：

- `modules/development/base`
- `modules/gaming/base`
- `modules/software/workstation`

就不再合理。

### 4. 用户身份回到 `systems/`

用户身份相关的内容不属于能力层。

以下内容应迁出 `modules/identity/rikki`：

- Git 用户名
- Git 邮箱
- Git 签名 key
- 用户特有的提交签名偏好

推荐落点：

```text
systems/shared/users/rikki/
├── default.nix
└── meta.nix   # 如确有共享纯数据需求
```

然后在具体宿主机用户路径中导入：

```text
systems/laptop-mbpM2/users/rikki/default.nix
systems/laptop-asus-tx4-personal/users/rikki/default.nix
```

这样身份仍然可以跨宿主机共享，但它属于“用户实例层复用”，不是“能力层复用”。

### 5. 用户态应用叶子优先使用应用名

为减少抽象分类带来的理解负担，用户态软件叶子优先使用具体应用名：

- `software/firefox`
- `software/tor-browser`
- `software/thunderbird`
- `software/qq`
- `software/feishu`
- `software/signal-desktop`
- `software/gimp`
- `software/typst`
- `software/kdenlive`
- `software/typora`
- `software/filezilla`
- `software/remmina`
- `software/anki`
- `software/calibre`
- `software/logseq`
- `software/xray`
- `software/sing-box`
- `software/v2rayn`
- `software/ghidra`
- `software/gnucash`
- `software/spotify`
- `software/vscode`
- `software/gemini-cli`
- `software/obs-studio`
- `software/osu-lazer`
- `software/hmcl`
- `software/mindustry`
- `software/ddnet`

只有存在稳定技术耦合时，才允许一个叶子模块包含多个包，例如：

- `software/ghidra` 可以同时携带对应扩展
- `development/toolchain` 可以同时携带多个紧耦合开发工具

## 新的数据模型

### 宿主机 `meta.nix`

宿主机与用户实例均显式区分：

- `views`
- `capabilities`

例如：

```nix
{
  target = {
    platform = "linux";
    arch = "x86_64";
  };

  hardware = "asus-tianxuan4";
  locale = "zh-CN";

  views = [
    "development/base"
    "gaming/base"
  ];

  capabilities = [
    "desktop/gnome"
    "services/docker"
    "services/flatpak"
    "services/vm"
    "services/tailscale"
    "services/cups"
    "core/fonts"
    "core/input"
    "development/emacs"
  ];

  users.rikki = import ./users/rikki/meta.nix;
}
```

### 用户 `meta.nix`

用户实例同样区分：

- `views`
- `capabilities`

例如：

```nix
{
  enable = true;
  admin = true;
  shell = "fish";

  views = [
    "development/base"
    "software/workstation"
  ];

  capabilities = [
    "software/firefox"
    "software/xray"
    "software/sing-box"
    "software/logseq"
    "software/gnucash"
    "software/spotify"
  ];
}
```

这意味着：

- 叶子能力选择是显式的
- 聚合视图选择也是显式的
- 目录层已经告诉你“这是叶子还是视图”

## 视图解析规则

需要在 `lib/capabilityGraph.nix` 中新增视图解析：

1. 读取 `viewsDir`
2. 根据 facet 加载 `views/<domain>/<name>/<facet>.nix`
3. 校验 `support.platform` / `support.arch`
4. 展开 `includes`
5. 汇总叶子 `capabilities`
6. 再将最终 capability 列表交给现有 capability 解析逻辑

视图解析需要支持：

- 未知视图报错
- 缺失 facet 报错
- 视图循环检测
- 平台与架构支持表校验

## 模块迁移方向

### 立即迁移为视图

- `modules/development/base` -> `views/development/base`
- `modules/gaming/base` -> `views/gaming/base`
- `modules/software/workstation` -> `views/software/workstation`

### 立即删除的人名模块

- `modules/identity/rikki`

### 立即清理的弱语义模块

- `modules/business/common`
- `modules/lifetime/common`
- `modules/software/base-cli`
- `modules/software/browser`
- `modules/software/communication`
- `modules/software/creative`
- `modules/software/desktop-tools`
- `modules/software/learning`
- `modules/software/network-access`
- `modules/software/remote-access`
- `modules/software/reverse-engineering`

这些模块要么迁移为具体应用叶子，要么被视图吸收。

## 迁移后的直觉收益

1. 看 `modules/` 就知道全是叶子。
2. 看 `views/` 就知道全是组合。
3. 看 `systems/.../users/...` 就知道那里是用户实例与身份数据。
4. 看 `software/firefox` 比看 `software/browser` 更直接。
5. 看 `views/software/workstation` 比看 `modules/software/workstation` 更直觉，因为它本来就是视图。

## 特殊约束

### `laptop-mbpM2` 不安装 Firefox

在新模型中，这不再需要 override 某个“浏览器模块内部选项”。

实现方式应为：

- `laptop-asus-tx4-personal/users/rikki/meta.nix` 显式选择 `software/firefox`
- `laptop-mbpM2/users/rikki/meta.nix` 不选择 `software/firefox`

这正是“显式叶子能力选择”的好处。
