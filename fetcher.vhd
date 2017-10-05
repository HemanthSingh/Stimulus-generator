----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
--
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: fetcher
-- Module Name: fetcher - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description:This module reads data from memory(Synchronous read/write BRAM) and Fetches it to Stimulus cell
--marking the frist stage of pipeline in the system
-- Dependencies: address_decoder, cell_address_gen, tsf_counter, pulse_counter_mem, local_counter_mem
-- and internal_amp_mem
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.StimG_Pkg.ALL;

ENTITY fetcher IS
	GENERIC (
		PhyC : INTEGER;
		pulse_number : INTEGER;
		pulse_number_bits : INTEGER;
		TSF : INTEGER := 5
	);
	PORT (
		reset : IN STD_LOGIC;
		clock : IN std_logic;
		start : IN std_logic;
		cell_ready : OUT std_logic;
		master_count : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		coc_number : IN INTEGER RANGE 0 TO (PhyC) - 1;-- cell on chip id number
		--read from local memory
		read_address_phase : OUT INTEGER RANGE 0 TO(TSF * pulse_number) - 1;
		read_address_offset : OUT INTEGER RANGE 0 TO(TSF * pulse_number) - 1;
		read_address_phase_amp : OUT INTEGER RANGE 0 TO(TSF * pulse_number) - 1;
		read_address_offset_amp : OUT INTEGER RANGE 0 TO(TSF * pulse_number) - 1;
		read_address_wave : OUT INTEGER RANGE 0 TO(TSF) - 1;
		read_address_inc_factor : OUT INTEGER RANGE 0 TO(TSF * pulse_number) - 1;
		--data in from local memory
		q_data_phase : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		q_data_offset : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		q_data_phase_amp : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		q_data_offset_amp : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		q_data_wave : IN STD_LOGIC;
		q_data_inc_factor : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		--output stimulus
		master_counter : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		phase_length : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		offset_length : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		wave_type : OUT STD_LOGIC;
		inc_step : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		tsf_in : OUT INTEGER RANGE 0 TO (TSF) - 1;
		cell_address_in : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		data_in_internal_amp : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		data_in_pulse_counter_cell : OUT STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
		data_in_local_counter_cell : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		data_in_phase_amp_cell : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		data_in_offset_amp_cell : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
		--input stimulus
		data_out_pulse_counter_cell : IN STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
		data_out_local_counter_cell : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		data_out_internal_amp_cell : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		tsf_out : IN INTEGER RANGE 0 TO (TSF) - 1;
		tsf_out_amp : IN INTEGER RANGE 0 TO (TSF) - 1 
	);
