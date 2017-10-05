 ----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: top
-- Module Name: top - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: Zybo 
-- Tool Versions: Vivado 2015.4
-- Description: Top level module with component instantiation 
-- Dependencies: bridge_controller, bram_tdp, clk_divider, fetcher, OUT_FIFO, DATA_FIFO, ADDRESS_FIFO, rr_scheduler,
-- master_counter_comp, phase_memory, offset_memory, wave_typ_memory, phase_amplitude, inc_factor, offset_amplitude, 
-- init_controller, stimulus_cell and adder_sp_p1_wrapper
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: Uses HLS generated single precition floating point adder which makes it FPGA family dependent,
-- regenerate new IP for required device family, add the new IP to block diagram with name adder_sp_p1,
-- make all its ports external and regenerate vhdl auto generated wrapper to make it compatable for new device
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.StimG_Pkg.ALL;

ENTITY top IS
    GENERIC (
        pulse_number : INTEGER := 4;
        pulse_number_bits : INTEGER := 2;
        Rtc : INTEGER := 50000; --in nano seconds
        PhyC : INTEGER := 2;
        StimC : INTEGER := 10;
        StimC_bits : INTEGER := 4;
        Clock_div : INTEGER := 5000;
        FIFO_size : INTEGER := 1024
    );
    PORT (
             M_AXIS_ACLK	: in std_logic;
             M_AXIS_ARESETN : in std_logic;
             cluster_rdy    : in STD_LOGIC;
             cluster_in_ack : in STD_LOGIC;
             cluster_in_str : out STD_LOGIC;
             cluster_in_type : out STD_LOGIC_VECTOR (1 downto 0);
             cluster_in_data : out STD_LOGIC_VECTOR (31 downto 0);
             cluster_in_adr : out STD_LOGIC_VECTOR (StimC_bits-1 downto 0);
             reset 		: IN STD_LOGIC;
             clock         : IN STD_LOGIC;
             start         : IN STD_LOGIC;
             init_str    : IN STD_LOGIC;
             init_in_typ    : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
             cell_in_address : IN STD_LOGIC_VECTOR(StimC_bits-1 DOWNTO 0) ;
             pulse_in_address: IN  STD_LOGIC_VECTOR(pulse_number_bits-1 DOWNTO 0);
             init_in_data_top: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
             init_ack    : OUT STD_LOGIC;   
             start_ack    : OUT STD_LOGIC
        );
END top;
ARCHITECTURE rtl OF top IS
    CONSTANT TSF : INTEGER := StimC/Phyc;-- Time sharing factor
    SUBTYPE int_r IS INTEGER RANGE 0 To(TSF*pulse_number)-1;
    SUBTYPE int_w IS INTEGER RANGE 0 To(TSF)-1;
    SUBTYPE int_s IS INTEGER RANGE 0 to StimC-1;
    TYPE int_array_r IS ARRAY (INTEGER RANGE <>) OF int_r;
    TYPE int_array_w IS ARRAY (INTEGER RANGE <>) OF int_w;
    TYPE int_array_s IS ARRAY (INTEGER RANGE <>) OF int_s;
    TYPE std_logic_array_ud IS ARRAY (INTEGER RANGE <>) OF STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
--clock signal
    SIGNAL clock_rt : STD_LOGIC;
--write enable into local memory
    SIGNAL we_phase, we_offset, we_wave_typ,we_phase_amp,we_offset_amp,we_inc_factor : std_logic_array(0 to PhyC-1);
--read address into local memory
    SIGNAL read_address_phase,read_address_offset,read_address_phase_amp,read_address_inc_factor,read_address_offset_amp : int_array_r(0 to PhyC-1);
    SIGNAL  stim_address:std_logic_32_array(0 to PhyC-1);
    SIGNAL read_address_wave : int_array_w(0 to PhyC-1);
--write data into local memory
    SIGNAL	init_out_phase,init_out_off,init_out_phase_amp,init_out_offset_amp,init_out_inc_factor : std_logic_32_array(0 to PhyC-1);
    SIGNAL	init_out_w_typ : 	 std_logic_array(0 to PhyC-1);
--write address into local memory
    SIGNAL	wave_typ_address:	 INTEGER RANGE 0 TO (TSF)-1; 
    SIGNAL	address_out_write :	 INTEGER RANGE 0 TO (TSF*pulse_number)-1;
