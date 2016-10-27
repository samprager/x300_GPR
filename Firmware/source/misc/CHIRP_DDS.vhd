-- Modified by Sam Prager
-- 5/30/2015
-- MiXIL, University of Southern Calfiornia
-- Chirp Generation using DUC_DDC.vhd


  --------------DDS Chirp Generation Parameters-------------------
  -- period = 4.17 us, BW = 46.08 MHz
  -- 491.52 Mhz clock, 4096 samples, 16 bit phase accumulator (n = 16)
  -- tuning_word_coeff = 3      for BW = 46.08 MHz (2048 samples)
  -- tuning_word_coeff = 4      for BW = 61.44 MHz (2048 samples)
  -- tuning_word_coeff = 1.5    for BW = 46.08 MHz (4096 samples)
  -- tuning_word_coeff = 2      for BW = 61.44 MHz (4096 samples)
  -- Calculated Using:
  --    tuning_word_coeff = BW*(2^n)/(num_samples*fClock)
  -- Taken From:
  --    tuning_word_coeff = period*slope*(2^n)/(num_samples*fClock)
  -- Where:
  --    slope = BW/period
  --    num_samples = period*fclock
  --
  -- Note: Derived From:
  --    tuning_word = rect[t/period] t*slope*(2^n)/fclock
  -- And:
  --     t = sample_count*period/num_samples
  -- Therefore:
  --    tuning_word = sample_count*tuning_coeff
  -------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- FILE NAME : CHIRP_DDS.vhd
--
-- AUTHOR    : Samuel Prager
--
-- Target Device: 7K325t-2ffg900
--
-------------------------------------------------------------------------------------
-- DESCRIPTION
-- ===========
--
-- This file encapsulates DUC and DDC.
-- In most cases ...
--	IF_IN will be driven from ADC at top-level
--	IF_OUT will drive the DAC at top-level
-------------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_misc.all;
  use ieee.std_logic_unsigned.all;

entity CHIRP_DDS is
generic (
  DDS_LATENCY : integer := 2 -- value of 15000 = approx 1 sec for ramp of length 2^14 samples @ 245.76 MSPS
);
port (
	CLOCK           		: in std_logic;
	RESET           		: in std_logic;

	IF_OUT_I					: out std_logic_vector(15 downto 0);
	IF_OUT_Q					: out std_logic_vector(15 downto 0);
	IF_OUT_VALID			: out std_logic;

  chirp_ready  : out std_logic;
  chirp_done  : out std_logic;
  chirp_active  : out std_logic;
  chirp_init  : in std_logic;
  chirp_enable : in std_logic;

  freq_offset_in : in std_logic_vector(31 downto 0);
  tuning_word_coeff_in : in std_logic_vector(31 downto 0);
  chirp_count_max_in : in std_logic_vector(31 downto 0)
);
end CHIRP_DDS;

architecture CHIRP_DDS_syn of CHIRP_DDS is
-- Added by SP
component SP_DDS
port (
  aclken : in std_logic;
  aclk   : in std_logic;
  s_axis_phase_tvalid : in std_logic;
  s_axis_phase_tdata: in std_logic_vector(15 downto 0);
  m_axis_data_tvalid : out std_logic;
  m_axis_data_tdata  : out std_logic_vector(31 downto 0)
);
end component;

signal clk					: std_logic;
signal rst			      : std_logic;

signal if_out_i_sig		: std_logic_vector(15 downto 0);
signal if_out_q_sig		: std_logic_vector(15 downto 0);
signal if_out_valid_sig	: std_logic;


-- For Chirp---------------------------------

signal chirp_ready_r  :  std_logic;
signal chirp_done_r  :   std_logic;
signal chirp_active_r  :  std_logic;
signal chirp_init_r  :   std_logic;
signal chirp_enable_r :  std_logic;

signal s_axis_phase_tvalid, m_axis_data_tvalid : std_logic;
--signal phase_acc  : std_logic_vector(15 downto 0) := (others=>'0');
signal chirp_i              : std_logic_vector(15 downto 0);
signal chirp_q            : std_logic_vector(15 downto 0);
signal dds_dout_chirp_i        : std_logic_vector(15 downto 0);
signal dds_dout_chirp_q        : std_logic_vector(15 downto 0);
signal dds_dout_chirp_i_q      : std_logic_vector(31 downto 0);
signal dds_dout_chirp_phase      : std_logic_vector(15 downto 0);

-- Use if using library ieee.std_logic_unsigned.all:
signal tuning_word  :std_logic_vector(31 downto 0) := (others=>'0');
signal phase_acc_long  :std_logic_vector(31 downto 0) := (others=>'0');
signal chirp_count  :std_logic_vector(31 downto 0) := (others=>'0');
signal chirp_count_max  :std_logic_vector(31 downto 0) := (11 downto 0 => '1',others=>'0');
signal tuning_word_coeff :std_logic_vector(31 downto 0) := (0=> '1',others=>'0');
signal freq_offset  :std_logic_vector(31 downto 0) := (10=>'1',9=>'1',others=>'0');

signal dds_latency_counter  :std_logic_vector(3 downto 0) := (others=>'0');


-- Use if using library ieee.numeric_std.all:
--signal tuning_word  :unsigned(31 downto 0) := (others=>'0');
--signal phase_acc_long  :unsigned(31 downto 0) := (others=>'0');
--signal chirp_count  :unsigned(9 downto 0) := (others=>'0');
--constant tuning_word_coeff :unsigned(31 downto 0) := (4=>'1',others=>'0');
--signal delay_count : unsigned(3 downto 0) := "0111";
--constant chirp_delay : unsigned(3 downto 0) := "0111";
-------------------------------