END fetcher;
ARCHITECTURE rtl OF fetcher IS
	-------------------------------------------------init signals -----------------------------------------------------------------------
	--write enable into context
	SIGNAL q_data_phase_s : INTEGER;
	SIGNAL q_data_offset_s : INTEGER;
	SIGNAL we_pulse_counter_init : std_logic;
	SIGNAL we_local_counter_init : std_logic;
	SIGNAL we_internal_amp_init : std_logic;
	--write address for context memory
	SIGNAL write_address_pulse_counter_init : INTEGER RANGE 0 TO(TSF) - 1;
	SIGNAL write_address_local_counter_init : INTEGER RANGE 0 TO(TSF) - 1;
	SIGNAL write_address_internal_amp_init : INTEGER RANGE 0 TO(TSF) - 1;
	--write data for context memory
	SIGNAL data_out_pulse_counter_init : STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
	SIGNAL data_out_local_counter_init : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL data_out_internal_amp_init : STD_LOGIC_VECTOR (31 DOWNTO 0); 
	--extra signal
	SIGNAL cell_ready_s, q_data_wave_s : std_logic;
	SIGNAL address_out_read : INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
	----------------------------------------stimulus generator signals------------------------------------------------------------------
	SIGNAL amplitude : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL cell_address, cell_address_buffer, cell_address_s : INTEGER;
	--write address for context memory cell
	SIGNAL write_address_internal_amp_cell : INTEGER RANGE 0 TO(TSF) - 1;
	--write data for context memory
	SIGNAL data : STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');
	--write enable into context
	SIGNAL we_pulse_counter_cell : std_logic;
	SIGNAL we_local_counter_cell : std_logic;
	SIGNAL we_internal_amp_cell : std_logic;
	------------------------------------------global signals----------------------------------------------------------------
	--write address for context memory cell
	SIGNAL write_address_pulse_counter : INTEGER RANGE 0 TO(TSF) - 1;
	SIGNAL write_address_internal_amp : INTEGER RANGE 0 TO(TSF) - 1;
	SIGNAL write_address_local_counter : INTEGER RANGE 0 TO (TSF) - 1;
	--write data for context memory
	SIGNAL data_out_pulse_counter : INTEGER;
	SIGNAL data_out_pulse_counter_s : STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
	SIGNAL data_out_local_counter : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL data_out_internal_amp : std_logic_vector(31 DOWNTO 0);
	--write enable into context
	SIGNAL we_pulse_counter : std_logic;
	SIGNAL we_internal_amp : std_logic;
	--read from context memory
	SIGNAL read_pulse_counter : INTEGER RANGE 0 TO(TSF) - 1;
	SIGNAL read_local_counter : INTEGER RANGE 0 TO (TSF) - 1;
	SIGNAL read_internal_amp : INTEGER RANGE 0 TO(TSF) - 1;
	--data in from context memory
	SIGNAL q_pulse_counter : STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
	SIGNAL q_pulse_counter_s : INTEGER RANGE 0 TO pulse_number - 1;
	SIGNAL q_local_counter : STD_LOGIC_VECTOR (31 DOWNTO 0);
	SIGNAL q_internal_amp, q_internal_amp_s, q_data_phase_amp_s, q_data_offset_amp_s : STD_LOGIC_VECTOR (31 DOWNTO 0);
	--done signal
	SIGNAL we : std_logic;
	SIGNAL tsf_in_s, tsf_in_buffer : INTEGER RANGE 0 TO TSF - 1;
	SIGNAL address : INTEGER;
	SIGNAL tsf_count : INTEGER RANGE 0 TO (TSF) - 1; 
	SIGNAL init_counter : INTEGER RANGE 0 TO TSF;
	SIGNAL tsf_out_pulse : INTEGER RANGE 0 TO TSF - 1;
	SIGNAL cell_address_out_pulse : INTEGER;

