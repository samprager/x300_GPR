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
  parameter CLK_FREQ = 245760000,    // Hz
  parameter CHIRP_PRP = 1000000, //Pule Repetition Period (usec)
  parameter ADC_SAMPLE_COUNT_INIT = 32'h000001fe,
  parameter CHIRP_PRF_INT_COUNT_INIT = 32'h00000000,
  parameter CHIRP_PRF_FRAC_COUNT_INIT = 32'h1d4c0000,
  parameter CHIRP_TUNING_COEF_INIT = 32'b1,
  parameter CHIRP_COUNT_MAX_INIT = 32'h00000dff, // 3584 samples
  parameter CHIRP_FREQ_OFFSET_INIT = 32'h0b00, // 2816 -> 10.56 MHz min freq
  parameter CHIRP_CTRL_WORD_INIT = 32'h20

)(
  input aclk,
  input aresetn,

//  input clk_mig,              // 200 MHZ OR 100 MHz
//  input mig_init_calib_complete,

  input clk_fmc150,           // 245.76 MHz
  input resetn_fmc150,
  input [3:0] fmc150_status_vector, // {pll_status, mmcm_adac_locked, mmcm_locked, ADC_calibration_good};

  input[31:0] chirp_time_int,
  input[31:0] chirp_time_frac,

  input [31:0] adc_sample_time,

  input [127:0] chirp_parameters_in,
  output [127:0] chirp_parameters_out,

  input chirp_ready,          // continuous high when dac ready
  input chirp_active,         // continuous high while chirping
  input chirp_done,           // single pulse when chirp finished
  output chirp_init,          // single pulse to initiate chirp
  output chirp_enable,        // continuous high while chirp enabled
  output adc_enable,          // high while adc samples saved

  input clk_eth,              // gtx_clk : 125 MHz
  input eth_resetn,
  input data_tx_ready,        // high when ready to transmit
  input data_tx_active,       // high while data being transmitted
  input data_tx_done,         // single pule when done transmitting
  output data_tx_init,        // single pulse to start tx data
  output data_tx_enable      // continuous high while transmit enabled

);
localparam CHIRP_PRF_COUNT_FAST = 24576;    //100 u sec CLK_FREQ*CHIRP_PRP;
localparam CHIRP_PRF_COUNT_SLOW = 10*CLK_FREQ;    //32'h927c0000 = 245760000  (10 sec)
localparam ADC_LIMIT = ADC_SAMPLE_COUNT_INIT;
localparam     IDLE        = 3'b000,
               ACTIVE      = 3'b001,
               CHIRP       = 3'b010,    // pulse chirp (and generate adc samples)
               COLLECT     = 3'b011,    // continue to collect adc samples
               PROCESS     = 3'b100,    // process adc samples
               WAIT        = 3'b101,    // wait to transmit samples
               TRANSMIT    = 3'b110,    // transmitting samples over ethernet
               OVERHEAD    = 3'b111;    // clean up before idle

reg [2:0] next_gen_state;
reg [2:0] gen_state;

reg [63:0] chirp_count;
reg [3:0] overhead_count;
reg [31:0] adc_collect_count;
reg [31:0] process_count;

reg chirp_ready_int;
reg chirp_active_int;
reg chirp_done_int;
reg chirp_init_int;
reg chirp_enable_int;
reg adc_enable_int;

reg data_tx_ready_int;
reg data_tx_active_int;
reg data_tx_done_int;
reg data_tx_init_int;
reg data_tx_enable_int;

wire chirp_prf_speed_sel;

reg[31:0] chirp_time_int_r = CHIRP_PRF_INT_COUNT_INIT;
reg[31:0] chirp_time_frac_r = CHIRP_PRF_FRAC_COUNT_INIT;//CHIRP_PRF_COUNT_SLOW;
reg[31:0] adc_sample_time_r = ADC_SAMPLE_COUNT_INIT;
reg[31:0] chirp_time_int_rr = CHIRP_PRF_INT_COUNT_INIT;
reg[31:0] chirp_time_frac_rr = CHIRP_PRF_FRAC_COUNT_INIT;//CHIRP_PRF_COUNT_SLOW;
reg[31:0] adc_sample_time_rr = ADC_SAMPLE_COUNT_INIT;
reg[31:0] chirp_time_int_rrr = CHIRP_PRF_INT_COUNT_INIT;
reg[31:0] chirp_time_frac_rrr = CHIRP_PRF_FRAC_COUNT_INIT;//CHIRP_PRF_COUNT_SLOW;
reg[31:0] adc_sample_time_rrr = ADC_SAMPLE_COUNT_INIT;
reg update_chirp_time_int = 1'b0;
reg update_chirp_time_frac = 1'b0;
reg update_adc_sample_time = 1'b0;


