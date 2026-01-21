---
description: 智能 git 提交命令（带 GPG 签名）
agent: build
---

分析当前暂存的文件变更，生成符合 conventional commits 规范的提交消息，并使用 GPG 密钥签名提交。

## 执行步骤

1. 检查暂存的文件变更：
!`git diff --staged --name-status`

2. 查看详细变更内容（用于理解变更目的）：
!`git diff --staged`

3. 分析变更内容，根据以下规则确定提交类型：
   - `feat:` - 添加新功能或新文件
   - `fix:` - 修复 bug 或问题
   - `refactor:` - 重构代码（不改变功能）
   - `docs:` - 文档更新
   - `test:` - 添加或修改测试
   - `chore:` - 构建过程或辅助工具的变动
   - `style:` - 代码格式调整

4. 生成提交消息格式：
   ```
   <type>: <简短描述>
   
   - <变更详情1>
   - <变更详情2>
   ```

5. 执行签名提交命令：
   ```bash
   git -c user.signingkey=3927D7F5365B0203! commit -S -m "<生成的提交消息>"
   ```

## 约束规则

- **禁止 AI 标识**：提交消息中不得包含任何表明是 AI 助手完成的标记
- **简洁明了**：提交消息应简洁，专注于变更内容本身
- **遵循规范**：严格遵循 conventional commits 规范
- **中文描述**：使用中文描述变更内容

## 示例输出

如果暂存了以下变更：
- 添加了 `modules/desktop/gnome.nix`
- 修改了 `systems/laptop.nix`

应生成类似提交消息：
```
feat: 添加 GNOME 桌面环境模块

- 添加 modules/desktop/gnome.nix
- 更新 systems/laptop.nix 配置
```
