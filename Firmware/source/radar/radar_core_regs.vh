
/********************************************************
** Waveform Generator and Radar Control Blocks: 200-223
********************************************************/
localparam [7:0] SR_CH_COUNTER_ADDR = 200;
localparam [7:0] SR_CH_TUNING_COEF_ADDR = 201;
localparam [7:0] SR_CH_FREQ_OFFSET_ADDR = 202;
localparam [7:0] SR_AWG_CTRL_WORD_ADDR = 203;

localparam [7:0] SR_PRF_INT_ADDR = 204;
localparam [7:0] SR_PRF_FRAC_ADDR = 205;
localparam [7:0] SR_ADC_SAMPLE_ADDR = 206;

localparam [7:0] SR_RADAR_CTRL_POLICY = 207;
localparam [7:0] SR_RADAR_CTRL_COMMAND = 208;
localparam [7:0] SR_RADAR_CTRL_TIME_HI = 209;
localparam [7:0] SR_RADAR_CTRL_TIME_LO = 210;
localparam [7:0] SR_RADAR_CTRL_CLEAR_CMDS = 211;

/* Daughter board control readback registers */
localparam [7:0] RB_RADAR_RUN = 32;
localparam [7:0] RB_RADAR_CTRL = 33;
localparam [7:0] RB_RADAR_PRF = 34;
