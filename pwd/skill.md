---
name: pwd
description: 打印当前工作目录的路径
---

当用户调用这个 skill 时，执行以下操作：

1. 使用 PowerShell 执行 `Get-Location` 命令，获取当前工作目录的完整路径
2. 将路径输出给用户
