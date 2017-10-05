----------------------------------------------------------------------------------
-- Company: Tu Delft
-- Engineer: HS Jagadeeshwar
-- 
-- Create Date: 10/02/2017 05:06:32 PM
-- Design Name: bridge_controller
-- Module Name: bridge_controller - Behavioral
-- Project Name: Stimulus Generator
-- Target Devices: vender independent
-- Tool Versions: Vivado 2015.4
-- Description: This file describes bridge controller which accepts ready and valid signals from top module
-- and puts them as strobe and valid signals required to interface with Jan's ION implementation
-- This module uses state machine to implement the functionality
-- descripltion of each state is provided in comments besides its code
-- Dependencies: No component Instantiation 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

entity bridge_controller is
  GENERIC (
      StimC_bits : INTEGER := 4
        );
    Port ( 
	   M_AXIS_ACLK	: in std_logic;
	   M_AXIS_ARESETN : in std_logic;
	   cluster_rdy : in STD_LOGIC;
           cluster_in_ack : in STD_LOGIC;
           cluster_in_str : out STD_LOGIC;
           Read_En : out STD_LOGIC;
           cluster_in_type : out STD_LOGIC_VECTOR (1 downto 0);
           cluster_in_data : out STD_LOGIC_VECTOR (31 downto 0);
           cluster_in_adr : out STD_LOGIC_VECTOR (StimC_bits-1 downto 0);
           data_valid : in STD_LOGIC;
           data_in : in STD_LOGIC_VECTOR (31 downto 0);
           address_in : in STD_LOGIC_VECTOR (31 downto 0));
end bridge_controller;

architecture Behavioral of bridge_controller is
-- Define the states of state machine                                             
	-- The control state machine oversees the writing of input streaming data to the cluster_in_data,
	-- and outputs the streaming data from the FIFO                                   
	type state is ( IDLE,        -- This is the initial/idle state  
		                           -- This state is waiting for valid data in FIFO and cluster_rdy
	                                -- the state machine changes state to DATA_READY                    
	                DATA_READY,  -- In this state valid data is put on cluster_in_data and sets strobe
				                  -- the state machine changes state to DATA_READY    
			DATA_WAITING, -- In this state state machine is waiting for acknowledgement  
					-- the state machine changes state to DATA_SENT
			DATA_SENT);-- In this state strobe is reset  
					-- the state machine changes state to IDLE
	-- State variable                                                                 
	signal  mst_exec_state : state;   
 
begin
   cluster_in_data <= data_in;
   cluster_in_adr  <= std_logic_vector(resize(unsigned(address_in),StimC_bits));
   cluster_in_type <= "10";
-- Control state machine implementation                                               
	process(M_AXIS_ACLK)                                                                        
	begin                                                                                       
	  if (rising_edge (M_AXIS_ACLK)) then                                                       
	    if(M_AXIS_ARESETN = '0') then                                                           
	      -- Synchronous reset (active low)                                                     
	      mst_exec_state      <= IDLE;                                                          
	    else                                                                                    
	      case (mst_exec_state) is                                                              
	        when IDLE     =>                                                                    
	          -- The slave starts accepting cluster_in_data when                                          
	           -- there cluster_rdy is asserted to mark                                           
	            -- ready for accepting streaming data   
	            if ( data_valid = '1' and cluster_rdy = '1') then
                  Read_En <= '1';
                  mst_exec_state  <= DATA_READY;                                               
                else                                                                            
                  mst_exec_state  <= IDLE;                                              
                end if;                                                                                                                    
	                                                                                    
 		when DATA_READY =>                                                              
	            -- This state is responsible for setting strobe        
	            mst_exec_state  <= DATA_WAITING;                                            
		        cluster_in_str  <= '1';
		        Read_En <= '0';
 		when DATA_WAITING =>                                                              
	            -- This state is responsible to wait for acknowledgement           
	            if ( cluster_in_ack = '1') then
	              mst_exec_state  <= DATA_SENT;                                               
	            else                                                                            
	              mst_exec_state  <= DATA_WAITING;                                              
	            end if;                                                                                 
	                                                                                            
	        when DATA_SENT  =>                                                                                      
	            -- This state is responsible to reset strobe and wait
		     --for acknowledgement to reset           
		    cluster_in_str  <= '0';                                        
	            if ( cluster_in_ack = '0') then
	              mst_exec_state  <= IDLE;                                               
	            else                                                                            
	              mst_exec_state  <= DATA_SENT;                                              
	            end if;                                                                           
	                                                                                            
	        when others    =>                                                                   
	          mst_exec_state <= IDLE;                                                                                                                                    
	      end case;                                                                             
	    end if;                                                                                 
	  end if;                                                                                   
	end process;                                                                                



end Behavioral;
