# Claude Code Skills

自定义 skill 集合，覆盖 FPGA 开发全流程 + Bash 脚本工程化。

---

## 目录

| 分类 | Skill |
|------|-------|
| 🔧 执行型 | `pwd` `ls` `skills` `commit_push` |
| 📋 预处理 | `req-analysis` |
| 📊 分析型 | `full-review` `project-reader` |
| 🧠 FPGA RTL | `verilog-sv-language` |
| 🧠 FPGA 工具链 | `vivado-tcl` `vivado-synth` `vivado-analysis` |
| 🧠 脚本工程化 | `bash-defensive-patterns` `makefile-patterns` |
| 🔄 编排型 | `bash-dev-workflow` `sv-dev-workflow` `skill-maker` `project-evolution` |

---

## 🔧 执行型

### `/pwd`
打印当前工作目录，同时列出 session 涉及的所有关键目录（配置目录、Skills 目录、工程目录）。

### `/ls`
列出当前目录下所有文件和文件夹（含隐藏文件），按 📁 文件夹 / 📄 文件 分组，显示名称和修改时间。

### `/skills`
列出所有已安装的 skill，按类型分组展示，附带简要功能说明。

---

## 📋 预处理

### `/req-analysis` 🆕
**独立需求分析**——通过不断追问理清所有需求细节，生成需求文档。**任何项目开始前都可以先调用此 skill 明确需求。**

不限轮次追问，直到需求完全理清。文档格式：功能需求(编号+优先级) + 接口规格 + 非功能需求 + 约束条件 + 用户确认 checkbox。

> 也可被 `/bash-dev-workflow` 和 `/sv-dev-workflow` 的阶段 0/A0 内嵌调用，逻辑相同。

---

## 📊 分析型

### `/full-review` 🆕
**项目全面审查**——对代码和文档进行系统化审查，按 🔴严重 / 🟡中等 / 🟢低 分级报告。每个问题附带具体修复代码。支持 `--focus` 聚焦审查和 `--auto` 自动修复。

> **内部调用**：Bash 项目自动调用 `/bash-defensive-patterns`；Verilog 项目自动调用 `/verilog-sv-language` + `/vivado-synth`

| 参数 | 说明 |
|------|------|
| 无参数 | 审查当前项目目录下所有脚本和文档 |
| `--focus <文件>` | 只审查指定文件（可多次指定） |
| `--auto` | 审查后自动修复（需二次确认） |

> ⚠️ 默认只报告不修改。即使使用 `--auto`，执行修改前仍需用户确认。

### `/project-reader` 🆕
**项目深度阅读与分析**——全量扫描项目，生成 `doc_reader/` 下 6 份结构化报告（概述、目录、架构、关键文件、依赖、使用指南）。分析完成后自动调用 `/full-review` 验证产物，迭代直到 0 问题。

> **内部调用**：Bash 项目 → `/bash-defensive-patterns`；FPGA → `/verilog-sv-language` + `/vivado-synth`；质量检查 → `/full-review`

| 输出 | 说明 |
|------|------|
| `00_项目概述.md` | 用途、技术栈、核心能力 |
| `01_目录结构与文件清单.md` | 完整文件树 + 分类统计 |
| `02_架构设计.md` | 分层架构 + 调用关系图 + 数据流 |
| `03_关键文件详解.md` | 每个核心文件的配置、函数、逻辑 |
| `04_依赖与运行环境.md` | 外部工具、版本、平台要求 |
| `05_使用指南.md` | 构建、运行、测试、常见修改 |

> ⚠️ 产物生成后强制经过 `/full-review` 质量检查，用户确认后修改，循环直到无误。

---

## 🧠 FPGA RTL 开发

### `/verilog-sv-language`
**Verilog/SystemVerilog RTL 编码规范**，遵循 IEEE 1800-2017 标准。

> **被调用**：`/sv-dev-workflow` 在编码(A2)和审查(A3)阶段自动调用此 skill。

| 能力 | 说明 |
|------|------|
| always 块规范 | `always_ff`（时序）/ `always_comb`（组合） |
| 参数化模块 | `parameter` + `localparam` + `$clog2()` |
| 接口定义 | AXI-Stream、AXI-Lite 等，含 modport |
| 赋值规范 | 时序 `<=`，组合 `=`，不可混用 |
| 综合属性 | Xilinx / Intel 厂商属性 |

---

## 🧠 FPGA 工具链（Vivado）

### `/vivado-tcl`
**生成并执行 Vivado/Vitis TCL 脚本**，覆盖全流程自动化（Project Mode / Non-Project Mode）。

> 仅负责生成和执行 TCL，不分析输出。分析报告用 `/vivado-analysis`。

### `/vivado-synth`
**Vivado 综合策略与属性决策**。帮助选择 `synth_design` 选项和综合属性。

> **被调用**：`/sv-dev-workflow` 在最终审查(A6)阶段自动调用此 skill。

| 需求 | 策略 |
|------|------|
| 首次尝试 | `default` |
| 面积优化 | `AreaOptimized_high` |
| 时序关键 | `PerformanceOptimized` |
| 布线拥塞 | `AlternateRoutability` |

