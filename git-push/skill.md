---
name: git-push
description: 将本地仓库推送到 GitHub。自动检测 git 仓库状态，生成 commit message，推送到远程仓库。首次推送提醒用户手动创建 GitHub 仓库。触发词：推送、推送代码、push、git push、github push、上传到GitHub、提交到GitHub。
---

# Git Push — 智能推送到 GitHub

自动完成 git add → commit → push 流程，并根据 git 状态智能判断是首次推送还是更新推送。

---

## 执行流程

### 步骤 1：检查当前目录是否为 git 仓库

执行 `git status` 检查当前目录：

- **如果是 git 仓库** → 进入步骤 2
- **如果不是** → 执行 `git init` → 提示用户先手动在 GitHub 创建仓库 → 进入步骤 2

### 步骤 2：检查远程仓库配置

执行 `git remote -v` 检查是否配置了 origin：

- **如果未配置 origin** → 提示用户：
  ```
  ⚠️ 未检测到远程仓库 origin。
  
  请先在 GitHub 上手动创建一个空仓库（不要勾选 README），然后告诉我仓库地址：
  格式：https://github.com/<用户名>/<仓库名>.git
  
  我会自动配置 origin 并推送。
  ```
  收到用户提供的地址后 → 执行 `git remote add origin <地址>` → 进入步骤 3

- **如果已配置 origin** → 进入步骤 3

### 步骤 3：暂存所有变更

执行 `git add -A`，暂存所有新增、修改、删除的文件。

### 步骤 4：自动生成 commit message

执行 `git diff --cached --stat` 获取变更摘要，根据变更内容自动生成有意义的 commit message。格式：

```
<类型>: <简要描述>

- <具体变更 1>
- <具体变更 2>
```

类型：`feat`(新功能) / `fix`(修复) / `refactor`(重构) / `docs`(文档) / `chore`(杂项)

### 步骤 5：提交

执行 `git commit -m "<自动生成的 message>"`

### 步骤 6：推送（含自动重试）

- **默认推送到 main 分支** → `git push origin main`
- **如果用户指定了其他分支** → `git push origin <指定分支>`
- **如果推送失败（如首次推送无上游）** → 执行 `git push -u origin main`

**网络重试机制**：如果推送因网络原因失败（connection reset、timeout 等），自动重试：

1. 等待 **10 秒** → 重试第 1 次
2. 仍失败 → 等待 **10 秒** → 重试第 2 次
3. 仍失败 → 等待 **10 秒** → 重试第 3 次
4. **3 次均失败** → 告知用户："网络不稳定，3 次推送均失败。commit 已在本地就绪，请稍后手动推送：`git push origin main`"

每次重试前简要提示"推送失败，10 秒后重试（第 N/3 次）..."。

---

## 用户指定分支

如果用户说"推送到 dev"或"push to feature/xxx"，则使用用户指定的分支而非默认的 main。

---

## 行为准则

1. **每一步执行前简要说明正在做什么**
2. **首次推送时务必提醒用户手动创建 GitHub 仓库**——AI 无法代替用户在 GitHub 上创建仓库
3. **生成有意义的 commit message**——不要使用 "update" 或 "fix" 这种笼统信息
4. **如果 git 操作失败，打印错误信息并停止**——不要盲目继续
