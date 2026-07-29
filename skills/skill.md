---
name: skills
description: 列出所有已安装的 skill，显示名称、分类和简要功能说明。输入 /skills 即可查看。
---

当用户调用这个 skill 时，执行以下操作：

## 扫描范围

扫描当前 skill 文件所在 skills 根目录下的所有子目录。你可以通过以下方式定位：

- 当前文件路径为 `<skills_root>/skills/skill.md`，取其父目录的父目录即为 skills 根目录
- 标准路径为 `~/.claude/skills/`（用户级 skill 的约定位置）

**不要**包含此目录之外的任何 skill。

## 扫描方法

1. 使用 Glob 工具在 skills 根目录下搜索 `*/skill.md` 和 `*/SKILL.md`（两种命名都存在，分别匹配小写和大写）
2. 读取每个文件的 frontmatter（name、description）
3. 根据 description 内容判断 skill 类型：
   - 🔧 执行型：description 包含 "write"、"execute"、"generate"、"run"、"执行"、"打印"、"列出"、"展示"、"operation"、"操作"、"创建"、"生成"
   - 🧠 知识型：description 包含 "knowledge"、"expert"、"guide"、"patterns"、"techniques"、"规范"、"标准"、"编程"、"coding"、"design"、"设计"
   - 📊 分析型：description 包含 "analysis"、"interpret"、"analyze"、"分析"、"解读"、"检查"、"审查"、"review"、"audit"
   - ⚙️ 流程型：description 包含 "workflow"、"evolution"、"记录"、"迭代"、"流程"、"管理"、"开发全流程"
4. 按类型分组展示。格式如下（示例）：

```
═══════════════════════════════════════════════════════
  Skill 列表（共 X 个）
═══════════════════════════════════════════════════════

🔧 执行型（编写/执行/操作）
─────────────────────────────────────────────
  /skill-name            简要功能说明

🧠 知识型（编码规范/最佳实践）
─────────────────────────────────────────────
  ...

📊 分析型（审查/解读/诊断）
─────────────────────────────────────────────
  ...

⚙️ 流程型（编排/记录/管理）
─────────────────────────────────────────────
  ...
```

5. 最后附加提示："输入 /<skill名> 触发对应 skill，或用自然语言描述需求自动匹配"

## 重要约束

- **绝不**列出 skills 根目录之外的 skill
- **绝不**凭空编造 skill 名称或描述
- 如果某个 skill 的 frontmatter 读取失败，跳过它并在末尾注明