### `/vivado-analysis`
**Vivado 时序分析与收敛策略**。解读 `report_timing`、QoR 评分、拥塞分析、CDC 检查。

---

## 🧠 脚本工程化

### `/bash-defensive-patterns`
**Bash 防御性编程最佳实践**。14 条规则 + 10 种代码模式，生产级脚本必备。

> **被调用**：`/bash-dev-workflow` 在编码阶段自动调用此 skill。

### `/makefile-patterns`
**Makefile 构建系统模式**。含自文档化 help、dev-loop、品质门禁、release 流程。

---

## 🔄 编排型

### `/bash-dev-workflow`
**Bash 脚本开发全流程管理**。8 阶段编排：需求分析 → 设计 → 编码 → 语法解析 → 审查 → 追踪 → 最终审查 → 全面检查。支持单文件和多文件项目。

支持 `--auto` 自动模式和手动模式。

**内部调用**：`/bash-defensive-patterns`（编码） | `/req-analysis`（需求分析阶段逻辑相同）

| 模式 | 触发 |
|------|------|
| 🔧 手动（默认） | 不指定 |
| 🤖 自动 | `--auto` / "自动" / "全自动" |

> ⚠️ 需求确认阶段无论手动/自动都必须人工确认。📂 示例见 `bash-dev-workflow/examples/bash-test/`

### `/sv-dev-workflow`
**Verilog/SystemVerilog 模块开发全流程管理**。Phase A(RTL)+Phase B(Testbench) 两阶段，支持多模块项目。

支持 `--auto` 自动模式和手动模式。

**内部调用**：`/verilog-sv-language`（编码+审查） | `/vivado-synth`（最终审查） | `/req-analysis`（A0/B0 需求分析逻辑相同）

| 模式 | 触发 |
|------|------|
| 🔧 手动（默认） | 不指定 |
| 🤖 自动 | `--auto` / "自动" / "全自动" |

> ⚠️ A0/B0 需求确认阶段无论手动/自动都必须人工确认。

### `/skill-maker` 🆕
**Skill 制作工作流**。根据用户描述创建自定义 skill，引导试用、反馈、迭代直到满意。

触发词：制作skill、创建skill、新建skill。

| 阶段 | 说明 |
|------|------|
| 1. 理解需求 | 追问 → 输出确认清单 → 🛑 |
| 2. 生成 Skill | 创建 skill.md → 展示内容 → 🛑 |
| 3. 试用 | 提示用户试用 → 🛑 |
| 4. 反馈 | 收集反馈 + AI 主动给改进建议 |
| 5. 迭代 | 修改 → 再试 → 循环 |
| 6. 完成 | 用户满意 |

> 3 个强制等待点：需求确认 + 内容确认 + 试用反馈。

### `/project-evolution` 🆕
**项目迭代演进记录**——记录每次会话/版本的修改、决策和问题，生成结构化 `ITERATION_LOG.md`，含文字+图+表。

触发词：记录迭代、记录修改、项目演进、迭代日志、project evolution、dev journal。

---

## Skill 调用关系

```
/req-analysis                独立预处理（可单独用）
    │
    ↓ 逻辑内嵌于
    │
├── /bash-dev-workflow  ──→ 编码时调用 /bash-defensive-patterns
│
├── /sv-dev-workflow    ──→ 编码时调用 /verilog-sv-language
│                       ──→ 最终审查时调用 /vivado-synth
│
├── /full-review        ──→ Bash 项目调用 /bash-defensive-patterns
│                       ──→ Verilog 项目调用 /verilog-sv-language + /vivado-synth
│
└── /project-reader     ──→ Bash 项目调用 /bash-defensive-patterns
                        ──→ FPGA 项目调用 /verilog-sv-language + /vivado-synth
                        ──→ 质量检查调用 /full-review
```

| 父 Skill | 调用的子 Skill | 调用时机 |
|---------|---------------|---------|
| `bash-dev-workflow` | `bash-defensive-patterns` | 编码阶段 |
| `sv-dev-workflow` | `verilog-sv-language` | 编码(A2) + 审查(A3) |
| `sv-dev-workflow` | `vivado-synth` | 最终审查(A6) |
| `full-review` | `bash-defensive-patterns` | Bash 项目审查 |
| `full-review` | `verilog-sv-language` + `vivado-synth` | Verilog 项目审查 |
| `project-reader` | `bash-defensive-patterns` | Bash 项目分析 |
| `project-reader` | `verilog-sv-language` + `vivado-synth` | FPGA 项目分析 |
| `project-reader` | `full-review` | 分析产物质量检查 |
| 两者 | `req-analysis`（逻辑内嵌） | 阶段 0 / A0 / B0 |

---

## 安装方式

所有 skill 存放在 `C:\Users\28968\.claude\skills\` 下，Claude Code CLI 启动时自动加载。

全局生效：`C:\Users\28968\.claude\skills/`。项目专属：`<项目>/.claude/skills/<名称>/skill.md`。

## 查看所有 skill

```
/skills
```
