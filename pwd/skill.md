---
name: pwd
description: 打印当前工作目录路径，以及当前 session 涉及的所有目录
---

当用户调用这个 skill 时，执行以下操作：

1. 使用 PowerShell 执行 `Get-Location`，获取当前工作目录的完整路径
2. 动态解析当前 session 涉及的关键目录（**不要硬编码任何路径**，全部通过环境变量和命令获取，确保任何电脑上都能用）：
   - 当前工作目录：`Get-Location`
   - Claude Code 用户配置目录：`$env:USERPROFILE\.claude\`（即用户主目录下的 `.claude`）
   - 用户级 Skills 目录：`$env:USERPROFILE\.claude\skills\`
   - 项目级 Skills 目录：当前工作目录下的 `.claude\skills\`（仅当该目录存在时列出）
   - 工程目录：当前工作目录（项目根）
3. 使用 PowerShell 检查上述目录是否存在（`Test-Path`），以清晰的格式分组展示：当前目录、配置目录、工程目录