BEGIN
	read_internal_amp <= tsf_count;-- read internal amp through decoded address into q_internal_amp
	read_address_wave <= tsf_count;-- read wave type through mod tsf counter
	read_pulse_counter <= tsf_count; -- get pulse number from context memory into q_pulse_counter
	read_local_counter <= tsf_count;
	read_address_phase <= address_out_read; --read phase memory through decoded address
	read_address_offset <= address_out_read; --read phase memory through decoded address
	read_address_phase_amp <= address_out_read; -- read phase amp through decoded address into q_data_phase_amp
	read_address_offset_amp <= address_out_read;-- read offset amp through decoded address into q_data_offset_amp
	read_address_inc_factor <= address_out_read; -- read phase amp through decoded address into q_data_inc_factor
	we_pulse_counter_cell <= '1';-- cell can always write in its turn
	we_local_counter_cell <= '1';-- cell can always write in its turn
	we_internal_amp_cell <= '1';-- cell can always write in its turn
	q_pulse_counter_s <= to_integer(unsigned(q_pulse_counter));

	----------------------------------------------------------------------------------------------------------------------------------
	-----------------------select between init or cell depending on cell_ready signal-------------------------------------------------
	data_out_pulse_counter <= to_integer(unsigned(data_out_pulse_counter_cell)) WHEN (cell_ready_s = '1' AND to_integer(unsigned(data_out_pulse_counter_cell)) < pulse_number) ELSE
	                          pulse_number - 1 WHEN (to_integer(unsigned(data_out_pulse_counter_cell)) = pulse_number) ELSE to_integer(unsigned(data_out_pulse_counter_init));
	                          --In order to prevent accesing more than pulse_number -1
	data_out_pulse_counter_s <= STD_LOGIC_VECTOR(to_unsigned(data_out_pulse_counter, data_in_pulse_counter_cell'length));
	data_out_local_counter <= data_out_local_counter_cell WHEN cell_ready_s = '1' ELSE
	                          data_out_local_counter_init;
	data_out_internal_amp <= data_out_internal_amp_cell WHEN cell_ready_s = '1' ELSE
	                         data_out_internal_amp_init;
	we_pulse_counter <= we_pulse_counter_cell WHEN cell_ready_s = '1' ELSE
	                    we_pulse_counter_init;
	we_internal_amp <= we_internal_amp_cell WHEN cell_ready_s = '1' ELSE
	                   we_internal_amp_init;
	write_address_pulse_counter <= (tsf_out) WHEN cell_ready_s = '1' ELSE -- write at cell out address
	                               write_address_pulse_counter_init;
	write_address_local_counter <= tsf_out WHEN cell_ready_s = '1' ELSE
	                               write_address_local_counter_init;
	write_address_internal_amp <= (tsf_out_amp) WHEN cell_ready_s = '1' ELSE -- write at cell out address
	                              write_address_internal_amp_init;
-----------------------------------------------------------------------------------------------------------------------------------
uut_address_decoder_read: COMPONENT address_decoder --COMPONENT address_decoder decodes address from cell_in_address and
-- pulse_in_address to required address location in memory
-----------------------------------------------------------------------------------------------------------------------------------
			GENERIC MAP(
			pulse_number, TSF
			)
			PORT MAP(
				cell_in_address => tsf_count, --mod tsf counter counting round
				pulse_in_address => q_pulse_counter_s, --pulse in address for decoding through context memory
				address_out => address_out_read--decoded address for pulse and offset address
			); 
-----------------------------------------------------------------------------------------------------------------------------------
uut_cell_address_gen: COMPONENT cell_address_gen--COMPONENT cell_address_gen generates the address of stimulus cell that 
--each fether has to work on based on tsf_in and coc_number(cell on chip index identifier)
-----------------------------------------------------------------------------------------------------------------------------------
 		 generic MAP (  
			PhyC, TSF
			)
   		PORT MAP(
     			 tsf_in =>tsf_count, 
      			 coc_in =>coc_number,
      			 cell_address=>cell_address
   		);

----------------------------------------------------------------------------------------------------------------------------------
uut_tsf_counter: COMPONENT tsf_counter--COMPONENT tsf_counter is Time sharing factor counter that is a MOD TSF counter
----------------------------------------------------------------------------------------------------------------------------------
    GENERIC MAP (
        TSF
    )
    PORT MAP (
        reset => reset,
        clock => clock,
        cell_ready => cell_ready_s,
        tsf_count => tsf_count
    );

-----------------------------------------------------------------------------------------------------------------------------------
uut_pulse_counter: COMPONENT pulse_counter_mem--COMPONENT pulse_counter_mem stores pulse number of context to work on,
-- written by stimulus cell read by Fetcher
-----------------------------------------------------------------------------------------------------------------------------------
			GENERIC MAP(
			pulse_number_bits, TSF, PhyC 
			)
			PORT MAP(
				clock => clock, 
				data => data_out_pulse_counter_s, 
				write_address => write_address_pulse_counter, 
				read_address => read_pulse_counter, 
				we =>we_pulse_counter, 
				q => q_pulse_counter,
				tsf_out_pulse => tsf_out_pulse,
				cell_address_in_pulse => cell_address,
				cell_address_out_pulse => cell_address_out_pulse
			);
-----------------------------------------------------------------------------------------------------------------------------------
uut_local_counter_mem: COMPONENT local_counter_mem--COMPONENT local_counter_mem stores local counter value which is intern master counters value that each 
--cellin current context is working on,
-- written by stimulus cell read by Fetcher
-----------------------------------------------------------------------------------------------------------------------------------
			GENERIC MAP(
			pulse_number, TSF
			)
			PORT MAP(
				clock => clock, 
				data => data_out_local_counter, 
				write_address => write_address_local_counter, 
				read_address => read_local_counter, 
				we =>we_local_counter_cell, 
				q => q_local_counter
			);

-----------------------------------------------------------------------------------------------------------------------------------
uut_internal_amp_mem: COMPONENT internal_amp_mem--COMPONENT internal_amp_mem stores internal amplitude value that each 
--cell in current context is working on,
-- written by stimulus cell read by Fetcher
-----------------------------------------------------------------------------------------------------------------------------------
			GENERIC MAP(
			TSF
			)
			PORT MAP(
				clock => clock, 
				data => data_out_internal_amp, 
				write_address => write_address_internal_amp, 
				read_address => read_internal_amp, 
				we =>we_internal_amp, 
				q => q_internal_amp 
			);

-----------------------------------------------------------------------------------------------------------------------------------
            PROCESS (clock, start, reset)--process to clear context memory before generating cell_ready
-----------------------------------------------------------------------------------------------------------------------------------
            BEGIN
                IF (clock'EVENT AND clock = '1') THEN
                    IF (reset = '0') THEN
                        init_counter <= 0;
                        cell_ready_s <= '0';
                    ELSE
                        IF start = '1' THEN
                            IF cell_ready_s = '0' THEN
                                we_pulse_counter_init <= '1';
                                we_internal_amp_init <= '1';
                                we_local_counter_init <= '1';
                                write_address_pulse_counter_init <= init_counter;
                                write_address_local_counter_init <= init_counter;
                                write_address_internal_amp_init <= init_counter;
                                data_out_internal_amp_init <= (OTHERS => '0');
                                data_out_pulse_counter_init <= (OTHERS => '0');
                                data_out_local_counter_init <= (OTHERS => '1');
                                IF init_counter = TSF THEN
                                    cell_ready_s <= '1';
                                    init_counter <= 0;
                                ELSE
                                    init_counter <= init_counter + 1;
                                    cell_ready_s <= '0';
                                END IF;
                            ELSE
                                we_pulse_counter_init <= '0';
                                we_local_counter_init <= '0';
                                we_internal_amp_init <= '0';
                            END IF;
                        ELSE
                            cell_ready_s <= '0'; -- added to take into account stop
                        END IF;
                    END IF;
                END IF;
             
            END PROCESS;
            
-----------------------------------------------------------------------------------------------------------------------------------
            PROCESS (clock, cell_ready_s, reset)--output process
-----------------------------------------------------------------------------------------------------------------------------------
            BEGIN
                IF (clock'EVENT AND clock = '1') THEN
                    IF (reset = '0') THEN
                        cell_ready <= '0';
                    ELSE
                        IF cell_ready_s = '1' THEN
                            cell_ready <= '1';
                            master_counter <= master_count;
                            phase_length <= q_data_phase;
                            offset_length <= q_data_offset;
                            wave_type <= q_data_wave;
                            inc_step <= q_data_inc_factor;
                            tsf_in <= tsf_out_pulse;
                            cell_address_in <= STD_LOGIC_VECTOR(to_unsigned(cell_address_out_pulse, 32));
                            data_in_internal_amp <= q_internal_amp;
                            data_in_pulse_counter_cell <= q_pulse_counter;
                            data_in_local_counter_cell <= q_local_counter;
                            data_in_phase_amp_cell <= q_data_phase_amp;
                            data_in_offset_amp_cell <= q_data_offset_amp;
                        ELSE
                            cell_ready <= '0';
                        END IF;
                    END IF;
                END IF;
            END PROCESS;
END rtl;   