reg [31:0] ch_tuning_coef_r = CHIRP_TUNING_COEF_INIT;
reg [31:0] ch_counter_max_r = CHIRP_COUNT_MAX_INIT;
reg [31:0] ch_freq_offset_r = CHIRP_FREQ_OFFSET_INIT;
reg [31:0] ch_tuning_coef_rr = CHIRP_TUNING_COEF_INIT;
reg [31:0] ch_counter_max_rr = CHIRP_COUNT_MAX_INIT;
reg [31:0] ch_freq_offset_rr = CHIRP_FREQ_OFFSET_INIT;
reg [31:0] ch_tuning_coef_rrr = CHIRP_TUNING_COEF_INIT;
reg [31:0] ch_counter_max_rrr = CHIRP_COUNT_MAX_INIT;
reg [31:0] ch_freq_offset_rrr = CHIRP_FREQ_OFFSET_INIT;
reg [31:0] ch_ctrl_word_r = CHIRP_CTRL_WORD_INIT;
reg [31:0] ch_ctrl_word_rr = CHIRP_CTRL_WORD_INIT;
reg [31:0] ch_ctrl_word_rrr = CHIRP_CTRL_WORD_INIT;
reg update_ch_tuning_coef = 1'b0;
reg update_ch_counter_max = 1'b0;
reg update_ch_freq_offset = 1'b0;
reg update_ch_ctrl_word = 1'b0;

reg[63:0] chirp_prf_count_max = {CHIRP_PRF_INT_COUNT_INIT, CHIRP_PRF_FRAC_COUNT_INIT};

reg[31:0] adc_collect_count_max = ADC_LIMIT;

assign chirp_parameters_out = {ch_ctrl_word_rrr,ch_freq_offset_rrr,ch_tuning_coef_rrr,ch_counter_max_rrr};

// sync chirp param control inputs from reg map
always @(posedge clk_fmc150) begin
    if(~resetn_fmc150) begin
        ch_tuning_coef_r <= CHIRP_TUNING_COEF_INIT;
        ch_tuning_coef_rr <= CHIRP_TUNING_COEF_INIT;
        ch_tuning_coef_rrr <= CHIRP_TUNING_COEF_INIT;
        update_ch_tuning_coef  <= 1'b0;
    end else begin
        ch_tuning_coef_r <= chirp_parameters_in[63:32];
        ch_tuning_coef_rr <= ch_tuning_coef_r;
        if (ch_tuning_coef_rrr !== ch_tuning_coef_rr) begin
            ch_tuning_coef_rrr <= ch_tuning_coef_rr;
            update_ch_tuning_coef <= 1'b1;
        end else begin
             ch_tuning_coef_rrr <= ch_tuning_coef_rrr;
             update_ch_tuning_coef <= 1'b0;
        end
    end
end
always @(posedge clk_fmc150) begin
    if(~resetn_fmc150) begin
        ch_freq_offset_r <= CHIRP_FREQ_OFFSET_INIT;
        ch_freq_offset_rr <= CHIRP_FREQ_OFFSET_INIT;
        ch_freq_offset_rrr <= CHIRP_FREQ_OFFSET_INIT;
        update_ch_freq_offset <= 1'b0;
    end else begin
        ch_freq_offset_r <= chirp_parameters_in[95:64];
        ch_freq_offset_rr <= ch_freq_offset_r;
        if (ch_freq_offset_rrr !== ch_freq_offset_rr) begin
            ch_freq_offset_rrr <= ch_freq_offset_rr;
            update_ch_freq_offset <= 1'b1;
        end else begin
             ch_freq_offset_rrr <= ch_freq_offset_rrr;
             update_ch_freq_offset <= 1'b0;
        end
    end
end

