----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
--
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: address_decoder
-- Module Name: address_decoder - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: decodes address from cell_in_address and
-- pulse_in_address to required address location in memory
-- Dependencies: No component Instantiation 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY address_decoder IS
  generic (  pulse_number: Integer;
	     TSF : Integer);
   PORT
   (
      cell_in_address : IN INTEGER RANGE 0 TO TSF-1;
      pulse_in_address : IN INTEGER RANGE 0 TO pulse_number-1;
      address_out: OUT	integer RANGE 0 to (TSF*pulse_number)-1
   );
END address_decoder;
ARCHITECTURE rtl OF address_decoder IS
BEGIN
   address_out<=(cell_in_address*pulse_number)+pulse_in_address;
END rtl;
