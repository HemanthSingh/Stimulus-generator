 ----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: phase_amplitude
-- Module Name: phase_amplitude - Behavioral
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

ENTITY phase_amplitude IS
  generic (  pulse_number: Integer ;
	     TSF : Integer);
   PORT
   (
      clock: IN   std_logic;
      data:  IN    std_logic_vector(31 downto 0);
      write_address:  IN   integer RANGE 0 to (TSF*pulse_number)-1;
      read_address:   IN   integer RANGE 0 to (TSF*pulse_number)-1;
      we:    IN   std_logic;
      q:     OUT   std_logic_vector(31 downto 0)
   );
END phase_amplitude;
ARCHITECTURE rtl OF phase_amplitude IS
   TYPE mem IS ARRAY(0 TO (TSF*pulse_number)-1) OF std_logic_vector(31 downto 0);

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
