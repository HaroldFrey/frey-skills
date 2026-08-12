#===============================================================================
# Makefile — Vivado 自动化入口 (make + tcl)
#
# 用法 (在项目根目录执行):
#   make project   # 创建 Vivado 工程 (已存在则复用, 不重建)
#   make sim       # 仿真: 自动建/开工程 + 加源文件 + xsim 仿真 + VCD 波形检查
#   make check     # 仅检查已有 VCD 波形 (不启动 Vivado, 快)
#   make synth     # 综合: 自动建/开工程 + 加源文件 + synth_design
#   make all       # 全流程: project → sim → synth → check (不执行 clean)
#   make clean     # 删除日志目录与所有输出产物 (工程/仿真/综合/波形)
#
# 前提 (工具路径为示例, 请按你的环境修改 [MODIFY]):
#   - make 可用 (D:\App_install_Lcoation\make\bin\make.exe)
#   - Vivado (D:\App_install_Lcoation\Vivado201902\Vivado\2019.2)
#   - make 可用 (已加入 PATH: D:\App_install_Lcoation\make\bin\make.exe)
#   - Vivado 2019.2 (D:\App_install_Lcoation\Vivado201902)
#
# 脚本分层:
#   project.tcl      工程创建 (幂等) — 工程名/器件型号配置中心
#   add_sources.tcl  源文件管理 (幂等, 公共子脚本)
#   sim.tcl          仿真 (source 上两者)
#   synth.tcl        综合 (source 上两者)
# 日志:
#   log/       — Vivado 会话日志 (vivado_*.log / *.jou)
#   make_run/  — 每次 make 命令的打印信息 (tee 同时输出终端与文件)
#   sim_run/   — 仿真日志与波形 (xvlog/xelab/xsim)
#   synth_run/ — 综合报告与网表
#===============================================================================

VIVADO := D:/App_install_Lcoation/Vivado201902/Vivado/2019.2/bin/vivado.bat
PYTHON := D:/App_install_Lcoation/python/python.exe
LOG_DIR := log
RUN_DIR := make_run

.PHONY: project sim check synth all clean

all: project sim synth check

# 仅检查已有 VCD 波形 (等价于 make sim 内置的检查步骤, 不启动 Vivado)
# -X utf8: 强制 python UTF-8 输出 (Windows 默认按 GBK, 终端/日志会乱码)
check:
	mkdir -p $(RUN_DIR)
	$(PYTHON) -X utf8 sim/check_vcd.py sim_run/tb_axi_wr_example.vcd 2>&1 | tee $(RUN_DIR)/check.log; \
		exit $${PIPESTATUS[0]}

project:
	mkdir -p $(LOG_DIR) $(RUN_DIR)
	$(VIVADO) -mode batch -notrace \
		-log $(LOG_DIR)/vivado_project.log -journal $(LOG_DIR)/vivado_project.jou \
		-source scripts/project.tcl 2>&1 | tee $(RUN_DIR)/project.log; \
		exit $${PIPESTATUS[0]}

sim:
	mkdir -p $(LOG_DIR) $(RUN_DIR)
	$(VIVADO) -mode batch -notrace \
		-log $(LOG_DIR)/vivado_sim.log -journal $(LOG_DIR)/vivado_sim.jou \
		-source scripts/sim.tcl 2>&1 | tee $(RUN_DIR)/sim.log; \
		exit $${PIPESTATUS[0]}

synth:
	mkdir -p $(LOG_DIR) $(RUN_DIR)
	$(VIVADO) -mode batch -notrace \
		-log $(LOG_DIR)/vivado_synth.log -journal $(LOG_DIR)/vivado_synth.jou \
		-source scripts/synth.tcl 2>&1 | tee $(RUN_DIR)/synth.log; \
		exit $${PIPESTATUS[0]}

clean:
	rm -rf $(LOG_DIR) $(RUN_DIR) vivado_prj sim_run synth_run xsim.dir .Xil \
		vivado*.log vivado*.jou vivado_*.backup.jou vivado_*.backup.log \
		webtalk* xsim.jou xsim_*.backup.jou xelab.jou xvlog.jou \
		*.xsim *.wdb *.pb *.vcd tb_sim sim/check_vcd.log