always @(posedge clk_fmc150) begin
    if(~resetn_fmc150) begin
        ch_counter_max_r <= CHIRP_COUNT_MAX_INIT;
        ch_counter_max_rr <= CHIRP_COUNT_MAX_INIT;
        ch_counter_max_rrr <= CHIRP_COUNT_MAX_INIT;
        update_ch_counter_max <= 1'b0;
    end else begin
        ch_counter_max_r <= chirp_parameters_in[31:0];
        ch_counter_max_rr <= ch_counter_max_r;
        if (ch_counter_max_rrr !== ch_counter_max_rr) begin
            ch_counter_max_rrr <= ch_counter_max_rr;
            update_ch_counter_max <= 1'b1;
        end else begin
             ch_counter_max_rrr <= ch_counter_max_rrr;
             update_ch_counter_max <= 1'b0;
        end
    end
end

always @(posedge clk_fmc150) begin
    if(~resetn_fmc150) begin
        ch_ctrl_word_r <= CHIRP_CTRL_WORD_INIT;
        ch_ctrl_word_rr <= CHIRP_CTRL_WORD_INIT;
        ch_ctrl_word_rrr <= CHIRP_CTRL_WORD_INIT;
        update_ch_ctrl_word <= 1'b0;
    end else begin
        ch_ctrl_word_r <= chirp_parameters_in[127:96];
        ch_ctrl_word_rr <= ch_ctrl_word_r;
        if (ch_ctrl_word_rrr !== ch_ctrl_word_rr) begin
            ch_ctrl_word_rrr <= ch_ctrl_word_rr;
            update_ch_ctrl_word <= 1'b1;
        end else begin
             ch_ctrl_word_rrr <= ch_ctrl_word_rrr;
             update_ch_ctrl_word <= 1'b0;
        end
    end
end

 // sync chirp time control inputs from reg map
// always @(posedge aclk) begin
//     if(~aresetn) begin
//         chirp_time_int_r <= 32'b0; //32'd10;
//         chirp_time_frac_r <= 32'h927c0000;//32'b0;
//         adc_sample_time_r <= 32'hc8;
//         chirp_time_int_rr <= 32'b0; //32'd10;
//         chirp_time_frac_rr <= 32'h927c0000; //32'b0;
//         adc_sample_time_rr <= 332'hc8;
//         chirp_time_int_rrr <= 32'b0; //32'd10;
//         chirp_time_frac_rrr <= 32'h927c0000; //32'b0;
//         adc_sample_time_rrr <= 32'hc8;
//         update_chirp_time_int <= 1'b0;
//         update_chirp_time_frac <= 1'b0;
//         update_adc_sample_time <= 1'b0;
//      end else begin
//        chirp_time_int_r <= chirp_time_int;
//        chirp_time_frac_r <= chirp_time_frac;
//        adc_sample_time_r <= adc_sample_time;
//        chirp_time_int_rr <= chirp_time_int_r;
//        chirp_time_frac_rr <= chirp_time_frac_r;
//        adc_sample_time_rr <= adc_sample_time_r;
//        if (chirp_time_int_rrr !== chirp_time_int_rr) begin
//             chirp_time_int_rrr <= chirp_time_int_rr;
//             chirp_time_frac_rrr <= chirp_time_frac_rrr;
//             adc_sample_time_rrr <= adc_sample_time_rrr;
//             update_chirp_time_int <= 1'b1;
//             update_chirp_time_frac <= 1'b0;
//             update_adc_sample_time <= 1'b0;
//        end else if (chirp_time_frac_rrr !== chirp_time_frac_rr) begin
//              chirp_time_int_rrr <= chirp_time_int_rrr;
//              chirp_time_frac_rrr <= chirp_time_frac_rr;
//              adc_sample_time_rrr <= adc_sample_time_rrr;
//              update_chirp_time_int <= 1'b0;
//              update_chirp_time_frac <= 1'b1;
//              update_adc_sample_time <= 1'b0;
//        end else if (adc_sample_time_rrr !== adc_sample_time_rr) begin
//               chirp_time_int_rrr <= chirp_time_int_rrr;
//               chirp_time_frac_rrr <= chirp_time_frac_rrr;
//               adc_sample_time_rrr <= adc_sample_time_rr;
//               update_chirp_time_int <= 1'b0;
//               update_chirp_time_frac <= 1'b0;
//               update_adc_sample_time <= 1'b1;
//         end else begin
//              chirp_time_int_rrr <= chirp_time_int_rrr;
//              chirp_time_frac_rrr <= chirp_time_frac_rrr;
//              adc_sample_time_rrr <= adc_sample_time_rrr;
//              update_chirp_time_int <= 1'b0;
//              update_chirp_time_frac <= 1'b0;
//              update_adc_sample_time <= 1'b0;
//          end
//     end
// end
always @(posedge aclk) begin
    if(~aresetn) begin
        chirp_time_int_r <= CHIRP_PRF_INT_COUNT_INIT;
        chirp_time_int_rr <= CHIRP_PRF_INT_COUNT_INIT;
        chirp_time_int_rrr <= CHIRP_PRF_INT_COUNT_INIT;
        update_chirp_time_int <= 1'b0;
    end else begin
        chirp_time_int_r <= chirp_time_int;
        chirp_time_int_rr <= chirp_time_int_r;
        if (chirp_time_int_rrr !== chirp_time_int_rr) begin
            chirp_time_int_rrr <= chirp_time_int_rr;
            update_chirp_time_int <= 1'b1;
        end else begin
             chirp_time_int_rrr <= chirp_time_int_rrr;
             update_chirp_time_int <= 1'b0;
        end
    end
