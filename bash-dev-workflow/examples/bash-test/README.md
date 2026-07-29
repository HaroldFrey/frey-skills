# file-stats — 目录文件统计器

## 功能简介
扫描指定目录，按扩展名统计文件数量和大小分布，展示 Top N 大文件。

## 快速开始
```bash
# 基本用法（显示扩展名统计 + Top 5 大文件）
bash script/file-stats.sh ../

# 显示 Top 10
bash script/file-stats.sh ../ -n 10

# 预览模式（不实际扫描）
bash script/file-stats.sh ../ -d

# 查看帮助
bash script/file-stats.sh -h
```

## 依赖
- `find`（系统自带）
- `du`（系统自带）
- `sort`（系统自带）
- `wc`（系统自带）

## 文件架构
```
├── README.md                       ← 本文件
├── script/
│   └── file-stats.sh               ← 主脚本
└── doc/
    ├── DESIGN_file-stats.md        ← 设计方案
    ├── SYNTAX_file-stats.md        ← 语法解析
    ├── REVIEW_file-stats.md        ← 代码审查报告
    ├── PROBLEMS_file-stats.md      ← 问题追踪
    └── FINAL_REPORT_file-stats.md  ← 最终审查报告
```

## 文档说明
| 文档 | 内容 | 适合谁 |
|------|------|--------|
| `DESIGN_file-stats.md` | 功能设计、参数说明 | 初次使用者 |
| `SYNTAX_file-stats.md` | 语法结构、函数变量速查 | 维护者 |
| `REVIEW_file-stats.md` | 安全/规范审查结果 | 审查者 |
| `PROBLEMS_file-stats.md` | 问题追踪记录 | 项目管理者 |
| `FINAL_REPORT_file-stats.md` | 最终审查报告 | 交付验收 |
