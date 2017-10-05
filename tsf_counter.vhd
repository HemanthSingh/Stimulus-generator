----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
--
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: tsf_counter
-- Module Name: tsf_counter - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description:tsf_counter is Time sharing factor counter that is a MOD TSF counter
-- Dependencies: No component Instantiation 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY tsf_counter IS
	GENERIC (
		TSF : INTEGER
	);
	PORT (
		reset : IN std_logic;
		clock : IN std_logic;
		cell_ready : IN std_logic;
		tsf_count : OUT INTEGER RANGE 0 TO TSF - 1
	);
END tsf_counter;
ARCHITECTURE rtl OF tsf_counter IS
	SIGNAL counter : INTEGER RANGE 0 TO TSF - 1;
BEGIN
	tsf_count<=counter;
	PROCESS (clock,reset)
	BEGIN
		IF reset = '0' THEN
			counter <= 0;
		ELSIF (clock'EVENT AND clock = '1') THEN
			IF (cell_ready = '1') THEN
				IF counter = (TSF) - 1 THEN
					counter <= 0;
				ELSE
					counter <= counter + 1;
				END IF;
			ELSE
				counter <= 0;
			END IF;
		END IF;

	END PROCESS;
END rtl;