end
 // sync chirp time control inputs from reg map
always @(posedge aclk) begin
    if(~aresetn) begin
        chirp_time_frac_r <= CHIRP_PRF_FRAC_COUNT_INIT;//CHIRP_PRF_COUNT_SLOW;
        chirp_time_frac_rr <= CHIRP_PRF_FRAC_COUNT_INIT; //CHIRP_PRF_COUNT_SLOW;
        chirp_time_frac_rrr <= CHIRP_PRF_FRAC_COUNT_INIT; //CHIRP_PRF_COUNT_SLOW;
        update_chirp_time_frac <= 1'b0;
    end else begin
        chirp_time_frac_r <= chirp_time_frac;
        chirp_time_frac_rr <= chirp_time_frac_r;
        if (chirp_time_frac_rrr !== chirp_time_frac_rr) begin
            chirp_time_frac_rrr <= chirp_time_frac_rr;
            update_chirp_time_frac <= 1'b1;
        end else begin
             chirp_time_frac_rrr <= chirp_time_frac_rrr;
             update_chirp_time_frac <= 1'b0;
        end
    end
end
 // sync chirp time control inputs from reg map
always @(posedge aclk) begin
    if(~aresetn) begin
        adc_sample_time_r <= ADC_SAMPLE_COUNT_INIT;
        adc_sample_time_rr <= ADC_SAMPLE_COUNT_INIT;
        adc_sample_time_rrr <= ADC_SAMPLE_COUNT_INIT;
        update_adc_sample_time <= 1'b0;
    end else begin
        adc_sample_time_r <= adc_sample_time;
        adc_sample_time_rr <= adc_sample_time_r;
        if (adc_sample_time_rrr !== adc_sample_time_rr) begin
            adc_sample_time_rrr <= adc_sample_time_rr;
            update_adc_sample_time <= 1'b1;
        end else begin
             adc_sample_time_rrr <= adc_sample_time_rrr;
             update_adc_sample_time <= 1'b0;
        end
    end
end

//always @(update_chirp_time_int or update_chirp_time_frac)
//begin
//    //chirp_prf_count_max = chirp_time_int_rrr*CLK_FREQ+chirp_time_frac_rrr*CLK_FREQ/1000000;
//    chirp_prf_count_max[63:32] <= chirp_time_int_rrr[31:0];
//    chirp_prf_count_max[31:0] <= chirp_time_frac_rrr[31:0];
// end

// always @(update_adc_sample_time)
// begin
//     adc_collect_count_max = adc_sample_time_rrr;
//  end


always @(posedge aclk)
begin
    if(~aresetn)
        adc_collect_count_max <= ADC_LIMIT;
   // else if (update_adc_sample_time)
    else
        adc_collect_count_max <= adc_sample_time_rrr;
end

always @(posedge aclk)
  begin
    if(~aresetn)
      chirp_prf_count_max <=  {CHIRP_PRF_INT_COUNT_INIT, CHIRP_PRF_FRAC_COUNT_INIT};
    else  begin
      chirp_prf_count_max[63:32] <= chirp_time_int_rrr[31:0];
      chirp_prf_count_max[31:0] <= chirp_time_frac_rrr[31:0];
     end
