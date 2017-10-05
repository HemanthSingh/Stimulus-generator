----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
--
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: init_controller
-- Module Name: init_controller - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: init_controller is initialization controller which receives data from user,
-- through input port and writes at required location in memory 
-- Dependencies: indexer and address_decoder
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.StimG_Pkg.ALL;

ENTITY init_controller IS
	GENERIC (
		pulse_number : INTEGER;
		pulse_number_bits : INTEGER;
		RTC : INTEGER; --in nano seconds
		PhyC : INTEGER;
		TSF : INTEGER; -- Time sharing factor
		StimC : INTEGER;
		StimC_bits : INTEGER
	);
	PORT (
		reset : IN STD_LOGIC;
		clock : IN STD_LOGIC;
		init_str : IN STD_LOGIC;
		init_in_typ : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		cell_in_address : IN STD_LOGIC_VECTOR(StimC_bits - 1 DOWNTO 0);
		pulse_in_address : IN STD_LOGIC_VECTOR(pulse_number_bits - 1 DOWNTO 0);
		init_in_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		init_ack : OUT STD_LOGIC;
		--write enable into local memory
		we_phase : OUT std_logic_array(0 TO PhyC - 1);
		we_offset : OUT std_logic_array(0 TO PhyC - 1);
		we_phase_amp : OUT std_logic_array(0 TO PhyC - 1);
		we_offset_amp : OUT std_logic_array(0 TO PhyC - 1);
		we_wave_typ : OUT std_logic_array(0 TO PhyC - 1);
		we_inc_factor : OUT std_logic_array(0 TO PhyC - 1);
		--write data for local memory
		init_out_off : OUT std_logic_32_array(0 TO PhyC - 1);
		init_out_phase : OUT std_logic_32_array(0 TO PhyC - 1);
		init_out_w_typ : OUT std_logic_array(0 TO PhyC - 1);
		init_out_phase_amp : OUT std_logic_32_array(0 TO PhyC - 1);
		init_out_offset_amp : OUT std_logic_32_array(0 TO PhyC - 1);
		init_out_inc_factor : OUT std_logic_32_array(0 TO PhyC - 1);
		--address decoder signals
		wave_typ_address : OUT INTEGER RANGE 0 TO TSF - 1;
		address_out_write : OUT INTEGER RANGE 0 TO (TSF * pulse_number) - 1
	);
END init_controller;
ARCHITECTURE rtl OF init_controller IS
	SIGNAL init_ack_s : STD_LOGIC := '0';
	SIGNAL read_address, write_address : INTEGER RANGE 0 TO (StimC - 1) * pulse_number;
	SIGNAL index : INTEGER RANGE 0 TO PhyC - 1;
	SIGNAL wave_typ_address_s : INTEGER RANGE 0 TO TSF - 1;
	SIGNAL pulse_in_address_s : INTEGER RANGE 0 TO pulse_number - 1;
	SIGNAL cell_in_address_s : INTEGER RANGE 0 TO StimC - 1;

BEGIN
	cell_in_address_s <= to_integer(unsigned(cell_in_address));
	wave_typ_address_s <= cell_in_address_s/PhyC;
	wave_typ_address <= wave_typ_address_s;
	init_ack <= init_ack_s;
	pulse_in_address_s <= to_integer(unsigned(pulse_in_address));
------------------------------------------------------------------------------------------------------------------------------------------------------
uut_indexer: COMPONENT indexer --COMPONENT indexer decodes the index location of memory by using cell_in_address
------------------------------------------------------------------------------------------------------------------------------------------------------
			GENERIC MAP(PhyC, StimC)
		PORT MAP(
			cell_in_address => cell_in_address_s, 
			index => index
		);
------------------------------------------------------------------------------------------------------------------------------------------------------
uut_address_decoder_write: COMPONENT address_decoder--COMPONENT address_decoder decodes address from cell_in_address and
-- pulse_in_address to required address location in memory
------------------------------------------------------------------------------------------------------------------------------------------------------
		      GENERIC MAP(
				pulse_number, TSF)
		PORT MAP(
				cell_in_address => wave_typ_address_s, 
				pulse_in_address => pulse_in_address_s, 
				address_out => address_out_write
		);
						PROCESS (clock, reset, index)
						VARIABLE init_in_typ_v : INTEGER RANGE 0 TO 7;
				BEGIN
					IF (reset = '0') THEN
 
						init_out_off(index) <= (OTHERS => '0');
						init_out_w_typ(index) <= '0';
						init_out_phase(index) <= (OTHERS => '0');
						init_out_phase_amp(index) <= (OTHERS => '0');
						init_out_offset_amp(index) <= (OTHERS => '0');
					ELSIF (clock'EVENT AND clock = '1') THEN
						IF (init_str = '1') THEN
							init_ack_s <= '1';
							init_in_typ_v := to_integer(unsigned(init_in_typ));
							CASE init_in_typ_v IS
								WHEN 0 => --phase amplitude
									init_out_phase_amp(index) <= init_in_data;
									we_phase_amp(index) <= '1';
								WHEN 1 => --offset amplitude
									init_out_offset_amp(index) <= init_in_data;
									we_offset_amp(index) <= '1';
 
								WHEN 2 => --phase
									init_out_phase(index) <= init_in_data;
									we_phase(index) <= '1';
								WHEN 3 => --offset
									init_out_off(index) <= init_in_data;
									we_offset(index) <= '1';
								WHEN 4 => --wave type
									IF (init_in_data = x"00000001") THEN 
										init_out_w_typ(index) <= '1';
									ELSE
										init_out_w_typ(index) <= '0';
									END IF;
									we_wave_typ(index) <= '1';
								WHEN 5 => --inc factor
									init_out_inc_factor(index) <= init_in_data;
									we_inc_factor(index) <= '1';
								WHEN OTHERS => 
									we_phase(index) <= '0';
									we_offset(index) <= '0';
									we_wave_typ(index) <= '0';
									we_phase_amp(index) <= '0';
									we_inc_factor(index) <= '0';
									we_offset_amp(index) <= '0';
							END CASE;
						END IF;
						IF (init_ack_s = '1') THEN
							init_ack_s <= '0';
							we_phase(index) <= '0';
							we_offset(index) <= '0';
							we_wave_typ(index) <= '0';
							we_phase_amp(index) <= '0';
							we_inc_factor(index) <= '0';
							we_offset_amp(index) <= '0';
						END IF;
					END IF;
				END PROCESS;
END rtl;