--read data into local memory
    SIGNAL  q_data_phase,q_data_offset :  std_logic_32_array(0 to PhyC-1);
    SIGNAL	q_data_phase_amp,q_data_offset_amp, q_data_inc_factor:   std_logic_32_array(0 to PhyC-1);
    SIGNAL  stim_data: std_logic_32_array(0 to PhyC-1);
    SIGNAL 	q_data_wave:  std_logic_array(0 to PhyC-1);
--fetcher signals
    SIGNAL cell_ready, stim_we :std_logic_array(0 to PhyC-1); 
    SIGNAL cell_ready_merged: std_logic;
    SIGNAL master_count, master_count_cock  : STD_LOGIC_VECTOR (31 DOWNTO 0);
--FIFO signals
    SIGNAL DATA_FIFO_Empty, DATA_FIFO_Full, ADDRESS_FIFO_Full, ADDRESS_FIFO_Empty :std_logic_array(0 to PhyC-1); 
    SIGNAL DATA_FIFO_ReadEn, ADDRESS_FIFO_ReadEn : std_logic_array(0 to PhyC-1);
    SIGNAL ADDRESS_FIFO_DataOut : std_logic_32_array(0 to PhyC-1);
    SIGNAL DATA_FIFO_DataOut : std_logic_32_array(0 to PhyC-1);
    SIGNAL scheduler_DataOut:STD_LOGIC_VECTOR(31 downto 0);
--extra signals
    SIGNAL	start_s, we_out_scheduler :  STD_LOGIC;
    SIGNAL	scheduler_ADDRESS_out : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL	scheduler_ADDRESS_top : STD_LOGIC_VECTOR(31 DOWNTO 0);
--signals for sigG
    SIGNAL data_in_local_counter_cell,data_out_local_counter_cell : std_logic_32_array(0 to PhyC-1);
    SIGNAL phase_length,offset_length,master_counter    : std_logic_32_array(0 to PhyC-1);
    SIGNAL wave_type :std_logic_array(0 to PhyC-1); 
    SIGNAL inc_step,Float_adder_out, data_in_internal_amp,data_in_phase_amp_cell,data_in_offset_amp_cell,data_out_internal_amp_cell : 		std_logic_32_array(0 to PhyC-1);
    SIGNAL tsf_in,tsf_out,tsf_out_amp : int_array_w(0 to PhyC-1);
    SIGNAL cell_address_in : std_logic_32_array(0 to PhyC-1);  
    SIGNAL data_in_pulse_counter_cell, data_out_pulse_counter_cell : std_logic_array_ud(0 to PhyC-1);  
    SIGNAL data_internal    : STD_LOGIC_VECTOR(63 DOWNTO 0);  --was inout
 -- bram_tdp signals
    SIGNAL a_wr    :   std_logic:='1';
    SIGNAL b_wr    :   std_logic:='0';
    SIGNAL a_addr,b_addr  :   std_logic_vector(0 downto 0):= (others => '0');
    SIGNAL b_din:   std_logic_vector(31 downto 0) := (others => '0');
    SIGNAL a_dout   :   std_logic_vector(31 downto 0);
-- bridge_controller signals
    SIGNAL Read_En : STD_LOGIC;
    SIGNAL address_out    : STD_LOGIC_VECTOR(31 DOWNTO 0);
    SIGNAL data_out    : STD_LOGIC_VECTOR(31 DOWNTO 0); 
    SIGNAL valid        : STD_LOGIC;
BEGIN
start_s<= start;
data_out<=data_internal(63 downto 32);
address_out<=data_internal(31 downto 0);

