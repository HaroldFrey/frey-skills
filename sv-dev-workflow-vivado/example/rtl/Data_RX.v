
`timescale 1ns / 1ns

module  Data_RX#(
parameter  C_M_AXI_DATA_WIDTH     = 8 ,  //数据位宽
parameter  C_M_AXI_ADDR_WIDTH     = 8 ,  //地址位宽
parameter  C_M_AXI_WR_LEN_WIDTH   = 8    //突发长度位宽
)(
// Global ports
input    wire                               clk_wr,  // 写数据时钟
input    wire                               clk_axi, // axi总线时钟
input    wire                               rst_n,

//valid、ready、data
input    wire                               wr_valid ,
input    wire [C_M_AXI_DATA_WIDTH-1 : 0]    wr_data_in,
output   wire  			                    wr_ready,

// ADDR LEN DATA
input    wire [C_M_AXI_ADDR_WIDTH-1 : 0]    wr_addr,
input    wire [C_M_AXI_WR_LEN_WIDTH-1 : 0] 	wr_len,

// ports intr with AXI_Master
input    wire                               data_rd_en,
output   wire                               wr_fifo_empty,
output   wire [C_M_AXI_ADDR_WIDTH-1 : 0]    wr_addr_out,
output   wire [C_M_AXI_WR_LEN_WIDTH-1 : 0] 	wr_len_out,
output   wire [C_M_AXI_DATA_WIDTH-1 : 0]    wr_data_out
);


//----------------- 数据缓存 ---------------------- //
wire                                fifo_rd_en;
wire                                fifo_empty;
wire                                fifo_full;

assign wr_fifo_empty = fifo_empty;
assign fifo_rd_en = (data_rd_en) ? 1'b1 : 1'b0 ;

// FWFT 异步 FIFO (等效 Vivado FIFO Generator IP)
fifo_async #(
    .MODE       (0),           // 0=FWFT
    .DATA_WIDTH (C_M_AXI_DATA_WIDTH),
    .DEPTH      (32),
    .ADDR_WIDTH (5)
) rx_data_fifo_inst (
    .wr_clk       (clk_wr),
    .rd_clk       (clk_axi),
    .din          (wr_data_in),
    .wr_en        (wr_valid),
    .rd_en        (fifo_rd_en),
    .dout         (wr_data_out),
    .full         (fifo_full),
    .almost_full  (),
    .empty        (fifo_empty),
    .almost_empty ()
);

//----------------- 输出信号 ---------------------- //
assign wr_ready    = (fifo_full) ? 1'b0 : 1'b1;

assign wr_addr_out = wr_addr;
assign wr_len_out  = wr_len;


endmodule
