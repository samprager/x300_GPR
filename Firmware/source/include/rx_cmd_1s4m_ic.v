// rx_cmd_1s4m_ic.v
`ifndef _rx_cmd_1s4m_ic_v_
`define _rx_cmd_1s4m_ic_v_


wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     ch_wr_cmd_axis_tdata;
wire                            ch_wr_cmd_axis_tvalid;
wire                            ch_wr_cmd_axis_tlast;
wire                            ch_wr_cmd_axis_tready;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     ch_wr_cmd_axis_tuser;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]   ch_wr_cmd_axis_tkeep;
wire [3:0]                      ch_wr_cmd_axis_tdest;
wire [3:0]                      ch_wr_cmd_axis_tid;

wire  [RX_CMD_ID_WIDTH-1:0]     ch_wr_cmd_id;
wire  [RX_CMD_ID_WIDTH-1:0]     ch_wr_cmd_id_tuser;
wire  [RX_CMD_ID_WIDTH/8-1:0]   ch_wr_cmd_id_tkeep;

wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     sp_wr_cmd_axis_tdata;
wire                            sp_wr_cmd_axis_tvalid;
wire                            sp_wr_cmd_axis_tlast;
wire                            sp_wr_cmd_axis_tready;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]    sp_wr_cmd_axis_tuser;
wire [(RX_WR_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]  sp_wr_cmd_axis_tkeep;
wire [3:0]                      sp_wr_cmd_axis_tdest;
wire [3:0]                      sp_wr_cmd_axis_tid;

wire  [RX_CMD_ID_WIDTH-1:0]     sp_wr_cmd_id;
wire  [RX_CMD_ID_WIDTH-1:0]     sp_wr_cmd_id_tuser;
wire  [RX_CMD_ID_WIDTH/8-1:0]   sp_wr_cmd_id_tkeep;

wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     ch_rd_cmd_axis_tdata;
wire                            ch_rd_cmd_axis_tvalid;
wire                            ch_rd_cmd_axis_tlast;
wire                            ch_rd_cmd_axis_tready;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]    ch_rd_cmd_axis_tuser;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]  ch_rd_cmd_axis_tkeep;
wire [3:0]                      ch_rd_cmd_axis_tdest;
wire [3:0]                      ch_rd_cmd_axis_tid;

wire  [RX_CMD_ID_WIDTH-1:0]     ch_rd_cmd_id;
wire  [RX_CMD_ID_WIDTH-1:0]     ch_rd_cmd_id_tuser;
wire  [RX_CMD_ID_WIDTH/8-1:0]   ch_rd_cmd_id_tkeep;

wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]     sp_rd_cmd_axis_tdata;
wire                            sp_rd_cmd_axis_tvalid;
wire                            sp_rd_cmd_axis_tlast;
wire                            sp_rd_cmd_axis_tready;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)-1:0]    sp_rd_cmd_axis_tuser;
wire [(RX_RD_CMD_DWIDTH+RX_CMD_ID_WIDTH)/8-1:0]  sp_rd_cmd_axis_tkeep;
wire [3:0]                      sp_rd_cmd_axis_tdest;
wire [3:0]                      sp_rd_cmd_axis_tid;

wire  [RX_CMD_ID_WIDTH-1:0]     sp_rd_cmd_id;
wire  [RX_CMD_ID_WIDTH-1:0]     sp_rd_cmd_id_tuser;
wire  [RX_CMD_ID_WIDTH/8-1:0]   sp_rd_cmd_id_tkeep;

wire S00_CMD_DECODE_ERR;           // output wire S00_DECODE_ERR
wire [31:0] S00_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] S00_FIFO_DATA_COUNT
wire [31:0] M00_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M00_FIFO_DATA_COUNT
wire [31:0] M01_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M01_FIFO_DATA_COUNT
wire [31:0] M02_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M02_FIFO_DATA_COUNT
wire [31:0] M03_CMD_FIFO_DATA_COUNT;  // output wire [31 : 0] M03_FIFO_DATA_COUNT
`endif