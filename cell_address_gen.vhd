----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
--
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: cell_address_gen
-- Module Name: cell_address_gen - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description:cell_address_gen generates the address of stimulus cell that 
--each fether has to work on based on tsf_in and coc_number(cell on chip index identifier)
-- Dependencies: No component Instantiation 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY cell_address_gen IS
  generic (  PhyC : INTEGER;
	     TSF : INTEGER
		);
   PORT
   (
     tsf_in : IN INTEGER RANGE 0 TO TSF-1;
     coc_in : IN INTEGER RANGE 0 TO PhyC-1;
     cell_address: out   INTEGER
   );
END cell_address_gen;
ARCHITECTURE rtl OF cell_address_gen IS
BEGIN
   cell_address<= (tsf_in* PhyC)+coc_in;
END rtl;
