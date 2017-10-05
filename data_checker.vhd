----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: data_checker
-- Module Name: data_checker - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: data checker is signal variation detector that checks if generated data is new and sets valid
-- Dependencies: : No component Instantiation 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE work.StimG_Pkg.ALL;

entity data_checker is
 generic (
       TSF : INTEGER
     );
    Port (   
            reset  : IN  STD_LOGIC;
            clock     : IN STD_LOGIC;
            cell_start : IN std_logic;
            cell_address_in : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
            data_in_internal_amp : in STD_LOGIC_VECTOR (31 downto 0);
            tsf_in: IN INTEGER RANGE 0 TO (TSF)-1;
            data: out STD_LOGIC_VECTOR(31 downto 0);
            address : out STD_LOGIC_VECTOR (31 DOWNTO 0); 
            we: out std_logic
);
end data_checker;

architecture Behavioral of data_checker is
SIGNAL temp_array : std_logic_32_array(0 to TSF-1);
begin

 data_proc:process(clock,data_in_internal_amp,reset,tsf_in)
  begin
 if (reset = '0') then
 we<='0';
 else
 if rising_edge(clock)  then
 if cell_start = '1' and temp_array(tsf_in) /= data_in_internal_amp then
         data <= data_in_internal_amp;
         address<=cell_address_in;
         we<='1';
 else
      we<='0';
  end if;
 temp_array(tsf_in) <= data_in_internal_amp;
 end if;
 end if;
 end process data_proc;

end Behavioral;
