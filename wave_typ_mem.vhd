 ----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: wave_typ_memory
-- Module Name: wave_typ_memory - Behavioral
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
ENTITY wave_typ_memory IS
  generic (  pulse_number: Integer;
	     TSF : Integer );
   PORT
   (
      clock: IN   std_logic;
      data:  IN   std_logic;
      write_address:  IN   integer RANGE 0 to TSF-1;
      read_address:   IN   integer RANGE 0 to TSF-1;
      we:    IN   std_logic;
      q:     OUT  std_logic
   );
END wave_typ_memory;
ARCHITECTURE rtl OF wave_typ_memory IS
   TYPE mem IS ARRAY(0 TO TSF-1) OF std_logic;
   SIGNAL ram_block : mem;
BEGIN

   PROCESS (clock)
   BEGIN
      IF (clock'event AND clock = '1') THEN
         IF (we = '1') THEN
            ram_block(write_address) <= data;
         END IF;
         q <= ram_block(read_address);
      END IF;
   END PROCESS;
END rtl;
