#===============================================================================
# sim.tcl — Vivado 自动化仿真脚本 (batch 模式)
#
# 用法 (由 Makefile 调用): make sim
# 流程: 打开/创建工程 → 加源文件 → xvlog/xelab/xsim 编译仿真 → 结果摘要
# 复用: scripts/project.tcl (建工程) + scripts/add_sources.tcl (加文件)
#
# 说明: 仿真不走 launch_simulation (该命令在部分 Windows 环境
#       存在 "Spawn failed: Broken pipe" 已知问题), 改为在 Tcl 里
#       手动按非工程流程调用 xvlog → xelab → xsim (全部绝对路径)
#===============================================================================

# 统一 stdout 为 UTF-8 (Windows 默认 ANSI/GBK, 会导致日志乱码)
fconfigure stdout -encoding utf-8

# 复用子脚本 (用 info script 定位, 与调用目录无关)
# -encoding utf-8: Vivado 默认按系统编码(GBK)读 tcl 源码, 必须显式指定
set script_dir [file dirname [file normalize [info script]]]
source -encoding utf-8 [file join $script_dir project.tcl]
source -encoding utf-8 [file join $script_dir add_sources.tcl]

#------------------------------------------------------------------------------
# 1) 工程准备 (幂等: 已存在则复用, 不重建)
#------------------------------------------------------------------------------
ensure_project
add_all_sources

#------------------------------------------------------------------------------
# 2) 手动编译仿真 (xvlog → xelab → xsim, 绝对路径, 绕开 launch_simulation)
#------------------------------------------------------------------------------
set work_dir [file normalize ./sim_run]
if {[file exists $work_dir]} { file delete -force $work_dir }
file mkdir $work_dir

# [MODIFY] RTL 文件列表 (按模块修改)
set rtl_files [list     [file normalize ./rtl/axi_wr_master.v]     [file normalize ./rtl/Data_RX.v]     [file normalize ./rtl/fifo_async.v] ]
set tb_files [list [file normalize ./sim/tb_axi_wr_example.sv]]    ;# [MODIFY] TB 文件
set lib "xil_defaultlib"

# 说明: Tcl 的 cd 对 exec 子进程不生效 (Vivado Windows 环境),
#       用 cmd /c "cd /d <工作目录> && ..." 把 xvlog/xelab/xsim
#       的工作目录切到 sim_run/, 避免中间文件散落项目根
#       注意: 命令字符串用 concat 构建 ({}* 展开在字符串内不生效)
set cd_cmd "cd /d [file nativename $work_dir] &&"

puts "INFO: xvlog compile (RTL + TB)"
# 捕获 exec 输出再 puts: 子进程直接写 stdout 的字节不经过 fconfigure (编码不统一),
# 捕获时 Tcl 按系统编码(GBK)解码, puts 按 UTF-8 输出, 保证日志编码一致
set _o [exec cmd /c [concat $cd_cmd xvlog --incr --relax -sv -work $lib -log xvlog.log \
    {*}$rtl_files {*}$tb_files]]

puts "INFO: xelab link top tb_axi_wr_example"
set _o [exec cmd /c [concat $cd_cmd xelab --incr --relax -debug typical -s tb_sim -log xelab.log \
    $lib.tb_axi_wr_example]]

puts "INFO: xsim run (TB \$finish ends)"
set _o [exec cmd /c [concat $cd_cmd xsim tb_sim -R -log xsim.log]]

#------------------------------------------------------------------------------
# 3) 收尾: 打印结果摘要 + 保存波形
#------------------------------------------------------------------------------
puts "============ SIMULATION RESULT ============"
set log_fp [open [file join $work_dir xsim.log] r]
while {[gets $log_fp line] >= 0} {
    if {[regexp -nocase {PASS|FAIL|ERROR|finish} $line]} { puts "  $line" }
}
close $log_fp
puts "====================================="

set vcd [file join $work_dir tb_axi_wr_example.vcd]
if {[file exists $vcd]} {
    puts "INFO: VCD saved -> $vcd"
} else {
    puts "WARNING: VCD not found (TB \$dumpfile not effective?)"
}

# 说明: VCD 波形检查已独立为步骤 (make check / make all 最后一步),
#       sim.tcl 只负责仿真本身, 见 scripts/check_vcd.tcl
close_project
exit