scheduler_ADDRESS_top<= scheduler_ADDRESS_out;
----------------------------------------------------------------------------------------------------------------------------------
cell_merge_proc:process(clock) -- process that merges all cell ready into one, to prevent synthesis tool removal of useful logic
----------------------------------------------------------------------------------------------------------------------------------
	begin
	IF (clock'event AND clock = '1') THEN
	merge(cell_ready,cell_ready_merged);
	end if;
	end process cell_merge_proc;
start_ack<=cell_ready_merged;   
----------------------------------------------------------------------------------------------------------------------------------
uut_bridge_controller: COMPONENT bridge_controller --COMPONENT Bridge controller to bridge the data from Stimulus generator
-- to make output compatable with Jan's ION implementation
----------------------------------------------------------------------------------------------------------------------------------
          GENERIC MAP(
            StimC_bits
             )
    Port map ( 
	       M_AXIS_ACLK	=> M_AXIS_ACLK,
	       M_AXIS_ARESETN => M_AXIS_ARESETN,
	       cluster_rdy => cluster_rdy,
           cluster_in_ack => cluster_in_ack,
           cluster_in_str => cluster_in_str,
           Read_En => Read_En,
           cluster_in_type => cluster_in_type,
           cluster_in_data => cluster_in_data,
           cluster_in_adr  => cluster_in_adr,
           data_valid => valid,
           data_in => data_out,
           address_in => address_out);
----------------------------------------------------------------------------------------------------------------------------------
uut_bram_tdp: COMPONENT bram_tdp -- COMPONENT Dual port BRAM used to cross clock domain
 ----------------------------------------------------------------------------------------------------------------------------------
        generic map(
            32, 1  
        )
        port map(
            -- Port A for write
            a_clk => clock_rt,  
            a_wr  => a_wr, -- connected to 1 
            a_addr  => a_addr, -- connected to 0
            a_din   => master_count,
            a_dout  => a_dout,            
            -- Port B for read
            b_clk  => clock,
            b_wr   =>  b_wr, -- connected to 0
            b_addr  => b_addr, -- connected to 0
            b_din => b_din,  
            b_dout  => master_count_cock -- read data
        );
 ----------------------------------------------------------------------------------------------------------------------------------
uut_clk_divider: COMPONENT clk_divider --COMPONENT Clock divider to produce real time clock of 50us from input clock
-- uses generic Clock_div parameter which represents Fin/Fout where Fin is input frequency and Fout 20kHz(50us)
----------------------------------------------------------------------------------------------------------------------------------
GENERIC MAP (
		Clock_div
	)
    Port map (
        clk_in=> clock,
        reset  => reset, 
        cell_ready => cell_ready_merged,
        clk_out => clock_rt
    );
    
uut_fetcher: for i in 0 to PhyC-1 generate 
 ----------------------------------------------------------------------------------------------------------------------------------
uut_fetcher_in: COMPONENT fetcher --COMPONENT Fetcher fetches input data from memory(Synchronous read/write BRAM) to Stimulus cell 
 --marking the frist stage of pipeline
 ----------------------------------------------------------------------------------------------------------------------------------
  generic map ( PhyC, pulse_number,pulse_number_bits,TSF
        )
   PORT map
   (   
    reset=>reset,
    clock => clock,
    start => start_s,
    cell_ready => cell_ready(i),
    master_count => master_count_cock,
    coc_number=> i,
--read from local memory 
    read_address_phase => read_address_phase(i),
    read_address_offset => read_address_offset(i),
    read_address_phase_amp => read_address_phase_amp(i),
    read_address_offset_amp => read_address_offset_amp(i),
    read_address_wave => read_address_wave(i),
    read_address_inc_factor => read_address_inc_factor(i),
--data in from local memory
    q_data_phase => q_data_phase(i),
    q_data_offset => q_data_offset(i),
    q_data_phase_amp => q_data_phase_amp(i),
    q_data_offset_amp => q_data_offset_amp(i),
    q_data_wave => q_data_wave(i),
    q_data_inc_factor => q_data_inc_factor(i),
--output stimulus
    master_counter => master_counter(i), 
    phase_length => phase_length(i),
    offset_length => offset_length(i),
    wave_type => wave_type(i),
    inc_step => inc_step(i),
    tsf_in =>tsf_in(i),
    cell_address_in => cell_address_in(i),
    data_in_internal_amp =>data_in_internal_amp(i),
    data_in_pulse_counter_cell => data_in_pulse_counter_cell(i), 
    data_in_local_counter_cell =>  data_in_local_counter_cell(i),
    data_in_phase_amp_cell => data_in_phase_amp_cell(i), 
    data_in_offset_amp_cell => data_in_offset_amp_cell(i),
    data_out_pulse_counter_cell => data_out_pulse_counter_cell(i),
    data_out_local_counter_cell => data_out_local_counter_cell(i),
    data_out_internal_amp_cell => data_out_internal_amp_cell(i),
    tsf_out => tsf_out(i),
    tsf_out_amp => tsf_out_amp(i)
   );
  end generate uut_fetcher ;
  
 ----------------------------------------------------------------------------------------------------------------------------------
uut_OUT_FIFO_IN:COMPONENT OUT_FIFO --COMPONENT OUT_FIFO acts as a FIFO read from Bridge controller and written by Scheduler
	-- its size is kept sufficiently large to accomodate data rate reduction from Bridge controller,
	-- in case of data loss increase the size of this FIFO through Generic parameter FIFO_size
 ----------------------------------------------------------------------------------------------------------------------------------
	Generic map (
			FIFO_size
	)
	Port MAP( 
		CLK	=> clock,
		RST	=> reset,
		DATA_WriteEn => we_out_scheduler,
		DataIn  => scheduler_DataOut,
		ADDRESSIn  => scheduler_ADDRESS_top,
		ReadEn => Read_En,
		DataOut	=> data_internal,
		tvalid	=> valid
	);

uut_DATA_FIFO: for i in 0 to PhyC-1 generate 
 ----------------------------------------------------------------------------------------------------------------------------------
uut_DATA_FIFO_IN:COMPONENT DATA_FIFO --COMPONENT DATA_FIFO stores Iamp values generated by Stimulus cell,
-- read  by Scheduler and written by Stimulus cell
 ----------------------------------------------------------------------------------------------------------------------------------
	Generic map (
			PhyC
	)
	Port MAP( 
		CLK	=> clock,
		RST	=> reset,
		DATA_WriteEn => stim_we(i),
		DataIn  => stim_data(i),
		ReadEn => DATA_FIFO_ReadEn(i),
		DataOut	=> DATA_FIFO_DataOut(i),
		Empty	=> DATA_FIFO_Empty(i),
		Full	=> DATA_FIFO_Full(i)
	);
	end generate uut_DATA_FIFO ;

uut_ADDRESS_FIFO: for i in 0 to PhyC-1 generate 
----------------------------------------------------------------------------------------------------------------------------------
uut_ADDRESS_FIFO_IN:COMPONENT ADDRESS_FIFO--COMPONENT ADDRESS_FIFO stores Cell address values generated by Stimulus cell,
-- read  by Scheduler and written by Stimulus cell
----------------------------------------------------------------------------------------------------------------------------------
	Generic map (
			PhyC
	)
	Port MAP( 
		CLK	=> clock,
		RST	=> reset,
		ADDRESS_WriteEn => stim_we(i),
		DataIn  => stim_address(i),
		ReadEn => ADDRESS_FIFO_ReadEn(i),
		DataOut	=> ADDRESS_FIFO_DataOut(i),
		Empty	=> ADDRESS_FIFO_Empty(i),
		Full	=> ADDRESS_FIFO_Full(i)
	);
	end generate uut_ADDRESS_FIFO ;
----------------------------------------------------------------------------------------------------------------------------------
uut_rr_scheduler_in: COMPONENT rr_scheduler --COMPONENT rr_scheduler is round robin scheduler which reads data from stimulus cells,
-- in roud robin order and writes data into ADDRESS_FIFO and DATA_FIFO
----------------------------------------------------------------------------------------------------------------------------------
	Generic map (
			PhyC, StimC
	)
	Port MAP ( 
		CLK => clock,		
		RST => reset,		
		valid => cell_ready_merged,	
		Data_In	=>DATA_FIFO_DataOut,	
		ADDRESS_In => ADDRESS_FIFO_DataOut,	
		DATA_FIFO_Empty	 => DATA_FIFO_Empty,
		ADDRESS_FIFO_Empty => ADDRESS_FIFO_Empty,
		Data_ReadEn => 	DATA_FIFO_ReadEn,
		ADDRESS_ReadEn => ADDRESS_FIFO_ReadEn,
		scheduler_DataOut => scheduler_DataOut,
		scheduler_ADDRESS_out =>scheduler_ADDRESS_out,
		we_out_scheduler => we_out_scheduler
	);
----------------------------------------------------------------------------------------------------------------------------------
uut_master_counter: COMPONENT master_counter_comp --COMPONENT master_counter_comp is master counter which counts clock pulses of
--50us clock after start and resets on stop
----------------------------------------------------------------------------------------------------------------------------------
    PORT MAP (
        reset => reset,
        clock_rt => clock_rt,
        cell_ready => cell_ready_merged,
        master_count => master_count
    );

uut_phase: for i in 0 to PhyC-1 generate 
----------------------------------------------------------------------------------------------------------------------------------
uut_phase_memoryi: COMPONENT phase_memory --COMPONENT phase_memory stores phase length values of each pulse for each cell,
-- written by Init_controller read by Fetcher 
----------------------------------------------------------------------------------------------------------------------------------
            GENERIC MAP(
            pulse_number, TSF
            )
            PORT MAP(
                clock => clock, 
                data => init_out_phase(i), 
                write_address => address_out_write, 
                read_address => read_address_phase(i), 
                we => we_phase(i), 
                q => q_data_phase(i)
            );
  end generate uut_phase;
  
uut_offset: for i in 0 to PhyC-1 generate 
----------------------------------------------------------------------------------------------------------------------------------
uut_offset_memoryi: COMPONENT offset_memory--COMPONENT offset_memory stores offset length values of each pulse for each cell,
-- written by Init_controller read by Fetcher 
----------------------------------------------------------------------------------------------------------------------------------
            GENERIC MAP(
            pulse_number, TSF
            )
            PORT MAP(
                clock => clock, 
                data => init_out_off(i), 
                write_address => address_out_write, 
                read_address => read_address_offset(i), 
                we => we_offset(i), 
                q => q_data_offset(i)
            );
  end generate uut_offset;
  
uut_wave:for i in 0 to PhyC-1 generate 
 ----------------------------------------------------------------------------------------------------------------------------------
uut_wave_memoryi:COMPONENT wave_typ_memory--COMPONENT wave_typ_memory stores wave type(pulse or ramp) values for each cell,
-- written by Init_controller read by Fetcher 
 ----------------------------------------------------------------------------------------------------------------------------------
            GENERIC MAP(
            pulse_number, TSF
            )
            PORT MAP(
                clock => clock, 
                data => init_out_w_typ(i), 
                write_address =>wave_typ_address, 
                read_address => read_address_wave(i), 
                we => we_wave_typ(i), 
                q => q_data_wave(i)
            );
  end generate uut_wave;
  
uut_phase_amp: for i in 0 to PhyC-1 generate 
 ----------------------------------------------------------------------------------------------------------------------------------
uut_phase_amplitudei:COMPONENT phase_amplitude--COMPONENT phase_amplitude stores phase amplitude values of each pulse for each cell,
-- written by Init_controller read by Fetcher 
 ----------------------------------------------------------------------------------------------------------------------------------
            GENERIC MAP(
            pulse_number, TSF
            )
            PORT MAP(
                clock => clock, 
                data => init_out_phase_amp(i), 
                write_address => address_out_write, 
                read_address => read_address_phase_amp(i), 
                we => we_phase_amp(i), 
                q => q_data_phase_amp(i)
            );
  end generate uut_phase_amp;
  
   uut_inc_factor: for i in 0 to PhyC-1 generate 
 ----------------------------------------------------------------------------------------------------------------------------------
uut_inc_factori: COMPONENT inc_factor--COMPONENT inc_factor stores increment factor values of each pulse for each cell,
-- written by Init_controller read by Fetcher (needed by ramp wave generator)
 ----------------------------------------------------------------------------------------------------------------------------------
             GENERIC MAP(
             pulse_number, TSF
             )
             PORT MAP(
                 clock => clock, 
                 data => init_out_inc_factor(i), 
                 write_address => address_out_write, 
                 read_address => read_address_inc_factor(i), 
                 we => we_inc_factor(i), 
                 q => q_data_inc_factor(i)
             );
   end generate uut_inc_factor;

uut_offset_amp: for i in 0 to PhyC-1 generate 
 ----------------------------------------------------------------------------------------------------------------------------------
uut_offset_amplitudei: COMPONENT offset_amplitude--COMPONENT inc_factor stores increment factor values of each pulse for each cell,
-- written by Init_controller read by Fetcher (needed by ramp wave generator)
 ----------------------------------------------------------------------------------------------------------------------------------
            GENERIC MAP(
            pulse_number, TSF
            )
            PORT MAP(
                clock => clock, 
                data => init_out_offset_amp(i), 
                write_address => address_out_write, 
                read_address => read_address_offset_amp(i), 
                we => we_offset_amp(i), 
                q => q_data_offset_amp(i)
            );
  end generate uut_offset_amp;

 ----------------------------------------------------------------------------------------------------------------------------------
uut_init_controller: COMPONENT init_controller--COMPONENT init_controller is initialization controller which receives data from user,
-- through input port and writes at required location in memory   
 ----------------------------------------------------------------------------------------------------------------------------------
        GENERIC MAP(
  		 pulse_number,pulse_number_bits, RTC, PhyC, TSF,StimC
, StimC_bits        )
        PORT MAP (
            reset	=> reset,
            clock => clock,
            init_str => init_str,
            init_in_typ => init_in_typ,
            cell_in_address => cell_in_address,
            pulse_in_address => pulse_in_address,
            init_in_data => init_in_data_top,
            init_ack => init_ack,
            we_phase => we_phase,
            we_offset => we_offset,
            we_phase_amp=>we_phase_amp,
            we_offset_amp=>we_offset_amp,
            we_wave_typ => we_wave_typ,
            we_inc_factor=> we_inc_factor,
            init_out_off => init_out_off,
            init_out_phase => init_out_phase,
            init_out_w_typ => init_out_w_typ,
            init_out_phase_amp => init_out_phase_amp,
            init_out_offset_amp=> init_out_offset_amp,
            init_out_inc_factor => init_out_inc_factor,
            wave_typ_address => wave_typ_address,
            address_out_write => address_out_write
        );

uut_stimulus_cell: for i in 0 to PhyC-1 generate 
 ----------------------------------------------------------------------------------------------------------------------------------
uut_stimulus_celli:COMPONENT stimulus_cell --COMPONENT stimulus_cell is a 5 stage pipeline component which generates the stimulus 
--at specified time with specific address, 4 stage pipeline floating point adder and one stage Data_checker(data reduction)
-- reads from featcher and writes into FIFO
-- total 6 stage pipeline for system, 1 for Fetcher 5 for Stimulus generator(latency 6)   
 ----------------------------------------------------------------------------------------------------------------------------------
     generic MAP( PhyC, TSF, pulse_number, pulse_number_bits
     		 	 )
 		   Port MAP(
 				 reset => reset,
 				 clock => clock,
				 cell_start => cell_ready(i),
 				 master_counter =>master_counter(i),
				 phase_length => phase_length(i),
				 offset_length => offset_length(i),
				 wave_type => wave_type(i),
				 tsf_in => tsf_in(i),
				 tsf_out => tsf_out(i),
				 tsf_out_amp => tsf_out_amp(i),
				 cell_address_in => cell_address_in(i),
				 data_in_internal_amp => data_in_internal_amp(i),
				 data_in_pulse_counter_cell =>data_in_pulse_counter_cell(i),
 				 data_out_pulse_counter_cell =>data_out_pulse_counter_cell(i),
				 data_in_local_counter_cell =>data_in_local_counter_cell(i),
 				 data_out_local_counter_cell =>data_out_local_counter_cell(i),
				 data_in_phase_amp_cell=> data_in_phase_amp_cell(i),
				 data_in_offset_amp_cell=> data_in_offset_amp_cell(i),
				 data_out_internal_amp_cell => data_out_internal_amp_cell(i),
 				 data => stim_data(i),
				 address => stim_address(i),
				 we => stim_we(i),
				 Float_adder_out => Float_adder_out(i)
   			 ); 
 end generate uut_stimulus_cell;
 
uut_FPadd: for i in 0 to PhyC-1 generate 
 ----------------------------------------------------------------------------------------------------------------------------------
uut_FPaddi: COMPONENT adder_sp_p1_wrapper --COMPONENT adder_sp_p1_wrapper is HLS generated sigle precition floating point adder
-- with 4 pipeline stages
 ----------------------------------------------------------------------------------------------------------------------------------
     PORT MAP(
                ap_clk => clock,
                ap_rst => reset,
                inA => inc_step(i),
                inB => data_in_internal_amp(i),
                out1 => Float_adder_out(i)
       );
    end generate uut_FPadd;
    
END rtl;
 

			