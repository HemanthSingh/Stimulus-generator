----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: clk_divider
-- Module Name: clk_divider - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: Clock divider with generic parameter Clock_div which defines Fin/Fout factor or division factor
-- Fin is input frequency 
-- Fout is 20kHz(50us) in our case 
-- Dependencies: No component Instantiation 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: This code is copied and edited from:
-- https://www.codeproject.com/Tips/444385/Frequency-Divider-with-VHDL
--website makes this code openly available and avails for open use with or without editing
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_divider is
GENERIC (
		Clock_div : INTEGER
	);
    Port (
        clk_in : in  STD_LOGIC;
        reset  : in  STD_LOGIC;
        cell_ready : IN std_logic;
        clk_out: out STD_LOGIC
    );
end clk_divider;

architecture Behavioral of clk_divider is
    signal temporal: STD_LOGIC;
    signal counter : integer range 0 to Clock_div := 0;
begin
    frequency_divider: process (reset, clk_in) begin
        if (reset = '0') then
            temporal <= '0';
            counter <= 0;
        elsif rising_edge(clk_in) then
           if cell_ready = '1' then
            if (counter = (Clock_div)-1) then
                temporal <= NOT(temporal);
                counter <= 0;
            else
                counter <= counter + 1;
            end if;
           end if;
        end if;
    end process;
    
    clk_out <= temporal;
end Behavioral;
