----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: indexer
-- Module Name: indexer - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: indexer decodes the index location of memory by using cell_in_address
-- which gives turn to each Physical cell one after the other
-- Dependencies: No component Instantiation 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY indexer IS
  generic (  PhyC: Integer;
	     StimC : Integer);
   PORT
   (
      cell_in_address:  IN INTEGER RANGE 0 TO StimC - 1;
      index:     OUT INTEGER RANGE 0 TO PhyC - 1
   );
END indexer;
ARCHITECTURE rtl OF indexer IS
BEGIN
   index <= cell_in_address mod PhyC;
END rtl;
