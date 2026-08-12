#===============================================================================
# check_vcd.tcl — 仿真波形检查 (独立子脚本, 幂等)
#
# 用途: 被 sim.tcl source, 仿真完成后调用 run_vcd_check 检查 VCD 波形
# 独立用法 (make check): 直接调 python 检查已有 VCD, 见 Makefile
#
# 原理: 调用 sim/check_vcd.py 解析 VCD, 验证:
#   1. TB 判定 (test_done / test_pass)
#   2. 写事务次数 == 4
#   3. 读事务次数 == 4
#   4. 读数据抽查 (0x10 / 0xA5 / 0x20 / 0x30)
# 退出码: 0 = 通过, 非 0 = 失败 (使 make sim 报错, 阻断流程)
#===============================================================================

#------------------------------------------------------------------------------
# run_vcd_check — 运行 VCD 波形检查
#   检查日志: 重定向到 sim/check_vcd.log (不改 py 脚本, 用 tcl 重定向实现)
#   返回: 0 = 全部通过; 抛错 = 失败 (VCD 缺失 / 检查不通过)
#------------------------------------------------------------------------------
proc run_vcd_check {} {
    set vcd [file normalize ./sim_run/tb_axi_wr_example.vcd]    ;# [MODIFY] VCD 名
    if {![file exists $vcd]} {
        error "VCD file not found: $vcd (run make sim first)"
    }
    set log_file [file normalize ./sim/check_vcd.log]
    puts "INFO: check_vcd.py running (log -> sim/check_vcd.log)"
    # 编码处理: Windows 上 python 输出按系统 locale (中文系统=GBK),
    # 用 exec 捕获 (Tcl 自动按系统编码解码为 Unicode), 再转 UTF-8 写日志,
    # 保证 VSCode (默认 UTF-8) 打开日志正常
    if {[catch {exec [file normalize $::python_exe] \
            [file normalize ./sim/check_vcd.py] $vcd} out]} {
        # 检查失败: 写日志后抛错 (阻断 make)
        set fp [open $log_file w]
        fconfigure $fp -encoding utf-8
        puts $fp $out
        close $fp
        error $out
    }
    set fp [open $log_file w]
    fconfigure $fp -encoding utf-8
    puts $fp $out
    close $fp
    puts $out
    puts "INFO: VCD check passed (ALL PASS)"
    return 0
}