end

always @(posedge aclk)
begin
  if(~aresetn)
    chirp_count <= 0;
  else if (gen_state == ACTIVE & (|chirp_count))
    chirp_count <= chirp_count - 1;
  else if (gen_state == IDLE) begin
        chirp_count <= chirp_prf_count_max;
  //  if (chirp_prf_speed_sel)
//    if (chirp_time_int_r == 32'b1)
//        chirp_count <= CHIRP_PRF_COUNT_FAST;
//    else
//        chirp_count <= CHIRP_PRF_COUNT_SLOW;

   end
end

always @(posedge aclk)
begin
  if(~aresetn)
    adc_collect_count <= 0;
  else if (gen_state == COLLECT & (|adc_collect_count))
    adc_collect_count <= adc_collect_count - 1;
  else if (gen_state == IDLE)
    adc_collect_count <= adc_collect_count_max;
end

always @(posedge aclk)
begin
  if(~aresetn)
    process_count <= 0;
  else if (gen_state == PROCESS & (|process_count))
    process_count <= process_count - 1;
  else if (gen_state == IDLE)
    process_count <= 2;
end

always @(posedge aclk)
begin
  if(~aresetn)
    overhead_count <= 0;
  else if (gen_state == OVERHEAD & (|overhead_count))
    overhead_count <= overhead_count - 1;
  else if (gen_state == IDLE)
    overhead_count <= 2;
end

always @(gen_state or chirp_count or chirp_done or chirp_ready or
          data_tx_ready or data_tx_done or overhead_count or //fmc150_status_vector or
           adc_collect_count or process_count)
begin
   next_gen_state = gen_state;
   case (gen_state)
      IDLE : begin
         if (chirp_ready) //& (&fmc150_status_vector[3:1]))
            next_gen_state = ACTIVE;
      end
      ACTIVE : begin
         if (chirp_ready & (chirp_count == 0)) //& (&fmc150_status_vector[3:1]))
            next_gen_state = CHIRP;
      end
      CHIRP : begin
         if (chirp_done)
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
      // Skip Transmit Control for now
      WAIT : begin
         if (data_tx_ready) begin
            next_gen_state = TRANSMIT;
         end
      end
      TRANSMIT : begin
         if (data_tx_done) begin
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

always @(posedge aclk)
begin
   if (~aresetn) begin
      gen_state <= IDLE;
   end
   else begin
       gen_state <= next_gen_state;
   end
end

always @(posedge clk_fmc150)
begin
  if(~resetn_fmc150)
    chirp_enable_int <= 1'b0;
  else if (gen_state ==  CHIRP)
    chirp_enable_int <= 1'b1;
  else
    chirp_enable_int <= 1'b0;
end

always @(posedge clk_fmc150)
begin
  if(~resetn_fmc150)
    chirp_init_int <= 1'b0;
  else if (gen_state ==  CHIRP & !chirp_active & !chirp_enable_int)
    chirp_init_int <= 1'b1;
  else
    chirp_init_int <= 1'b0;
end

always @(posedge clk_fmc150)
begin
  if(~resetn_fmc150)
    adc_enable_int <= 1'b0;
  else if (gen_state == CHIRP | gen_state == COLLECT)
    adc_enable_int <= 1'b1;
  else
    adc_enable_int <= 1'b0;
end

always @(posedge clk_eth)
begin
  if(~eth_resetn)
    data_tx_enable_int <= 1'b0;
  else if (gen_state == TRANSMIT)
    data_tx_enable_int <= 1'b1;
  else
    data_tx_enable_int <= 1'b0;
end

always @(posedge clk_eth)
begin
  if(~eth_resetn)
    data_tx_init_int <= 1'b0;
  else if (gen_state == TRANSMIT & !data_tx_active)
    data_tx_init_int <= 1'b1;
  else
    data_tx_init_int <= 1'b0;
end

assign chirp_enable = chirp_enable_int;
assign chirp_init = chirp_init_int;
assign adc_enable = adc_enable_int;
assign data_tx_enable = data_tx_enable_int;
assign data_tx_init = data_tx_init_int;

endmodule
