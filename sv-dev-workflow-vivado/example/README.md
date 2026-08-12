# 示例工程 — axi_wr_simple (Vivado 自动化流程演示)

> 本目录演示 `/sv-dev-workflow-vivado` 技能 Phase C 的完整自动化流程：
> **建工程 → 编译仿真 → VCD 检查 → 综合验证 → 清理**，全程 make 一键完成。

## 模块功能

`rtl/axi_wr_simple.sv` — AXI4 写主机**简化版**（示例用）：
用户发一次写请求（`wr_start` 脉冲 + 地址/数据），模块自动完成一次 AXI 单拍写事务
（AW → W → B 通道 valid/ready 握手），输出 `done`/`error`。

## 快速开始（在 example/ 目录执行）

```bash
make all       # 全流程: 建工程 → 仿真(+检查) → 综合 → 最终检查
make sim       # 仿真: xvlog/xelab/xsim → 结果摘要
make check     # 仅检查 VCD 波形 (不启动 Vivado)
make synth     # 综合: 利用率/时序报告 + 网表 checkpoint
make clean     # 删除全部产物 (log/ vivado_prj/ sim_run/ synth_run/)
```

预期输出（`make sim` 末尾）：

```
============ SIMULATION RESULT ============
   结果    : ALL PASS
=====================================
INFO: VCD saved -> .../sim_run/tb_axi_wr_simple.vcd
```

`make check` 输出 4 项检查全部 `[PASS]`，波形可用 GTKWave / VSCode WaveTrace 查看
（`sim_run/tb_axi_wr_simple.vcd`）。

## 目录结构

```
example/
├── Makefile            # 自动化入口 (project/sim/check/synth/all/clean)
├── scripts/            # 5 个 tcl 子脚本 (每步独立)
│   ├── project.tcl     #   建工程 (幂等) + 配置中心 (工程名/器件)
│   ├── add_sources.tcl #   加源文件 (幂等)
│   ├── sim.tcl         #   仿真主脚本
│   ├── check_vcd.tcl   #   VCD 波形检查
│   └── synth.tcl       #   综合主脚本
├── rtl/
│   └── axi_wr_simple.sv   # 被测模块
└── sim/
    ├── tb_axi_wr_simple.sv  # 测试平台 (自检 ALL PASS)
    └── check_vcd.py         # VCD 波形检查脚本
```

## 使用到其他工程时的修改点（脚本内标 [MODIFY]）

| 文件 | 修改内容 |
|------|---------|
| `Makefile` | Vivado / Python / make 路径（**示例路径仅示意，按你的环境查找修改**）|
| `scripts/project.tcl` | 工程名、器件型号 |
| `scripts/add_sources.tcl` | RTL 文件列表、设计顶层 |
| `scripts/sim.tcl` | TB 文件、TB 顶层名 |
| `scripts/synth.tcl` | 设计顶层 |
| `sim/check_vcd.py` | 检查项（按你的 TB 场景编写）|

> ⚠️ 工具路径不要照抄示例：实际环境用 `which vivado` / 常见安装目录查找，
> 找不到询问用户。

## 环境要求

本 example 中的工具路径为**实测可用配置**（2026-08-12 FIFO_EX 项目完整走通验证），直接复制使用：

| 工具 | 实测路径 | 启动方式 |
|------|---------|---------|
| Vivado 2019.2 | `D:/App_install_Lcoation/Vivado201902/Vivado/2019.2/bin/vivado.bat` | `vivado.bat -mode batch -notrace -source <脚本>` |
| Python 3.12 | `D:/App_install_Lcoation/python/python.exe` | `python.exe -X utf8 sim/check_vcd.py <vcd>`（`-X utf8` 强制 UTF-8 输出防乱码） |
| GNU make | `D:\App_install_Lcoation\make\bin\make.exe`（已加入 PATH） | `make sim/check/synth` |

器件型号：`xc7z020clg400-2`（Zynq-7020）。

> 若你的环境不同（Vivado 版本或安装位置变化），才需要修改 `Makefile` 与 `scripts/project.tcl` 中的路径；查找不到时询问用户，不要猜测路径。
