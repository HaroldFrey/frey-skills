#===============================================================================
# add_sources.tcl — 工程源文件管理 (公共子脚本, 幂等)
#
# 用途: 被 sim.tcl / synth.tcl source, 提供添加源文件的 proc
# 幂等性: 已添加过的文件会自动跳过, 可重复调用
#
# 提供的 proc:
#   add_design_sources      RTL 源文件 + 设置设计顶层 (sources_1)
#   add_testbench_sources   TB 源文件 + 设置仿真顶层 (sim_1)
#   add_all_sources         以上两者
#===============================================================================

#------------------------------------------------------------------------------
# add_file_if_missing — 向指定 fileset 添加文件 (已存在则跳过)
#------------------------------------------------------------------------------
proc add_file_if_missing {fset path} {
    set norm [file normalize $path]
    if {[llength [get_files -quiet $norm]] == 0} {
        puts "INFO: add $path -> $fset"
        add_files -norecurse -fileset $fset $path
    } else {
        puts "INFO: skip $path (already in project)"
    }
}

#------------------------------------------------------------------------------
# add_design_sources — RTL 源文件 + 设计顶层
#------------------------------------------------------------------------------
proc add_design_sources {} {
    # [MODIFY] RTL 文件列表 (按模块修改)
    foreach f {
        rtl/axi_wr_master.v
        rtl/Data_RX.v
        rtl/fifo_async.v
    } {
        add_file_if_missing sources_1 $f
        # .v 后缀文件实际使用 SystemVerilog 语法 (parameter int 等),
        # 显式设置文件类型, 否则综合按 Verilog-2001 解析会报 unknown type
        # 注意: set_property 对象必须是 get_files 返回的对象 (不能传裸路径)
        set fobj [get_files -quiet [file normalize $f]]
        if {[llength $fobj] > 0} {
            set_property file_type SystemVerilog $fobj
        }
    }
    set_property top axi_wr_master [get_filesets sources_1]    ;# [MODIFY] 设计顶层
    update_compile_order -fileset sources_1
}

#------------------------------------------------------------------------------
# add_testbench_sources — TB 源文件 + 仿真顶层
#------------------------------------------------------------------------------
proc add_testbench_sources {} {
    add_file_if_missing sim_1 sim/tb_axi_wr_example.sv    ;# [MODIFY] TB 文件
    set_property top tb_axi_wr_example [get_filesets sim_1]    ;# [MODIFY] TB 顶层
    update_compile_order -fileset sim_1
}

#------------------------------------------------------------------------------
# add_all_sources — 设计 + TB 全部
#------------------------------------------------------------------------------
proc add_all_sources {} {
    add_design_sources
    add_testbench_sources
}
