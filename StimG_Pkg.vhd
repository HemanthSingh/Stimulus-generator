--------------------------------------------------------------------------------
--
-- Package StimG_Pkg
-- File: StimG_Pkg.vhd
-- Author: HS Jagadeeshwar
-- Description: Package with type and component declarations for Stimulus Generator IP
-- compatible axi-slaves
-- Date: April, 2010
-- Modified: 
-- Remarks: 
--
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-----------------------------------------------------------------------------------------------------------------
PACKAGE StimG_Pkg IS
----------------------------------------------------------------------------------------------------------------- 

	TYPE int_array IS ARRAY (INTEGER RANGE <>) OF INTEGER;
	TYPE std_logic_array IS ARRAY (INTEGER RANGE <>) OF std_logic;
	SUBTYPE logic IS std_logic;
	TYPE std_logic_new IS ARRAY (INTEGER RANGE <>) OF logic;
	TYPE std_logic_32_array IS ARRAY (INTEGER RANGE <>) OF std_logic_vector(31 DOWNTO 0);
	TYPE bool_array IS ARRAY (INTEGER RANGE <>) OF boolean;

	constant XBITS :INTEGER := 32;   
   	constant YBITS :INTEGER := 8; 
   	constant GRAIN :INTEGER := 2; --Allways in 2!!!!
   	constant DEPTH :INTEGER := 4; --Every how much steps register
   	function clogb2 (bit_depth : integer) return integer;

	PROCEDURE merge
		(SIGNAL merge_in : IN std_logic_array;
		SIGNAL merge_out : OUT std_logic);
		--------------------------------------------------------------------------------------------------------------------
        component adder_sp_p1_wrapper is
        --------------------------------------------------------------------------------------------------------------------
        port (
          ap_clk : in STD_LOGIC;
          ap_rst : in STD_LOGIC;
          inA : in STD_LOGIC_VECTOR ( 31 downto 0 );
          inB : in STD_LOGIC_VECTOR ( 31 downto 0 );
          out1 : out STD_LOGIC_VECTOR ( 31 downto 0 )
        );
        end component adder_sp_p1_wrapper;
		--------------------------------------------------------------------------------------------------------------------
		COMPONENT address_decoder IS
		--------------------------------------------------------------------------------------------------------------------
			GENERIC (
				pulse_number : INTEGER;
				TSF : INTEGER
			);
			PORT (
				cell_in_address : IN INTEGER RANGE 0 TO TSF - 1;
				pulse_in_address : IN INTEGER RANGE 0 TO pulse_number - 1;
				address_out : OUT INTEGER RANGE 0 TO (TSF * pulse_number) - 1
			);
		END COMPONENT address_decoder;
		--------------------------------------------------------------------------------------------------------------------
		COMPONENT phase_memory IS
		--------------------------------------------------------------------------------------------------------------------
			GENERIC (
				pulse_number : INTEGER;
				TSF : INTEGER
			);
			PORT (
				clock : IN std_logic;
				data : IN std_logic_vector (31 DOWNTO 0);
				write_address : IN INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
				read_address : IN INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
				we : IN std_logic;
				q : OUT std_logic_vector (31 DOWNTO 0)
			);
		END COMPONENT phase_memory;
		--------------------------------------------------------------------------------------------------------------------
		COMPONENT offset_memory IS
		--------------------------------------------------------------------------------------------------------------------
			GENERIC (
				pulse_number : INTEGER;
				TSF : INTEGER
			);
			PORT (
				clock : IN std_logic;
				data : IN std_logic_vector (31 DOWNTO 0);
				write_address : IN INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
				read_address : IN INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
				we : IN std_logic;
				q : OUT std_logic_vector (31 DOWNTO 0)
			);
		END COMPONENT offset_memory;
		-------------------------------------------------------------------------------------------------------------------
		COMPONENT phase_amplitude IS
		-------------------------------------------------------------------------------------------------------------------
			GENERIC (
				pulse_number : INTEGER;
				TSF : INTEGER 
			);
			PORT (
				clock : IN std_logic;
				data:  IN    std_logic_vector(31 downto 0);
				write_address : IN INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
				read_address : IN INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
				we : IN std_logic;
				q : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
			);
		END COMPONENT phase_amplitude;
		-------------------------------------------------------------------------------------------------------------------
		COMPONENT offset_amplitude IS
		-------------------------------------------------------------------------------------------------------------------
			GENERIC (
				pulse_number : INTEGER;
				TSF : INTEGER 
			);
			PORT (
				clock : IN std_logic;
				data:  IN    std_logic_vector(31 downto 0);
				write_address : IN INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
				read_address : IN INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
				we : IN std_logic;
				q : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
			);
		END COMPONENT offset_amplitude;
				-------------------------------------------------------------------------------------------------------------------
		COMPONENT inc_factor IS
		-------------------------------------------------------------------------------------------------------------------
			GENERIC (
				pulse_number : INTEGER;
				TSF : INTEGER 
			);
			PORT (
				clock : IN std_logic;
				data:  IN    std_logic_vector(31 downto 0);
				write_address : IN INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
				read_address : IN INTEGER RANGE 0 TO (TSF * pulse_number) - 1;
				we : IN std_logic;
				q : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
			);
		END COMPONENT inc_factor;
		-------------------------------------------------------------------------------------------------------------------
		COMPONENT wave_typ_memory IS
		-------------------------------------------------------------------------------------------------------------------
			GENERIC (
				pulse_number : INTEGER;
				TSF : INTEGER
			);
			PORT (
				clock : IN std_logic;
				data : IN std_logic;
				write_address : IN INTEGER RANGE 0 TO TSF - 1;
				read_address : IN INTEGER RANGE 0 TO TSF - 1;
				we : IN std_logic;
				q : OUT std_logic
			);
		END COMPONENT wave_typ_memory;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT phase_indicator_mem IS
			-----------------------------------------------------------------------------------------------------------------
			GENERIC (
				pulse_number : INTEGER;
				TSF : INTEGER 
			);
			PORT (
				clock : IN std_logic;
				data : IN std_logic;
				write_address : IN INTEGER RANGE 0 TO TSF - 1;
				read_address : IN INTEGER RANGE 0 TO TSF - 1;
				we : IN std_logic;
				q : OUT std_logic
			);
		END COMPONENT phase_indicator_mem;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT pulse_counter_mem IS
			-----------------------------------------------------------------------------------------------------------------
			GENERIC (
				pulse_number_bits : INTEGER;
				TSF : INTEGER ;
			    PhyC : INTEGER:=5
			);
			PORT ( 
			      clock: IN   std_logic;
			      data:  IN   STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
			      write_address:  IN   integer RANGE 0 to TSF-1;
			      read_address:   IN   integer RANGE 0 to TSF-1;
			      we:    IN   std_logic;
			      q:     OUT  STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
			      tsf_out_pulse : OUT INTEGER RANGE 0 TO TSF-1;
			      cell_address_in_pulse : IN integer;
			      cell_address_out_pulse : OUT integer	
                );
		END COMPONENT pulse_counter_mem;

		-----------------------------------------------------------------------------------------------------------------
		COMPONENT internal_amp_mem IS
			-----------------------------------------------------------------------------------------------------------------
			GENERIC (
				TSF : INTEGER 
			);
			PORT (
				clock: IN   std_logic;
      				data:  IN    std_logic_vector(31 downto 0);
      				write_address:  IN   integer RANGE 0 to (TSF)-1;
   				read_address:   IN   integer RANGE 0 to (TSF)-1;
    				we:    IN   std_logic;
    				q:     OUT  STD_LOGIC_VECTOR (31 DOWNTO 0)
			);
		END COMPONENT internal_amp_mem;

		-----------------------------------------------------------------------------------------------------------------
		COMPONENT init_controller IS
		-----------------------------------------------------------------------------------------------------------------
			GENERIC (
				pulse_number : INTEGER;
				pulse_number_bits : INTEGER;
				RTC : INTEGER; --in nano seconds
				PhyC : INTEGER;
				TSF : INTEGER; -- Time sharing factor
				StimC : INTEGER;
				StimC_bits : INTEGER
			);
			PORT (
				reset : IN STD_LOGIC;
				clock : IN STD_LOGIC;
			 	init_str : IN STD_LOGIC;
				init_in_typ	: IN STD_LOGIC_VECTOR(2 DOWNTO 0);
				cell_in_address : IN STD_LOGIC_VECTOR( StimC_bits-1 DOWNTO 0) ;
				pulse_in_address: IN  STD_LOGIC_VECTOR( pulse_number_bits-1 downto 0);
	           	init_in_data : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
				init_ack : OUT STD_LOGIC; 
		--write enable into local memory
				we_phase : OUT std_logic_array(0 TO PhyC-1);
				we_offset : OUT std_logic_array(0 TO PhyC-1);
				we_phase_amp : OUT std_logic_array(0 TO PhyC-1);
				we_offset_amp : OUT std_logic_array(0 TO PhyC-1);
				we_wave_typ : OUT std_logic_array(0 TO PhyC - 1);
				we_inc_factor : OUT std_logic_array(0 TO PhyC-1);
		--write data for local memory
				init_out_off : OUT std_logic_32_array(0 TO PhyC-1);
				init_out_phase : OUT std_logic_32_array(0 TO PhyC-1);
				init_out_w_typ : OUT std_logic_array(0 TO PhyC-1);
				init_out_phase_amp : OUT std_logic_32_array(0 TO PhyC-1);
				init_out_offset_amp : OUT std_logic_32_array(0 TO PhyC-1);
			   	init_out_inc_factor : OUT std_logic_32_array(0 TO PhyC-1);
		--address decoder signals
				wave_typ_address : OUT INTEGER RANGE 0 TO TSF - 1;
				address_out_write : OUT INTEGER RANGE 0 TO (TSF * pulse_number)-1
			);
		END COMPONENT init_controller;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT indexer IS
		-----------------------------------------------------------------------------------------------------------------
			GENERIC (
				PhyC : INTEGER;
				StimC : INTEGER
			);
			PORT (
				cell_in_address : IN INTEGER RANGE 0 TO StimC - 1;
				index : OUT INTEGER RANGE 0 TO PhyC - 1
			);
		END COMPONENT indexer;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT fetcher IS
		-----------------------------------------------------------------------------------------------------------------
			GENERIC (
				PhyC : INTEGER;
				pulse_number : INTEGER;
			    pulse_number_bits: Integer;
				TSF : INTEGER
			);
			PORT (
                  reset : IN STD_LOGIC;
                   clock : IN std_logic;
                   start : IN std_logic;
                   cell_ready : OUT std_logic;
                   master_count : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                   coc_number: IN INTEGER RANGE 0 TO (PhyC)-1;-- cell on chip id number
                   --read from local memory
                   read_address_phase : OUT INTEGER RANGE 0 TO(TSF * pulse_number) - 1;
                   read_address_offset : OUT INTEGER RANGE 0 TO(TSF * pulse_number) - 1;
                   read_address_phase_amp : OUT INTEGER RANGE 0 TO(TSF * pulse_number) - 1;
                   read_address_offset_amp : OUT INTEGER RANGE 0 TO(TSF * pulse_number) - 1;
                   read_address_wave : OUT INTEGER RANGE 0 TO(TSF) - 1; 
                   read_address_inc_factor : OUT INTEGER RANGE 0 TO(TSF * pulse_number) - 1;
                   --data in from local memory
                   q_data_phase : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                   q_data_offset : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                   q_data_phase_amp : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                   q_data_offset_amp : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                   q_data_wave : IN STD_LOGIC;
                   q_data_inc_factor : IN STD_LOGIC_VECTOR (31 DOWNTO 0);
                   --output stimulus
                   master_counter : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                   phase_length: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                   offset_length: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                   wave_type: OUT STD_LOGIC;
                   inc_step: OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                   tsf_in: OUT INTEGER RANGE 0 TO (TSF)-1;
                   cell_address_in : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                   data_in_internal_amp : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                   data_in_pulse_counter_cell : OUT STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
                   data_in_local_counter_cell : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                   data_in_phase_amp_cell : OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                   data_in_offset_amp_cell :OUT STD_LOGIC_VECTOR (31 DOWNTO 0);
                   --input stimulus
                   data_out_pulse_counter_cell : IN STD_LOGIC_VECTOR (pulse_number_bits DOWNTO 0);
                   data_out_local_counter_cell : IN STD_LOGIC_VECTOR (31 DOWNTO 0); 
		   data_out_internal_amp_cell: IN STD_LOGIC_VECTOR (31 DOWNTO 0);
		   tsf_out: IN INTEGER RANGE 0 TO (TSF)-1;
		   tsf_out_amp: IN INTEGER RANGE 0 TO (TSF)-1
			);
		END COMPONENT fetcher;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT tsf_counter IS
		-----------------------------------------------------------------------------------------------------------------
			GENERIC (
				TSF : INTEGER
			);
			PORT (
				reset : IN std_logic;
				clock : IN std_logic;
				cell_ready : IN std_logic;
				tsf_count : OUT INTEGER RANGE 0 TO TSF - 1
			);
		END COMPONENT tsf_counter;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT master_counter_comp IS
		-----------------------------------------------------------------------------------------------------------------
			PORT (
				reset : IN std_logic;
				clock_rt : IN std_logic;
				cell_ready : IN std_logic;
				master_count : OUT STD_LOGIC_VECTOR (31 DOWNTO 0)
			);
		END COMPONENT master_counter_comp;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT cell_address_gen IS
		-----------------------------------------------------------------------------------------------------------------
 		 generic (  PhyC : INTEGER;
			    TSF : INTEGER
		    );
   		PORT(
     			 tsf_in : IN INTEGER RANGE 0 TO TSF-1;
      			 coc_in : IN INTEGER RANGE 0 TO PhyC-1;
      			 cell_address: out   integer
   		);
		END COMPONENT cell_address_gen;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT inv_cell_address_gen IS
		-----------------------------------------------------------------------------------------------------------------
		  generic (  PhyC : INTEGER;
			     TSF : INTEGER
				);
		   PORT
		   (
		     cell_address: IN   INTEGER RANGE 0 to (TSF*PhyC)-1;
		     coc_in : IN INTEGER RANGE 0 TO PhyC-1;
		     tsf_out : OUT INTEGER RANGE 0 TO TSF-1
		   );
		END COMPONENT inv_cell_address_gen;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT stimulus_cell IS
		-----------------------------------------------------------------------------------------------------------------
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
		end COMPONENT stimulus_cell;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT local_counter_mem IS
		-----------------------------------------------------------------------------------------------------------------
		  generic (  pulse_number: Integer;
			     TSF : Integer );
		   PORT
		   (
		      clock: IN   std_logic;
		      data:  IN   STD_LOGIC_VECTOR (31 DOWNTO 0);
		      write_address:  IN   integer RANGE 0 to TSF-1;
		      read_address:   IN   integer RANGE 0 to TSF-1;
		      we:    IN   std_logic;
		      q:     OUT  STD_LOGIC_VECTOR (31 DOWNTO 0)
		   );
		END COMPONENT local_counter_mem;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT DATA_FIFO is
		-----------------------------------------------------------------------------------------------------------------
			Generic (
                        PhyC: Integer
			);
			Port ( 
				CLK		: in  STD_LOGIC;
                    RST        : in  STD_LOGIC;
                    DATA_WriteEn    : in  STD_LOGIC;
                    DataIn    : in  STD_LOGIC_VECTOR(31 downto 0);
                    ReadEn    : in  STD_LOGIC;
                    DataOut    : out STD_LOGIC_VECTOR(31 downto 0);
                    Empty    : out STD_LOGIC;
                    Full    : out STD_LOGIC
			);
		end COMPONENT DATA_FIFO;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT OUT_FIFO is
		-----------------------------------------------------------------------------------------------------------------
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
		end COMPONENT OUT_FIFO;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT ADDRESS_FIFO is
		-----------------------------------------------------------------------------------------------------------------
			Generic (
					PhyC: Integer			);
			Port ( 
				CLK		: in  STD_LOGIC;
				RST		: in  STD_LOGIC;
				ADDRESS_WriteEn	: in  STD_LOGIC;
				DataIn	: in  STD_LOGIC_VECTOR(31 DOWNTO 0);
				ReadEn	: in  STD_LOGIC;
				DataOut	: out STD_LOGIC_VECTOR(31 DOWNTO 0);
				Empty	: out STD_LOGIC;
				Full	: out STD_LOGIC
			);
		end COMPONENT ADDRESS_FIFO;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT rr_scheduler is
		-----------------------------------------------------------------------------------------------------------------
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
		end COMPONENT rr_scheduler;
		-----------------------------------------------------------------------------------------------------------------
		COMPONENT rrarbiter is
		-----------------------------------------------------------------------------------------------------------------
		generic ( PhyC : integer;
				StimC : INTEGER );
			port (
				clk   : in    std_logic;
				rst_n : in    std_logic;
				valid   : in    std_logic;
				grant : out   INTEGER RANGE 0 TO PhyC-1;
				grant_buffer :  out INTEGER RANGE 0 TO PhyC-1;
				grant_buffer_buffer :  out INTEGER RANGE 0 TO PhyC-1
			);
		end COMPONENT rrarbiter;
		
		-----------------------------------------------------------------------------------------------------------------		
       COMPONENT float_adder_wrapper is
        -----------------------------------------------------------------------------------------------------------------
          port (
           inA : in STD_LOGIC_VECTOR ( 31 downto 0 );
           inB : in STD_LOGIC_VECTOR ( 31 downto 0 );
           out1 : out STD_LOGIC_VECTOR ( 31 downto 0 )
          );
        end COMPONENT float_adder_wrapper; 
   		-----------------------------------------------------------------------------------------------------------------		     
        COMPONENT data_checker is
        -----------------------------------------------------------------------------------------------------------------	
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
        end COMPONENT data_checker;
        -----------------------------------------------------------------------------------------------------------------		     
        COMPONENT clk_divider is
        -----------------------------------------------------------------------------------------------------------------	
        GENERIC (
                Clock_div : INTEGER 
            );
            Port (
                clk_in : in  STD_LOGIC;
                reset  : in  STD_LOGIC;
                cell_ready : IN std_logic;
                clk_out: out STD_LOGIC
            );
        end COMPONENT clk_divider;
        -----------------------------------------------------------------------------------------------------------------		     
        COMPONENT bram_tdp is
        -----------------------------------------------------------------------------------------------------------------		     
        generic (
            DATA    : integer := 32;
            ADDR    : integer := 1
        );
        port (
            -- Port A
            a_clk   : in  std_logic;
            a_wr    : in  std_logic;
            a_addr  : in  std_logic_vector(ADDR-1 downto 0);
            a_din   : in  std_logic_vector(DATA-1 downto 0);
            a_dout  : out std_logic_vector(DATA-1 downto 0);
             
            -- Port B
            b_clk   : in  std_logic;
            b_wr    : in  std_logic;
            b_addr  : in  std_logic_vector(ADDR-1 downto 0);
            b_din   : in  std_logic_vector(DATA-1 downto 0);
            b_dout  : out std_logic_vector(DATA-1 downto 0)
        );
        end COMPONENT bram_tdp;
        -----------------------------------------------------------------------------------------------------------------		             
        COMPONENT bridge_controller is
        -----------------------------------------------------------------------------------------------------------------		     
            GENERIC (
            StimC_bits : INTEGER := 4
              );
          Port ( 
             M_AXIS_ACLK    : in std_logic;
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
        end COMPONENT bridge_controller;

	END StimG_Pkg;

	-----------------------------------------------------------------------------------------------------------------
	PACKAGE BODY StimG_Pkg IS
	-----------------------------------------------------------------------------------------------------------------
		PROCEDURE merge
			(SIGNAL merge_in : IN std_logic_array;
			SIGNAL merge_out : OUT std_logic) IS
			VARIABLE internal : std_logic := '1';
			VARIABLE I : INTEGER;
			BEGIN
				I := 0;
				WHILE (I < merge_in'length) LOOP
				internal := internal AND merge_in(I);
				I := I + 1;
			    END LOOP;
			merge_out <= internal;
			END merge;
             
        	function clogb2 (bit_depth : integer) return integer is            
             variable depth  : integer := bit_depth;                               
             variable count  : integer := 1;                                       
         begin                                                                   
              for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
              if (bit_depth <= 2) then                                           
                count := 1;                                                      
              else                                                               
                if(depth <= 1) then                                              
                    count := count;                                                
                  else                                                             
                    depth := depth / 2;                                            
                  count := count + 1;                                            
                  end if;                                                          
                end if;                                                            
           end loop;                                                             
           return(count);                                                          
         end;  
END;
