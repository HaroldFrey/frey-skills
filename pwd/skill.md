---
name: pwd
description: 打印当前工作目录路径，以及当前 session 涉及的所有目录
---

当用户调用这个 skill 时，执行以下操作：

1. 使用 PowerShell 执行 `Get-Location`，获取当前工作目录的完整路径
2. 列出当前 session 涉及的关键目录：
   - 当前工作目录
   - Claude Code 配置目录（`C:\Users\28968\.claude\`）
   - Skills 目录（用户级 + 项目级）
   - 当前项目的工作目录（`d:\Stduy`）
3. 以清晰的格式分组展示：当前目录、配置目录、工程目录
