#===============================================================================
# synth.tcl — Vivado 综合脚本 (batch 模式)
#
# 用法 (由 Makefile 调用): make synth
# 流程: 打开/创建工程 → 加 RTL 源文件 → synth_design 综合 → 报告 + checkpoint
# 复用: scripts/project.tcl (建工程) + scripts/add_sources.tcl (加文件)
# 产物: synth_run/ (利用率报告 / 时序报告 / 综合后网表 checkpoint)
#===============================================================================

# 统一 stdout 为 UTF-8 (Windows 默认 ANSI/GBK, 会导致日志乱码)
fconfigure stdout -encoding utf-8

# 复用子脚本 (用 info script 定位, 与调用目录无关)
# -encoding utf-8: Vivado 默认按系统编码(GBK)读 tcl 源码, 必须显式指定
set script_dir [file dirname [file normalize [info script]]]
source -encoding utf-8 [file join $script_dir project.tcl]
source -encoding utf-8 [file join $script_dir add_sources.tcl]

#------------------------------------------------------------------------------
# 1) 工程准备 (幂等: 已存在则复用) + 添加 RTL 源文件 (综合不需要 TB)
#------------------------------------------------------------------------------
ensure_project
add_design_sources

#------------------------------------------------------------------------------
# 2) 综合
#------------------------------------------------------------------------------
set run_dir [file normalize ./synth_run]
if {[file exists $run_dir]} { file delete -force $run_dir }
file mkdir $run_dir

puts "INFO: synth_design (top=axi_wr_master)"    ;# [MODIFY] 设计顶层
synth_design -top axi_wr_master -part $::prj_part

#------------------------------------------------------------------------------
# 3) 报告与网表导出
#------------------------------------------------------------------------------
puts "INFO: generate reports"
report_utilization  -file [file join $run_dir utilization.rpt]
report_timing       -max_paths 10 -file [file join $run_dir timing.rpt]
report_timing_summary -file [file join $run_dir timing_summary.rpt]

puts "INFO: save post-synth checkpoint"
write_checkpoint -force [file join $run_dir post_synth.dcp]

puts "INFO: synthesis done, outputs -> $run_dir"
close_project
exit
