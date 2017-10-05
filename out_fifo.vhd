----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: OUT_FIFO
-- Module Name: OUT_FIFO - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: OUT_FIFO acts as a FIFO read from Bridge controller and written by Scheduler
-- its size is kept sufficiently large to accomodate data rate reduction due to Bridge controller,
-- in case of data loss increase the size of this FIFO through Generic parameter FIFO_size
-- Dependencies: No component Instantiation 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

entity OUT_FIFO is
	Generic (
			StimC: Integer
	);
	Port ( 
		CLK		: in  STD_LOGIC;
		RST		: in  STD_LOGIC;
		DATA_WriteEn	: in  STD_LOGIC;
		DataIn	: in  STD_LOGIC_VECTOR(31 DOWNTO 0);
		ADDRESSIn: in  STD_LOGIC_VECTOR(31 DOWNTO 0); 
		ReadEn	: in  STD_LOGIC;
		DataOut	: out STD_LOGIC_VECTOR(63 DOWNTO 0);
		tvalid  : out STD_LOGIC
	);
end OUT_FIFO;

architecture Behavioral of OUT_FIFO is
signal		Empty	: STD_LOGIC;
signal		Full	: STD_LOGIC;
signal 		merged : STD_LOGIC_VECTOR(63 DOWNTO 0);
begin
	merged <= DataIn & ADDRESSIn;
	-- Memory Pointer Process
	fifo_proc : process (CLK)
		type FIFO_Memory is array (0 to StimC+1) of STD_LOGIC_VECTOR(63 DOWNTO 0);
		variable Memory : FIFO_Memory;
		
		variable Head : natural range 0 to StimC+1;
		variable Tail : natural range 0 to StimC+1;
		
		variable Looped : boolean;
	begin
		if rising_edge(CLK) then
			if RST = '0' then
				Head := 0;
				Tail := 0;
				
				Looped := false;
				
				Full  <= '0';
				Empty <= '1';
				tvalid<= '0';
			else
				if (ReadEn = '1') then
					if ((Looped = true) or (Head /= Tail)) then
						-- Update data output
						DataOut <= Memory(Tail);
						
						-- Update Tail pointer as needed
						if (Tail = StimC+1) then
							Tail := 0;
							
							Looped := false;
						else
							Tail := Tail + 1;
						end if;
						
						
					end if;
				end if;
				
				if (DATA_WriteEn = '1') then
					if ((Looped = false) or (Head /= Tail)) then
						-- Write Data to Memory
						Memory(Head) := merged;
						
						-- Increment Head pointer as needed
						if (Head = StimC+1  ) then
							Head := 0;
							
							Looped := true;
						else
							Head := Head + 1;
						end if;
					end if;
				end if;
				
				-- Update Empty and Full flags
				if (Head = Tail) then
					if Looped then
						Full <= '1';
					else
						Empty <= '1';
						tvalid<= '0';
					end if;
				else
					Empty	<= '0';
					tvalid<= '1';
					Full	<= '0';
				end if;
			end if;
		end if;
	end process;
		
end Behavioral;
