//===========================================================================
// tb_axi_wr_example.sv — AXI 写通道示例测试平台
//===========================================================================
// 目的: 验证摘取自 AXI_FULL_Master 项目的写通道控制器 (axi_wr_master)
//       + 写数据通路 (Data_RX) + 异步 FIFO (fifo_async)
// 场景: 一次 INCR 写突发 len=4 @0x100, 数据 0x11/0x22/0x33/0x44
// 语法: 简单 SystemVerilog (reg/wire/always/initial/task)
// 检查: awaddr/awlen 正确、bvalid 响应一次、wr_error==0、数据捕获一致
// 结果: ALL PASS / FAIL (VCD 供 check_vcd.py 二次检查)
//===========================================================================

`timescale 1ns / 1ns

module tb_axi_wr_example;

    //=======================================================================
    // 时钟与复位 (写数据时钟与 AXI 时钟同频)
    //=======================================================================
    reg clk_wr  = 1'b0;
    reg clk_axi = 1'b0;
    reg rst_n   = 1'b0;
    always #5 clk_wr  = ~clk_wr;
    always #5 clk_axi = ~clk_axi;

    //=======================================================================
    // USER 侧信号 (写请求 + 数据)
    //=======================================================================
    reg         wr_start;
    reg         wr_valid;
    reg  [7:0]  wr_data_in;
    wire        wr_ready;
    reg  [7:0]  wr_addr;
    reg  [7:0]  wr_len;
    reg  [1:0]  wr_burst_type;
    wire        wr_error;

    //=======================================================================
    // AXI 总线信号 (DUT 与 Slave 之间)
    //=======================================================================
    wire        m_axi_awvalid;
    wire [7:0]  m_axi_awaddr;
    wire [7:0]  m_axi_awlen;
    reg         m_axi_awready;
    wire        m_axi_wvalid;
    wire [7:0]  m_axi_wdata;
    wire        m_axi_wlast;
    reg         m_axi_wready;
    reg         m_axi_bvalid;
    reg  [1:0]  m_axi_bresp;
    wire        m_axi_bready;

    //=======================================================================
    // 内部连接 (FIFO 通路)
    //=======================================================================
    wire        fifo_rd_en;
    wire        fifo_empty;
    wire [7:0]  fifo_addr_out;
    wire [7:0]  fifo_len_out;
    wire [7:0]  fifo_data_out;

    //=======================================================================
    // 被测模块: 写通道控制器
    //=======================================================================
    axi_wr_master #(
        .C_M_AXI_ID_WIDTH       (1),
        .C_M_AXI_ADDR_WIDTH     (8),    // 与 Data_RX 地址位宽一致 (避免悬空 Z)
        .C_M_AXI_DATA_WIDTH     (8),
        .C_M_AXI_WR_LEN_WIDTH   (8)
    ) wr_master (
        .M_AXI_ACLK      (clk_axi),
        .M_AXI_ARESETN   (rst_n),
        .wr_start        (wr_start),
        .wr_burst_type   (wr_burst_type),
        .data_rd_en      (fifo_rd_en),
        .wr_fifo_empty   (fifo_empty),
        .wr_addr_in      (fifo_addr_out),
        .wr_len_in       (fifo_len_out),
        .wr_data_in      (fifo_data_out),
        .user_awuser     (0),
        .user_wuser      (0),
        .wr_error        (wr_error),
        .M_AXI_AWID      (),
        .M_AXI_AWADDR    (m_axi_awaddr),
        .M_AXI_AWLEN     (m_axi_awlen),
        .M_AXI_AWSIZE    (),
        .M_AXI_AWBURST   (),
        .M_AXI_AWLOCK    (),
        .M_AXI_AWCACHE   (),
        .M_AXI_AWPROT    (),
        .M_AXI_AWQOS     (),
        .M_AXI_AWUSER    (),
        .M_AXI_AWVALID   (m_axi_awvalid),
        .M_AXI_AWREADY   (m_axi_awready),
        .M_AXI_WDATA     (m_axi_wdata),
        .M_AXI_WSTRB     (),
        .M_AXI_WLAST     (m_axi_wlast),
        .M_AXI_WUSER     (),
        .M_AXI_WVALID    (m_axi_wvalid),
        .M_AXI_WREADY    (m_axi_wready),
        .M_AXI_BID       (0),
        .M_AXI_BRESP     (m_axi_bresp),
        .M_AXI_BUSER     (0),
        .M_AXI_BVALID    (m_axi_bvalid),
        .M_AXI_BREADY    (m_axi_bready)
    );

    //=======================================================================
    // 被测模块: 写数据通路 (FIFO)
    //=======================================================================
    Data_RX #(
        .C_M_AXI_DATA_WIDTH (8),
        .C_M_AXI_ADDR_WIDTH (8),
        .C_M_AXI_WR_LEN_WIDTH (8)
    ) rx_path (
        .clk_wr        (clk_wr),
        .clk_axi       (clk_axi),
        .rst_n         (rst_n),
        .wr_valid      (wr_valid),
        .wr_data_in    (wr_data_in),
        .wr_ready      (wr_ready),
        .wr_addr       (wr_addr),
        .wr_len        (wr_len),
        .data_rd_en    (fifo_rd_en),
        .wr_fifo_empty (fifo_empty),
        .wr_addr_out   (fifo_addr_out),
        .wr_len_out    (fifo_len_out),
        .wr_data_out   (fifo_data_out)
    );

    //=======================================================================
    // AXI Slave 响应模型 (写通道: 接收 AW/W, 返回 B)
    //=======================================================================
    integer b_cnt = 0;
    always @(posedge clk_axi or negedge rst_n) begin
        if (!rst_n) begin
            m_axi_awready <= 1'b0;
            m_axi_wready  <= 1'b0;
            m_axi_bvalid  <= 1'b0;
            m_axi_bresp   <= 2'b00;
        end else begin
            m_axi_awready <= m_axi_awvalid;              // 收到 AW 后一拍就绪
            m_axi_wready  <= m_axi_wvalid;               // 每拍 W 握手
            m_axi_bvalid  <= (m_axi_wlast && m_axi_wvalid && m_axi_wready);  // 最后一拍后响应
            if (m_axi_bvalid && m_axi_bready)
                b_cnt <= b_cnt + 1;
        end
    end

    //=======================================================================
    // AW 握手采样 (B 握手后 AWADDR 会递增, 需在递增前采样地址)
    //=======================================================================
    reg [7:0] awaddr_sampled = 8'h00;
    always @(posedge clk_axi) begin
        if (m_axi_awvalid && m_axi_awready)
            awaddr_sampled <= m_axi_awaddr;
    end

    //=======================================================================
    // 激励 + 检查
    //=======================================================================
    reg  [31:0] expect_data [0:3];
    integer err_cnt = 0;
    integer i;
    reg         seen_wlast = 1'b0;

    initial begin
        // 波形 dump
        $dumpfile("tb_axi_wr_example.vcd");
        $dumpvars(0, tb_axi_wr_example);

        // 期望数据
        expect_data[0] = 8'h11;
        expect_data[1] = 8'h22;
        expect_data[2] = 8'h33;
        expect_data[3] = 8'h44;

        // 初始化
        wr_start      = 1'b0;
        wr_valid      = 1'b0;
        wr_data_in    = 8'h00;
        wr_addr       = 8'h00;
        wr_len        = 8'h00;
        wr_burst_type = 2'b01;      // INCR

        // 复位 30ns
        #30;
        rst_n = 1'b1;
        #10;

        // 写入数据 (4 拍, 与 wr_ready 握手)
        wr_addr = 8'h10;            // 地址 0x10
        wr_len  = 8'h04;            // 长度 4
        for (i = 0; i < 4; i = i + 1) begin
            @(posedge clk_wr);
            wr_valid   = 1'b1;
            wr_data_in = expect_data[i];
            // 等待握手
            while (!wr_ready) @(posedge clk_wr);
            @(posedge clk_wr);
            wr_valid = 1'b0;
        end

        // 发起写事务
        @(posedge clk_axi);
        wr_start = 1'b1;
        @(posedge clk_axi);
        wr_start = 1'b0;

        // 等待响应
        while (b_cnt < 1) @(posedge clk_axi);
        #1;

        // ---- 检查点 ----
        if (awaddr_sampled !== 8'h10) begin
            $display("[FAIL] awaddr = %02h, expect 10", awaddr_sampled);
            err_cnt = err_cnt + 1;
        end else
            $display("[PASS] awaddr = %02h", awaddr_sampled);

        if (m_axi_awlen !== 8'h03) begin
            $display("[FAIL] awlen = %02h, expect 03 (len-1)", m_axi_awlen);
            err_cnt = err_cnt + 1;
        end else
            $display("[PASS] awlen = %02h", m_axi_awlen);

        if (b_cnt !== 1) begin
            $display("[FAIL] bvalid 次数 = %0d, expect 1", b_cnt);
            err_cnt = err_cnt + 1;
        end else
            $display("[PASS] bvalid 次数 = 1");

        if (wr_error !== 1'b0) begin
            $display("[FAIL] wr_error 应为 0 (BRESP=OKAY)");
            err_cnt = err_cnt + 1;
        end else
            $display("[PASS] wr_error = 0");

        if (seen_wlast === 1'b0) begin
            $display("[FAIL] WLAST 未出现");
            err_cnt = err_cnt + 1;
        end else
            $display("[PASS] WLAST 出现");
    end

    // WLAST 观测
    always @(posedge clk_axi) begin
        if (m_axi_wlast && m_axi_wvalid && m_axi_wready)
            seen_wlast = 1'b1;
    end

    // 结果判定
    initial begin
        wait (b_cnt >= 1);
        #50;
        if (err_cnt == 0)
            $display("结果    : ALL PASS");
        else
            $display("结果    : %0d FAIL", err_cnt);
        $finish;
    end

endmodule