begin

clk <= CLOCK;
rst <= RESET;


chirp_init_r  <= chirp_init;
chirp_enable_r <= chirp_enable;



----------------------------------------------------------------------------------
-- A) DDS generating a Chirp signal based on a 15.36 Msps sample clock.
----------------------------------------------------------------------------------
SP_DDS_inst : SP_DDS
port map (
  --aclken     => signal_vout_DDS,
  aclken        => '1',
  aclk       => clk,
  m_axis_data_tvalid => m_axis_data_tvalid,
  s_axis_phase_tvalid => s_axis_phase_tvalid,
  s_axis_phase_tdata => dds_dout_chirp_phase,
  m_axis_data_tdata   => dds_dout_chirp_i_q
);

s_axis_phase_tvalid <= '1';
--dds_dout_chirp_phase <= phase_acc(15 downto 0);
dds_dout_chirp_phase <= phase_acc_long(15 downto 0);
dds_dout_chirp_i <= dds_dout_chirp_i_q(15 downto 0);
dds_dout_chirp_q <= dds_dout_chirp_i_q(31 downto 16);



------------------ Chirp Generation -----------------------
Chirp_Gen: process (clk)    -- 491.52 MHz clock
  begin
    if (rising_edge(clk)) then
      if (rst = '1') then
        chirp_count <= (others => '0');

        tuning_word <= (others => '0');
        --tuning_word(31 downto 0) <= freq_offset(31 downto 0);
        --phase_acc <= (others => '0');
        phase_acc_long <= (others => '0');
        chirp_i  <= (others => '0');
        chirp_q  <= (others => '0');

        chirp_active_r <= '0';
        chirp_done_r  <= '0';

-- Default values
        tuning_word_coeff <= (0=> '1',others=>'0');
        freq_offset <= (10=>'1',9=>'1',others=>'0');
        chirp_count_max <= (11 downto 0 => '1',others => '0');

        dds_latency_counter <= (others => '0');

      elsif (chirp_init_r = '1' and chirp_active_r = '0') then
        chirp_count <= (others => '0');
        --tuning_word(31 downto 0) <= freq_offset_in(31 downto 0);
        --phase_acc_long <= (others => '0');
        tuning_word <= freq_offset_in+tuning_word_coeff_in;
        phase_acc_long <= freq_offset_in;

        chirp_i  <= (others => '0');
        chirp_q  <= (others => '0');

        chirp_active_r <= '1';
        chirp_done_r <= '0';

        tuning_word_coeff <= tuning_word_coeff_in;
        freq_offset <= freq_offset_in;
        chirp_count_max <= chirp_count_max_in;

        dds_latency_counter <= (others => '0');

      elsif(chirp_active_r = '1') then

        if (dds_latency_counter >= (DDS_LATENCY-1)) then
            chirp_i <= dds_dout_chirp_i;
            chirp_q <= dds_dout_chirp_q;
        else
            dds_latency_counter <= dds_latency_counter + 1;
            chirp_i  <= (others => '0');
            chirp_q  <= (others => '0');
        end if;

        if (chirp_done_r = '1') then
            chirp_active_r <= '0';
            chirp_done_r <= '0';
        elsif (chirp_count >= (chirp_count_max-DDS_LATENCY+1)) then
            chirp_count <= (others => '0');
            tuning_word(31 downto 0) <= freq_offset(31 downto 0);
            chirp_done_r <= '1';
            phase_acc_long <= (others => '0');
        else
            chirp_count <= chirp_count + 1;
            tuning_word(31 downto 0) <= tuning_word(31 downto 0) + tuning_word_coeff;
            chirp_done_r <= '0';
            phase_acc_long(31 downto 0) <= phase_acc_long(31 downto 0) + tuning_word(31 downto 0);
        end if;
      else
          if (dds_latency_counter > 0) then
              chirp_i <= dds_dout_chirp_i;
              chirp_q <= dds_dout_chirp_q;
              dds_latency_counter <= dds_latency_counter - 1;
          else
              chirp_i  <= (others => '0');
              chirp_q  <= (others => '0');
          end if;
--          chirp_i  <= (others => '0');
--          chirp_q  <= (others => '0');
      end if;
    end if;
  end process Chirp_Gen;

process (clk) begin
if (rising_edge(clk)) then
  if(rst = '1') then
    chirp_ready_r <= '0';
  else
    chirp_ready_r <= '1';
  end if;
end if;
end process;

chirp_ready <= chirp_ready_r;
chirp_active <= chirp_active_r;
chirp_done <= chirp_done_r;

----------------------------------------------------------------------------------------------------
-- Output MUX - Select data connected to the physical DAC interface
----------------------------------------------------------------------------------------------------
TX_mux_to_DAC: process (clk)
begin
  if (rising_edge(clk)) then
	  if_out_i_sig <= chirp_i;	-- connect Chirp DDS output directly to DAC @ 245.76 MSPS
      if_out_q_sig <= chirp_q;
      if_out_valid_sig <= chirp_active_r;
  end if;
end process TX_mux_to_DAC;

IF_OUT_I <= if_out_i_sig;
IF_OUT_Q <= if_out_q_sig;
IF_OUT_VALID <= if_out_valid_sig;
--IF_OUT_I <= chirp_i;
--IF_OUT_Q <= chirp_q;
--IF_OUT_VALID <= '1';


----------------------------------------------------------------------------------------------------
-- End
----------------------------------------------------------------------------------------------------
end CHIRP_DDS_syn;
