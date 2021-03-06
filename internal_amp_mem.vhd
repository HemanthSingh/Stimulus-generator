 ----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: internal_amp_mem
-- Module Name: internal_amp_mem - Behavioral
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

ENTITY internal_amp_mem IS
  generic ( TSF : Integer);
   PORT
   (
      clock: IN   std_logic;
      data:  IN    std_logic_vector(31 downto 0);
      write_address:  IN   integer RANGE 0 to (TSF)-1;
      read_address:   IN   integer RANGE 0 to (TSF)-1;
      we:    IN   std_logic;
      q:     OUT  STD_LOGIC_VECTOR (31 DOWNTO 0)
   );
END internal_amp_mem;
ARCHITECTURE rtl OF internal_amp_mem IS
   TYPE mem IS ARRAY(0 TO TSF-1) OF std_logic_vector(31 downto 0);
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
