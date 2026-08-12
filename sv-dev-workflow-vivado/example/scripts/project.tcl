#===============================================================================
# project.tcl — Vivado 工程创建脚本 (幂等)
#
# 两种用法:
#   1. 单独运行 (make project):
#         vivado.bat -mode batch -source scripts/project.tcl
#         工程已存在 -> 打开复用; 不存在 -> 创建
#   2. 被其他脚本 source (sim.tcl / synth.tcl):
#         提供 ensure_project proc 和全局配置变量, 供调用方复用
#
# 配置说明: 工程名 / 目录 / 器件型号在本文件顶部, 改这里全局生效
#===============================================================================

# 统一 stdout 为 UTF-8 (Windows 默认 ANSI/GBK, 会导致日志乱码)
fconfigure stdout -encoding utf-8

#------------------------------------------------------------------------------
# 全局配置 (所有脚本共享)
#------------------------------------------------------------------------------
set ::prj_name "axi_wr_example"     ;# [MODIFY] 工程名
set ::prj_dir  "vivado_prj"
set ::prj_part "xc7z020clg400-2"  ;# [MODIFY] 器件型号
# 工具路径 (免安装版, 供 check_vcd.tcl 等调用)
set ::python_exe "D:/App_install_Lcoation/python/python.exe"

#------------------------------------------------------------------------------
# ensure_project — 幂等打开/创建工程
#   已打开工程 -> 什么都不做
#   工程文件存在 -> open_project 复用
#   不存在 -> create_project 新建
#------------------------------------------------------------------------------
proc ensure_project {} {
    set xpr [file normalize "./$::prj_dir/$::prj_name.xpr"]

    # 当前已有打开的工程则直接返回
    if {![catch {current_project} cproj] && $cproj ne ""} {
        return
    }
    if {[file exists $xpr]} {
        puts "INFO: Open existing project $xpr"
        open_project $xpr
    } else {
        puts "INFO: Create project $::prj_name (part=$::prj_part)"
        create_project $::prj_name $::prj_dir -part $::prj_part -force
    }
}

#------------------------------------------------------------------------------
# 单独运行本项目时执行 (被 source 时跳过)
# 判断依据: $argv0 = 主脚本, info script 在 source 时变为被 source 文件
# 两者相等 ⇔ 本项目作为主脚本直接运行
#------------------------------------------------------------------------------
if {[string equal [file tail [info script]] [file tail $argv0]]} {
    ensure_project
    close_project
    exit
}
