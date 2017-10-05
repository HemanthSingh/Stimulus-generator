 ----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: pulse_counter_mem
-- Module Name: pulse_counter_mem - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: 2015.4
-- Description: A parameterized, inferable block RAM in VHDL.
-- Dependencies: No component Instantiation 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- This code is copied and edited from:
--http://vhdlguru.blogspot.nl/2011/01/block-and-distributed-rams-on-xilinx.html
--website makes this code openly available and avails for open use with or without editing
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.StimG_Pkg.ALL;

ENTITY pulse_counter_mem IS
  generic (  pulse_number_bits: Integer;
	     TSF : Integer; 	    
	     PhyC : INTEGER:=5 );
   PORT
   (
      clock: IN   std_logic;
      data:  IN   STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
      write_address:  IN   integer RANGE 0 to TSF-1;
      read_address:   IN   integer RANGE 0 to TSF-1;
      we:    IN   std_logic;
      q:     OUT  STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
      tsf_out_pulse : OUT INTEGER RANGE 0 TO TSF-1;
      cell_address_in_pulse : IN integer;
      cell_address_out_pulse : OUT integer
   );
END pulse_counter_mem;
ARCHITECTURE rtl OF pulse_counter_mem IS
   TYPE mem IS ARRAY(0 TO TSF-1) OF STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
   SIGNAL ram_block : mem;
BEGIN

   PROCESS (clock)
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (we = '1') THEN
            ram_block(write_address) <= data;
         END IF;
	   q <= ram_block(read_address);
	   tsf_out_pulse <= read_address;
	   cell_address_out_pulse <= cell_address_in_pulse;
      END IF;
   END PROCESS;

END rtl;
