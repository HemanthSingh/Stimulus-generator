----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: stimulus_cell
-- Module Name: stimulus_cell - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: stimulus_cell is a 5 stage pipeline component which generates the stimulus 
--at specified time with specific address, 4 stage pipeline floating point adder and one stage Data_checker(data reduction)
-- reads from featcher and writes into FIFO
-- total 6 stage pipeline for system, 1 for Fetcher 5 for Stimulus generator(latency 6)   
-- Dependencies: data_checker
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
USE work.StimG_Pkg.ALL;


entity stimulus_cell is
   		 generic (
        PhyC : INTEGER;
        TSF : INTEGER;
        pulse_number: Integer;
        pulse_number_bits: Integer
      );
    Port (
         reset  : IN  STD_LOGIC;
         clock     : IN STD_LOGIC;
         cell_start : IN std_logic;
         master_counter : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         phase_length: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         offset_length: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         wave_type: IN STD_LOGIC;
         tsf_in: IN INTEGER RANGE 0 TO (TSF)-1;
         tsf_out: OUT INTEGER RANGE 0 TO (TSF)-1;
         tsf_out_amp: OUT INTEGER RANGE 0 TO (TSF)-1;
         cell_address_in : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         data_in_internal_amp : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         data_in_pulse_counter_cell : IN STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
         data_out_pulse_counter_cell : OUT STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
         data_in_local_counter_cell : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         data_out_local_counter_cell : out STD_LOGIC_VECTOR (31 DOWNTO 0); 
         data_in_phase_amp_cell : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         data_in_offset_amp_cell : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
         data_out_internal_amp_cell: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
         data: out STD_LOGIC_VECTOR(31 downto 0);
         address : out STD_LOGIC_VECTOR (31 DOWNTO 0); 
         we: out std_logic;
         Float_adder_out : IN STD_LOGIC_VECTOR ( 31 downto 0 )
        );
end stimulus_cell;

architecture Behavioral of stimulus_cell is
SIGNAL state_cell, pipeline_en, pipeline_en_p1, pipeline_en_p2, wave_type_s: std_logic;
SIGNAL address_buffer:integer RANGE 0 to (TSF*PhyC)-1;
SIGNAL data_buffer, data_in_offset_amp_cell_s:STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL cell_address_out, cell_address_out_p0, cell_address_out_p2, cell_address_out_p1, cell_address_in_s: STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL phase_length_s, data_in_local_counter_cell_s: integer;
SIGNAL offset_length_s: integer;
SIGNAL master_counter_vec : STD_LOGIC_VECTOR (31 DOWNTO 0);
signal  data_out_internal_amp_cell_p0, data_out_internal_amp_cell_p1, data_out_internal_amp_cell_p2, data_in_phase_amp_cell_s : STD_LOGIC_VECTOR (31 DOWNTO 0);
SIGNAL data_in_pulse_counter_cell_s: STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
signal tsf_out_p0, tsf_out_p1, tsf_out_p2, tsf_in_s: INTEGER RANGE 0 TO (TSF)-1;
begin
-----------------------------------------------------------------------------------------------------------------------------------------                                 
pipe0: process (clock,reset) -- 0th stage of pipeline move from input ports to signals
-----------------------------------------------------------------------------------------------------------------------------------------                                 
        begin
            if (reset = '0') then
                 master_counter_vec<= (OTHERS => '0');
                 data_in_pulse_counter_cell_s <= (OTHERS => '0');
                 wave_type_s<= '0';
            elsif rising_edge(clock)  then   
                master_counter_vec <= master_counter;
                phase_length_s<= to_integer(unsigned(phase_length));
                offset_length_s<= to_integer(unsigned( offset_length));
                data_in_pulse_counter_cell_s <= data_in_pulse_counter_cell;
                data_in_local_counter_cell_s <= to_integer(unsigned(data_in_local_counter_cell));
                wave_type_s <= wave_type;
                tsf_in_s <= tsf_in;
                cell_address_in_s<= cell_address_in;
                data_in_phase_amp_cell_s <= data_in_phase_amp_cell;
                data_in_offset_amp_cell_s <= data_in_offset_amp_cell;       
          end if;
         end process pipe0;   
