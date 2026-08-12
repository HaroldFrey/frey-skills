//===========================================================================
// axi_wr_master.v  —  AXI4-Full 写通道控制器
//===========================================================================
// 功能: 独立管理 AXI 写事务 (AW + W + B 通道)
//   - 2 状态 FSM: IDLE ↔ WRITE
//   - INCR 突发写, 支持任意长度 (1~256)
//   - 单拍突发 WLAST 正确置位
//   - FIFO 空时自动反压 (WVALID 拉低)
//   - 地址和长度在 wr_start 时锁存
//===========================================================================

`timescale 1ns / 1ns

module axi_wr_master #(
    parameter       C_M_TARGET_SLAVE_BASE_ADDR      =   32'h00000000    ,// 目标从机基地址
    parameter       C_M_AXI_ID_WIDTH                =   1               ,// ID 信号位宽
    parameter       C_M_AXI_ADDR_WIDTH              =   32              ,// 地址位宽
    parameter       C_M_AXI_DATA_WIDTH              =   8               ,// 数据位宽
    parameter       C_M_AXI_WR_LEN_WIDTH            =   8               ,// 写突发长度位宽
    parameter       C_M_AXI_AWUSER_WIDTH            =   0               ,// 写地址 USER 位宽
    parameter       C_M_AXI_WUSER_WIDTH             =   0               ,// 写数据 USER 位宽
    parameter       C_M_AXI_BUSER_WIDTH             =   0               // 写响应 USER 位宽
)(
    // --------------------------Global Signals---------------------------//
    input   wire                                        M_AXI_ACLK      ,// AXI 时钟
    input   wire                                        M_AXI_ARESETN   ,// AXI 复位 (低有效)

    // --------------------------USER PORTS (写侧)-----------------------//
    input   wire                                        wr_start        ,// 写操作开始 (单周期脉冲)
    input   wire    [1 : 0]                             wr_burst_type   ,// 突发类型: 00=FIXED 01=INCR 10=WRAP
    output  wire                                        data_rd_en      ,// FIFO 读使能
    input   wire                                        wr_fifo_empty   ,// 写 FIFO 空标志
    input   wire    [C_M_AXI_ADDR_WIDTH-1 : 0]          wr_addr_in      ,// 突发写地址
    input   wire    [C_M_AXI_WR_LEN_WIDTH-1 : 0]        wr_len_in       ,// 突发写长度
    input   wire    [C_M_AXI_DATA_WIDTH-1 : 0]          wr_data_in      ,// 写数据 (来自 FIFO)
    input   wire    [C_M_AXI_AWUSER_WIDTH-1 : 0]        user_awuser     ,// 写地址 USER 信号
    input   wire    [C_M_AXI_WUSER_WIDTH-1 : 0]         user_wuser      ,// 写数据 USER 信号
    output  reg                                         wr_error        ,// 写事务错误 (BRESP != OKAY)

    // -------------------------AXI WRITE CHANNELS-----------------------//
    // AW Channel
    output          [C_M_AXI_ID_WIDTH-1 : 0]            M_AXI_AWID      ,
    output  reg     [C_M_AXI_ADDR_WIDTH-1 : 0]          M_AXI_AWADDR    ,
    output          [C_M_AXI_WR_LEN_WIDTH-1 : 0]        M_AXI_AWLEN     ,
    output          [2 : 0]                             M_AXI_AWSIZE    ,
    output          [1 : 0]                             M_AXI_AWBURST   ,
    output                                              M_AXI_AWLOCK    ,
    output          [3 : 0]                             M_AXI_AWCACHE   ,
    output          [2 : 0]                             M_AXI_AWPROT    ,
    output          [3 : 0]                             M_AXI_AWQOS     ,
    output          [C_M_AXI_AWUSER_WIDTH-1 : 0]        M_AXI_AWUSER    ,
    output  reg                                         M_AXI_AWVALID   ,
    input                                               M_AXI_AWREADY   ,

    // W Channel
    output  wire    [C_M_AXI_DATA_WIDTH-1 : 0]          M_AXI_WDATA     ,
    output          [C_M_AXI_DATA_WIDTH/8-1 : 0]        M_AXI_WSTRB     ,
    output                                              M_AXI_WLAST     ,
    output          [C_M_AXI_WUSER_WIDTH-1 : 0]         M_AXI_WUSER     ,
    output                                              M_AXI_WVALID    ,
    input                                               M_AXI_WREADY    ,

    // B Channel
    input           [C_M_AXI_ID_WIDTH-1 : 0]            M_AXI_BID       ,
    input           [1 : 0]                             M_AXI_BRESP     ,
    input           [C_M_AXI_BUSER_WIDTH-1 : 0]         M_AXI_BUSER     ,
    input                                               M_AXI_BVALID    ,
    output  reg                                         M_AXI_BREADY
);

    //===================================================================
    // 参数与函数
    //===================================================================
    localparam          IDLE        = 1'b0;
    localparam          WRITE       = 1'b1;
    localparam          SIZE        = clogb2(C_M_AXI_DATA_WIDTH/8-1);
    localparam          WSTRB_WIDTH = C_M_AXI_DATA_WIDTH/8;   // 便于 iverilog 编译

    function integer clogb2(input integer depth); begin
        if (depth == 0)
            clogb2 = 0;
        else if (depth != 0)
            for (clogb2 = 0; depth > 0; clogb2 = clogb2 + 1)
                depth = depth >> 1;
    end
    endfunction

    //===================================================================
    // 内部寄存器
    //===================================================================
    reg                                     state;
    reg     [31:0]                          wr_cnt;
    reg     [C_M_AXI_WR_LEN_WIDTH-1 : 0]    wr_len_latched;
    reg     [1 : 0]                         wr_burst_latched;

    //===================================================================
    // FSM
    //===================================================================
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 1'b0) begin
            state           <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (wr_start == 1'b1)
                        state <= WRITE;
                    else
                        state <= IDLE;
                end
                WRITE: begin
                    if (M_AXI_BVALID & M_AXI_BREADY)
                        state <= IDLE;
                    else
                        state <= WRITE;
                end
                default: state <= IDLE;
            endcase
        end
    end

    //===================================================================
    // 长度 / 突发类型锁存
    //===================================================================
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 1'b0) begin
            wr_len_latched   <= 0;   // 复位合并到本块, 避免跨 always 多驱动 (综合报 multi-driven)
            wr_burst_latched <= 2'b01;  // 默认 INCR
        end else if (wr_start) begin
            wr_len_latched   <= wr_len_in;
            wr_burst_latched <= (wr_burst_type === 2'bxx) ? 2'b01 : wr_burst_type;
        end
    end

    //===================================================================
    // AXI 固定配置信号
    //===================================================================
    assign M_AXI_AWID    = 0;
    assign M_AXI_AWLEN   = wr_len_latched - 1;
    assign M_AXI_AWSIZE  = SIZE;
    assign M_AXI_AWBURST = wr_burst_latched;  // FIXED/INCR/WRAP
    assign M_AXI_AWLOCK  = 1'b0;
    assign M_AXI_AWCACHE = 4'b0010;
    assign M_AXI_AWPROT  = 3'd0;
    assign M_AXI_AWQOS   = 4'd0;
    assign M_AXI_AWUSER  = user_awuser;
    assign M_AXI_WUSER   = user_wuser;
    assign M_AXI_WSTRB   = {{WSTRB_WIDTH}{1'b1}};

    //===================================================================
    // AWADDR — wr_start 时锁存, 写完成后偏移
    //===================================================================
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 1'b0) begin
            M_AXI_AWADDR <= C_M_TARGET_SLAVE_BASE_ADDR;
        end else if (wr_start) begin
            M_AXI_AWADDR <= C_M_TARGET_SLAVE_BASE_ADDR + wr_addr_in;
        end else if (M_AXI_BREADY & M_AXI_BVALID) begin
            M_AXI_AWADDR <= M_AXI_AWADDR + (wr_len_latched * C_M_AXI_DATA_WIDTH/8);
        end
    end

    //===================================================================
    // AWVALID — wr_start 脉冲触发
    //===================================================================
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 1'b0) begin
            M_AXI_AWVALID <= 1'b0;
        end else if (M_AXI_AWREADY & M_AXI_AWVALID) begin
            M_AXI_AWVALID <= 1'b0;
        end else if (wr_start == 1'b1) begin
            M_AXI_AWVALID <= 1'b1;
        end
    end

    //===================================================================
    // 写数据计数器
    //===================================================================
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 1'b0) begin
            wr_cnt <= 32'd0;
        end else if (state != WRITE) begin
            wr_cnt <= 32'd0;
        end else if (M_AXI_WVALID & M_AXI_WREADY) begin
            wr_cnt <= wr_cnt + 1;
        end
    end

    //===================================================================
    // FIFO 读使能 & WDATA
    //===================================================================
    assign data_rd_en  = (M_AXI_WVALID & M_AXI_WREADY) & (wr_fifo_empty == 1'b0);
    assign M_AXI_WDATA = data_rd_en ? wr_data_in : {C_M_AXI_DATA_WIDTH{1'b0}};

    //===================================================================
    // WVALID — 组合逻辑: 仅当 FIFO 非空且突发未完成时有效
    // (修复: 原寄存器版本在 FIFO 变空后滞后一拍才拉低, 该拍 WVALID 仍为 1
    //  但 data_rd_en=0 → WDATA=0, 从机会握手到一个无数据的假拍, 造成
    //  数据错位并在数据流中插入 0)
    //===================================================================
    assign M_AXI_WVALID = (state == WRITE) && (wr_fifo_empty == 1'b0) && (wr_cnt != wr_len_latched);

    //===================================================================
    // WLAST — 组合逻辑: 最后一拍 (wr_cnt == len-1) 时为 1
    // (重构: 原寄存器预测方案依赖提前一拍置位, 与 WVALID 的时序耦合,
    //  在单拍突发或反压场景下易产生 WLAST 提前/残留/丢失等问题;
    //  组合逻辑天然在最后一拍有效, 与反压/单拍/多拍均兼容)
    //===================================================================
    assign M_AXI_WLAST = (state == WRITE) && (wr_cnt == wr_len_latched - 1);

    //===================================================================
    // BREADY — 写完成后等待响应
    //===================================================================
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 1'b0) begin
            M_AXI_BREADY <= 1'b0;
        end else if (M_AXI_BVALID & M_AXI_BREADY) begin
            M_AXI_BREADY <= 1'b0;
        end else if (M_AXI_WLAST & M_AXI_WVALID & M_AXI_WREADY) begin
            M_AXI_BREADY <= 1'b1;
        end
    end

    //===================================================================
    // 写错误检测 (BRESP != OKAY)
    //===================================================================
    always @(posedge M_AXI_ACLK) begin
        if (M_AXI_ARESETN == 1'b0) begin
            wr_error <= 1'b0;
        end else if (wr_start) begin
            wr_error <= 1'b0;                        // 新事务开始, 清除旧错误
        end else if (M_AXI_BVALID & M_AXI_BREADY && M_AXI_BRESP != 2'b00) begin
            wr_error <= 1'b1;                        // 非 OKAY 响应, 置位错误
        end
    end

endmodule
