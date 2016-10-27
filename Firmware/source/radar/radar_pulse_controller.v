`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: MiXIL
// Engineer: Samuel Prager
//
// Create Date: 06/8/2016 02:25:19 PM
// Design Name:
// Module Name: radar_pulse_controller
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module radar_pulse_controller #(
  parameter CLK_FREQ = 200000000,    // Hz
  parameter CHIRP_PRP = 1000000, //Pule Repetition Period (usec)
  parameter ADC_SAMPLE_COUNT_INIT = 32'h000001fe,
  parameter CHIRP_PRF_INT_COUNT_INIT = 32'h00000000,
  parameter CHIRP_PRF_FRAC_COUNT_INIT = 32'h1d4c0000,
  parameter RADAR_POLICY_INIT = 32'd0,

  parameter SR_PRF_INT_ADDR = 0,
  parameter SR_PRF_FRAC_ADDR = 1,
  parameter SR_ADC_SAMPLE_ADDR = 2,
  parameter SR_RADAR_CTRL_POLICY = 3,
  parameter SR_RADAR_CTRL_COMMAND = 4,
  parameter SR_RADAR_CTRL_TIME_HI = 5,
  parameter SR_RADAR_CTRL_TIME_LO = 6,
  parameter SR_RADAR_CTRL_CLEAR_CMDS = 7

)(
  input clk,
  input reset,

  input [63:0] vita_time,

  input set_stb, input [7:0] set_addr, input [31:0] set_data,

  output [31:0] num_adc_samples,
  output [63:0] radar_prf,
  input awg_data_valid,
  output adc_run,
  output adc_last,

  input awg_ready,          // continuous high when dac ready
  input awg_active,         // continuous high while chirping
  input awg_done,           // single pulse when chirp finished
  output awg_init,          // single pulse to initiate chirp
  output awg_enable,        // continuous high while chirp enabled
  output adc_enable          // high while adc samples saved

);
localparam     IDLE        = 3'b000,
               ACTIVE      = 3'b001,
               CHIRP       = 3'b010,    // pulse chirp (and generate adc samples)
               COLLECT     = 3'b011,    // continue to collect adc samples
               PROCESS     = 3'b100,    // process adc samples
               OVERHEAD    = 3'b101;    // clean up before idle

localparam AUTONOMOUS_MODE = 32'b0;
localparam DEPENDENT_MODE = 32'b1;
localparam OVERHEAD_COUNT_MAX = 2;
localparam PROCESS_COUNT_MAX = 64;

reg [2:0] next_gen_state;
reg [2:0] gen_state;

reg [63:0] chirp_count;
reg [3:0] overhead_count;
reg [31:0] adc_collect_count;
reg [31:0] process_count;

reg awg_ready_int;
reg awg_active_int;
reg awg_done_int;
reg awg_init_int;
reg awg_enable_int;
reg adc_enable_int;
reg adc_run_int;
reg adc_last_int;

wire [31:0] chirp_count_int;
wire [31:0] chirp_count_frac;
wire [31:0] adc_sample_count;

wire update_chirp_count_int;
wire update_chirp_count_frac;
wire update_adc_sample_count;

reg update_prf_count_max;

reg[63:0] chirp_prf_count_max = {CHIRP_PRF_INT_COUNT_INIT, CHIRP_PRF_FRAC_COUNT_INIT};

reg[31:0] adc_collect_count_max = ADC_SAMPLE_COUNT_INIT;

wire [31:0] command_i;
wire [63:0] time_i;
wire [31:0] policy;
wire store_command;

wire send_imm, chain, reload, stop;
wire [27:0] numlines;
wire [63:0] rcvtime;
wire use_timestamps;

wire now, early, late;
wire command_valid;
reg command_ready;
wire clear_cmds;

// assign chirp_parameters_out = {ch_ctrl_word_rrr,ch_freq_offset_rrr,ch_tuning_coef_rrr,ch_counter_max_rrr};

setting_reg #(.my_addr(SR_PRF_INT_ADDR), .at_reset(CHIRP_PRF_INT_COUNT_INIT)) sr_prf_int_count (
  .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
  .in(set_data),.out(chirp_count_int),.changed(update_chirp_count_int));

setting_reg #(.my_addr(SR_PRF_FRAC_ADDR), .at_reset(CHIRP_PRF_FRAC_COUNT_INIT)) sr_prf_frac_count (
  .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
  .in(set_data),.out(chirp_count_frac),.changed(update_chirp_count_frac));

setting_reg #(.my_addr(SR_ADC_SAMPLE_ADDR), .at_reset(ADC_SAMPLE_COUNT_INIT)) sr_adc_sample_count (
  .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
  .in(set_data),.out(adc_sample_count),.changed(update_adc_sample_count));

 setting_reg #(.my_addr(SR_RADAR_CTRL_POLICY), .at_reset(RADAR_POLICY_INIT)) sr_policy (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(policy),.changed());

  setting_reg #(.my_addr(SR_RADAR_CTRL_COMMAND))
  sr_cmd (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(command_i),.changed());

  setting_reg #(.my_addr(SR_RADAR_CTRL_TIME_HI)) sr_time_h (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(time_i[63:32]),.changed());

  setting_reg #(.my_addr(SR_RADAR_CTRL_TIME_LO)) sr_time_l (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(time_i[31:0]),.changed(store_command));

  setting_reg #(.my_addr(SR_RADAR_CTRL_CLEAR_CMDS)) sr_clear_cmds (
    .clk(clk),.rst(reset),.strobe(set_stb),.addr(set_addr),
    .in(set_data),.out(),.changed(clear_cmds));

  axi_fifo_short #(.WIDTH(96)) commandfifo (
    .clk(clk),.reset(reset),.clear(clear_cmds),
    .i_tdata({command_i,time_i}), .i_tvalid(store_command), .i_tready(),
    .o_tdata({send_imm,chain,reload,stop,numlines,rcvtime}),
    .o_tvalid(command_valid), .o_tready(command_ready),
    .occupied(), .space() );

    time_compare time_compare (
      .clk(clk), .reset(reset),
      .time_now(vita_time), .trigger_time(rcvtime), .now(now), .early(early), .late(late), .too_early());

 always @(posedge clk)
  begin
      update_prf_count_max <= (update_chirp_count_int | update_chirp_count_frac);
  end


always @(posedge clk)
begin
    if(reset)
      adc_collect_count_max <= ADC_SAMPLE_COUNT_INIT;
   // else if (update_adc_sample_time)
    else
     //   adc_collect_count_max <= adc_sample_time_rrr;
     adc_collect_count_max <= adc_sample_count;
end

always @(posedge clk)
  begin
    if(reset)
      chirp_prf_count_max <=  {CHIRP_PRF_INT_COUNT_INIT, CHIRP_PRF_FRAC_COUNT_INIT};
    else  begin
    //   chirp_prf_count_max[63:32] <= chirp_time_int_rrr[31:0];
    //   chirp_prf_count_max[31:0] <= chirp_time_frac_rrr[31:0];
    chirp_prf_count_max[63:32] <= chirp_count_int[31:0];
    chirp_prf_count_max[31:0] <= chirp_count_frac[31:0];
     end
end

always @(posedge clk)
begin
  if(reset)
    chirp_count <= 0;
  else if (gen_state == ACTIVE) begin
    if (update_prf_count_max)
        chirp_count <= chirp_prf_count_max;
    else if (|chirp_count)
        chirp_count <= chirp_count - 1;
  end else begin
        chirp_count <= chirp_prf_count_max;
  end
end

always @(posedge clk)
begin
  if(reset)
    adc_collect_count <= 0;
  else if (gen_state == COLLECT) begin
    if (|adc_collect_count)
        adc_collect_count <= adc_collect_count - 1;
  end else begin
    adc_collect_count <= adc_collect_count_max;
  end
end

always @(posedge clk)
begin
  if(reset)
    process_count <= 0;
  else if (gen_state == PROCESS & (|process_count))
    process_count <= process_count - 1;
  else if (gen_state == IDLE)
    process_count <= PROCESS_COUNT_MAX;
end

always @(posedge clk)
begin
  if(reset)
    overhead_count <= 0;
  else if (gen_state == OVERHEAD & (|overhead_count))
    overhead_count <= overhead_count - 1;
  else if (gen_state == IDLE)
    overhead_count <= OVERHEAD_COUNT_MAX;
end

always @(posedge clk)
begin
  if(reset)
    command_ready <= 1'b0;
  else if ((gen_state == IDLE & (policy ==  DEPENDENT_MODE & command_valid & (send_imm | late | now)))|(policy ==  AUTONOMOUS_MODE))
    command_ready <= 1'b1;
  else
    command_ready <= 1'b0;
end

always @(gen_state or chirp_count or awg_done or awg_ready or overhead_count or adc_collect_count or process_count or policy or command_valid or now or send_imm)
begin
   next_gen_state = gen_state;
   case (gen_state)
      IDLE : begin
         if (awg_ready) begin //& (&fmc150_status_vector[3:1]))
            if (policy == AUTONOMOUS_MODE)
                next_gen_state = ACTIVE;
            if (policy ==  DEPENDENT_MODE & command_valid) begin
               if (now | send_imm) begin
                    next_gen_state = CHIRP;
               end
            end
        end

      end
      ACTIVE : begin
         if (awg_ready & (chirp_count == 0)) //& (&fmc150_status_vector[3:1]))
            next_gen_state = CHIRP;
         else if (policy ==  DEPENDENT_MODE )
            next_gen_state = IDLE;
      end
      CHIRP : begin
         if (awg_done)
            next_gen_state = COLLECT;
      end
      COLLECT : begin
         if (adc_collect_count == 1)
            next_gen_state = PROCESS;
      end
      PROCESS : begin
         if (process_count == 1) begin
            //next_gen_state = WAIT;
            next_gen_state = OVERHEAD;
         end
      end
      OVERHEAD : begin
         if (overhead_count == 1) begin
            next_gen_state = IDLE;
         end
      end
      default : begin
         next_gen_state = IDLE;
      end
   endcase
end

always @(posedge clk)
begin
   if (reset) begin
      gen_state <= IDLE;
   end
   else begin
       gen_state <= next_gen_state;
   end
end

always @(posedge clk)
begin
  if(reset)
    awg_enable_int <= 1'b0;
  else if (gen_state ==  CHIRP)
    awg_enable_int <= 1'b1;
  else
    awg_enable_int <= 1'b0;
end

always @(posedge clk)
begin
  if(reset)
    awg_init_int <= 1'b0;
  else if (gen_state ==  CHIRP & !awg_active & !awg_enable_int)
    awg_init_int <= 1'b1;
  else
    awg_init_int <= 1'b0;
end

always @(posedge clk)
begin
  if(reset)
    adc_enable_int <= 1'b0;
  else if (gen_state == CHIRP | gen_state == COLLECT)
    adc_enable_int <= 1'b1;
  else
    adc_enable_int <= 1'b0;
end

always @(posedge clk)
begin
  if(reset)
    adc_run_int <= 1'b0;
  else if (awg_done | gen_state == COLLECT)
    adc_run_int <= 1'b1;
  else
    adc_run_int <= 1'b0;
end

always @(posedge clk)
begin
  if(reset)
    adc_last_int <= 1'b0;
  else if (gen_state == COLLECT & adc_collect_count == 1)
    adc_last_int <= 1'b1;
  else
    adc_last_int <= 1'b0;
end


assign awg_enable = awg_enable_int;
assign awg_init = awg_init_int;
assign adc_enable = adc_enable_int;
assign num_adc_samples = adc_sample_count + 1'b1;

assign adc_run = adc_run_int | awg_data_valid;
assign adc_last = adc_last_int;
assign radar_prf = chirp_prf_count_max;

endmodule
