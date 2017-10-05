----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: master_counter_comp
-- Module Name: master_counter_comp - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: master_counter_comp is master counter which counts clock pulses of
--50us clock after start and resets on stop
-- Dependencies: No component Instantiation 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY master_counter_comp IS
    PORT (
        reset : IN std_logic;
        clock_rt : IN std_logic;
        cell_ready : IN std_logic;
        master_count : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
    );
END master_counter_comp;
ARCHITECTURE rtl OF master_counter_comp IS
     SIGNAL counter : INTEGER;
    SIGNAL master_count_s : INTEGER;
BEGIN

 
PROCESS (clock_rt,reset)
    BEGIN
        IF reset = '0' THEN
               counter <= 0;
               master_count_s<= 0;
        elsIF (clock_rt'EVENT AND clock_rt = '1') THEN
            master_count<=STD_LOGIC_VECTOR(to_unsigned(counter,32));
                if cell_ready = '1' then
                    if counter < INTEGER'High then
                        counter <= counter + 1;
                    else
                        counter <= 0;
                    END IF;
                else
                    counter <= 0;
                end if;
         end if;
    END PROCESS;

--PROCESS (cell_ready,master_count_s)
--    BEGIN
--        IF cell_ready = '1' THEN
--            master_count <= STD_LOGIC_VECTOR(to_unsigned(master_count_s,32));
--        end if;
--    END PROCESS;

END rtl;
