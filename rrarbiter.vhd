----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: rrarbiter
-- Module Name: rrarbiter - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: -- rrarbiter is a mod PhyC-1 counter
-- which gives turn to each Physical cell one after the other
-- Dependencies: No component Instantiation 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rrarbiter is
	generic ( PhyC : integer;
		StimC : INTEGER  );
	port (
		clk   : in    std_logic;
		rst_n : in    std_logic;
		valid   : in    std_logic;
		grant : out   INTEGER RANGE 0 TO PhyC-1;
		grant_buffer :  out INTEGER RANGE 0 TO PhyC-1;
		grant_buffer_buffer :  out INTEGER RANGE 0 TO PhyC-1
	);
end rrarbiter;

architecture Behavioral of rrarbiter is
	signal counter  : INTEGER RANGE 0 TO PhyC-1;
	signal grant_buffer_s :  INTEGER RANGE 0 TO PhyC-1;
	signal	grant_buffer_buffer_s :   INTEGER RANGE 0 TO PhyC-1;
begin
	grant<= counter;
	grant_buffer<= grant_buffer_s;
	grant_buffer_buffer <= grant_buffer_buffer_s;
	process (clk, rst_n)
	begin
	if rst_n = '0' then
		counter <= 0;
	elsif rising_edge(clk) then
		 grant_buffer_s <= counter;
		 grant_buffer_buffer_s <= grant_buffer_s;
		if valid ='1' and  counter < PhyC-1 then
			counter <= counter+1;
		else
			counter <= 0;
		end if;	
	end if;
	end process;

end Behavioral;

