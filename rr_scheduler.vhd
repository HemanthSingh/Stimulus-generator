----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: rr_scheduler
-- Module Name: rr_scheduler - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: rr_scheduler is round robin scheduler which reads data from stimulus cells,
-- in roud robin order and writes data into ADDRESS_FIFO and DATA_FIFO
-- Dependencies: rrarbiter 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE work.StimG_Pkg.ALL;

entity rr_scheduler is
	Generic (
			PhyC: Integer;
			StimC : INTEGER 
	);
	Port ( 
		CLK		: in  STD_LOGIC;
		RST		: in  STD_LOGIC;
		valid 		: in  STD_LOGIC;
		Data_In		: in std_logic_32_array(0 to PhyC-1);
		ADDRESS_In	: in  std_logic_32_array(0 to PhyC-1);
		DATA_FIFO_Empty	: in  std_logic_array(0 to PhyC-1);
		ADDRESS_FIFO_Empty: in  std_logic_array(0 to PhyC-1);
		Data_ReadEn	: out  std_logic_array(0 to PhyC-1);
		ADDRESS_ReadEn	: out  std_logic_array(0 to PhyC-1);
		scheduler_DataOut: out STD_LOGIC_VECTOR(31 downto 0);
		scheduler_ADDRESS_out: out STD_LOGIC_VECTOR(31 downto 0);
		we_out_scheduler     : out STD_LOGIC
	);

end rr_scheduler;

architecture Behavioral of rr_scheduler is

Signal grant, grant_buffer, grant_buffer_buffer : INTEGER RANGE 0 TO PhyC-1;
signal check: bool_array(0 to PhyC-1);
signal delay: bool_array(0 to PhyC-1);
signal	we_out_scheduler_s    : STD_LOGIC;
begin
we_out_scheduler<=we_out_scheduler_s;
	process (CLK,RST)
	begin
		if RST = '0' then
			scheduler_DataOut<= (OTHERS => '0');
			scheduler_ADDRESS_out<= (OTHERS => '0');

			for i in 0 to PhyC-1 loop
				ADDRESS_ReadEn(i) <= '0';
				Data_ReadEn(i) <= '0';
				check(i) <= FALSE;	
				delay(i) <= false;
			end loop;
		elsif rising_edge(CLK) then
			
				if (valid = '1' and DATA_FIFO_Empty(grant) /='1' and ADDRESS_FIFO_Empty(grant) /='1') then
					Data_ReadEn(grant) <='1';
					ADDRESS_ReadEn(grant) <='1';
					check(grant) <= true;	
				end if;
				if (check(grant_buffer) = true) then
					check(grant_buffer)<= FALSE;
					delay(grant_buffer) <= true;
					Data_ReadEn(grant_buffer) <='0';
					ADDRESS_ReadEn(grant_buffer) <='0';
					
				end if;
				if delay(grant_buffer_buffer)= true then
					delay(grant_buffer_buffer) <= false;
					scheduler_DataOut <= Data_In(grant_buffer_buffer);
					scheduler_ADDRESS_out <= ADDRESS_In(grant_buffer_buffer);
					we_out_scheduler_s <= '1'; 
				else 
					we_out_scheduler_s <= '0'; 
				end if;
		end if;
	end process;

-------------------------------------------------------------------------------------------------------------------------------------------------
uut_rrarbiter: COMPONENT rrarbiter --COMPONENT rrarbiter is a mod PhyC-1 counter which gives turn to each Physical cell one after the other
-------------------------------------------------------------------------------------------------------------------------------------------------
		generic map( PhyC, StimC)
			port map (
				clk  => CLK,
				rst_n => RST,
				valid  => valid,
				grant => grant,
				grant_buffer => grant_buffer,
				grant_buffer_buffer => grant_buffer_buffer
			);
		
end Behavioral;