-----------------------------------------------------------------------------------------------------------------------------------------                                             
pipe1: process (clock,reset) -- 1st stage of pipeline do the comparision and update
-- pipe_en to choose data between square or ramp wave(Floating point adder)    
-----------------------------------------------------------------------------------------------------------------------------------------                                 
 
    begin
        if (reset = '0') then
	  state_cell <= '0';
	  pipeline_en <= '0';
      else
	if rising_edge(clock)  then
	if  (to_integer(unsigned(data_in_pulse_counter_cell_s)) < pulse_number) and cell_start = '1' and data_in_local_counter_cell_s/=to_integer(unsigned(master_counter_vec)) then
		if wave_type_s ='0' then
				
			if (to_integer(unsigned(master_counter_vec)) < offset_length_s ) then
				cell_address_out_p0 <= cell_address_in_s;
				tsf_out <= tsf_in_s;
				tsf_out_p0 <= tsf_in_s; 
				data_out_local_counter_cell<=master_counter_vec; --give Stim cells one chance every master count
				data_out_internal_amp_cell_p0 <= data_in_offset_amp_cell_s;--offset amp
				data_out_pulse_counter_cell <= data_in_pulse_counter_cell_s;
				state_cell <= '1';
			    pipeline_en <= '0';
			elsif( to_integer(unsigned(master_counter_vec)) >= offset_length_s and to_integer(unsigned(master_counter_vec)) < phase_length_s) then	
				cell_address_out_p0 <= cell_address_in_s;
				tsf_out <= tsf_in_s;	
                tsf_out_p0 <= tsf_in_s; 
				data_out_local_counter_cell<= master_counter_vec;
				data_out_pulse_counter_cell <= data_in_pulse_counter_cell_s;
				data_out_internal_amp_cell_p0 <= data_in_phase_amp_cell_s;--phase amp
				state_cell <= '1';
			    pipeline_en <= '0';
			elsif (to_integer(unsigned(master_counter_vec)) = phase_length_s) then
				cell_address_out_p0 <= cell_address_in_s;
				tsf_out <= tsf_in_s;
                tsf_out_p0 <= tsf_in_s; 
				data_out_local_counter_cell <= master_counter_vec;
				data_out_pulse_counter_cell <= STD_LOGIC_VECTOR(to_unsigned((to_integer(unsigned(data_in_pulse_counter_cell_s)) +1),data_in_pulse_counter_cell_s'length ));--increment only once due to data_out_local_counter_cell
				data_out_internal_amp_cell_p0<= data_in_offset_amp_cell_s;
				state_cell <= '1';
				pipeline_en <= '0';
			else 
						state_cell <= '0';
						pipeline_en <= '0';
		    end if;		
		else
			if (to_integer(unsigned(master_counter_vec)) <= offset_length_s ) then
				cell_address_out_p0 <= cell_address_in_s;
				tsf_out <= tsf_in_s;
                tsf_out_p0 <= tsf_in_s; 
				data_out_local_counter_cell <=master_counter_vec; --give Stim cells one chance every master count
				data_out_internal_amp_cell_p0 <= data_in_offset_amp_cell_s;--offset amp
				data_out_pulse_counter_cell <= data_in_pulse_counter_cell_s;
				state_cell <= '1';
				pipeline_en <= '0';
		  elsif( to_integer(unsigned(master_counter_vec)) > offset_length_s and to_integer(unsigned(master_counter_vec)) <= phase_length_s) then	
                 cell_address_out_p0 <= cell_address_in_s;
                 tsf_out <= tsf_in_s;   
                 tsf_out_p0 <= tsf_in_s; 
                 data_out_local_counter_cell<= master_counter_vec;
                 data_out_pulse_counter_cell <= data_in_pulse_counter_cell_s;
                 state_cell <= '1';
                 pipeline_en <= '1';
			elsif (to_integer(unsigned(master_counter_vec)) > phase_length_s) then
				cell_address_out_p0 <= cell_address_in_s;
				tsf_out <= tsf_in_s;
				tsf_out_p0 <= tsf_in_s;
				data_out_local_counter_cell <= master_counter_vec;
				data_out_pulse_counter_cell <= STD_LOGIC_VECTOR(to_unsigned((to_integer(unsigned(data_in_pulse_counter_cell_s))+1),data_in_pulse_counter_cell_s'length ));--increment only once due to data_out_local_counter_cell
				data_out_internal_amp_cell_p0<= data_in_offset_amp_cell_s;
				state_cell <= '1';
				pipeline_en <= '0';
			else 
						state_cell <= '0';
						pipeline_en <= '0';
		    end if;
				
     	end if;
	else
		state_cell <= '0';
		pipeline_en <= '0';
	end if;
      end if;
      end if;
    end process pipe1;
-----------------------------------------------------------------------------------------------------------------------------------------                                 
pipe2: process (clock,reset) --2nd stage buffer pipeline
-----------------------------------------------------------------------------------------------------------------------------------------                                 
            begin
                if (reset = '0') then
                data_out_internal_amp_cell_p1<= (OTHERS => '0');
                cell_address_out_p1 <= (OTHERS => '0');
                tsf_out_p1 <= 0;   
                pipeline_en_p1 <= '0';
              else
            if rising_edge(clock)  then
                     cell_address_out_p1 <= cell_address_out_p0;
                     tsf_out_p1 <= tsf_out_p0;    
                     data_out_internal_amp_cell_p1 <= data_out_internal_amp_cell_p0; --increment for ramp      
                     pipeline_en_p1 <= pipeline_en; 
                end if;
              end if;
             end process pipe2; 
-----------------------------------------------------------------------------------------------------------------------------------------                                 
pipe3: process (clock,reset)--3nd stage buffer pipeline
-----------------------------------------------------------------------------------------------------------------------------------------                                
                    begin
                    if (reset = '0') then
                       data_out_internal_amp_cell_p2<= (OTHERS => '0');
                       cell_address_out_p2 <= (OTHERS => '0');
                       tsf_out_p2 <= 0;   
                       pipeline_en_p2 <= '0';
                    else
                    if rising_edge(clock)  then
                        cell_address_out_p2 <= cell_address_out_p1;
                        tsf_out_p2 <= tsf_out_p1;    
                        data_out_internal_amp_cell_p2 <= data_out_internal_amp_cell_p1; --increment for ramp      
                         pipeline_en_p2 <= pipeline_en_p1; 
                     end if;
                     end if;
                     end process pipe3;  
-----------------------------------------------------------------------------------------------------------------------------------------                                
pipe4: process (clock,reset)  -- 4th stage of pipeline by means of pipe_en choose to move data to output ports
-- (Floating point adder with 4 stage latency has its data available with right sync)                 
-----------------------------------------------------------------------------------------------------------------------------------------                                
        begin
            if (reset = '0') then
            data_out_internal_amp_cell<= (OTHERS => '0');
            cell_address_out <= (OTHERS => '0');
            tsf_out_amp <= 0;    
          else
        if rising_edge(clock)  then
            if(pipeline_en_p2= '1') then
                 cell_address_out <= cell_address_out_p2;
                 tsf_out_amp <= tsf_out_p2;    
                 data_out_internal_amp_cell <= Float_adder_out; --increment for ramp    
           else
                 cell_address_out <= cell_address_out_p2;
                 tsf_out_amp <= tsf_out_p2;    
                 data_out_internal_amp_cell <= data_out_internal_amp_cell_p2; --increment for ramp       
             end if;
            end if;
          end if;
         end process pipe4; 
-----------------------------------------------------------------------------------------------------------------------------------------                                
uut_data_checker: COMPONENT data_checker -- data checker is signal variation detector that checks if generated data is new and sets valid
-----------------------------------------------------------------------------------------------------------------------------------------
 generic map (
       TSF     )
    Port map(   
            reset => reset,
            clock => clock,
            cell_start=> cell_start,
            cell_address_in => cell_address_in,
            data_in_internal_amp => data_in_internal_amp,
            tsf_in => tsf_in,
            data => data,
            address => address,
            we => we
);


end Behavioral;



