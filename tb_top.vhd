LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.StimG_Pkg.ALL;
USE work.float_pkg.ALL;

ENTITY tb_top IS
	GENERIC (
		exponent : INTEGER := 8;
		fraction : INTEGER :=  -23;
	DataWidthStim: INTEGER := 32;
                pulse_number : INTEGER := 4;
                pulse_number_bits : INTEGER := 2;
                Rtc : INTEGER := 50000; --in nano seconds
                PhyC : INTEGER := 2;
                StimC : INTEGER := 10;
                StimC_bits : INTEGER := 4
	);
	PORT (
             cluster_in_adr : out STD_LOGIC_VECTOR (StimC_bits-1 downto 0);
               cluster_in_data    : INOUT STD_LOGIC_VECTOR(31 DOWNTO 0)	);
END tb_top;
ARCHITECTURE rtl OF tb_top IS

-----------------------------------------------------------------------------------------------------------------------------
procedure clk_gen(signal clk : out std_logic; constant Time_period : integer) is
----------------------------------------------------------------------------------------------------------------------------
    constant PERIOD    : time := 1 ns * Time_period;        -- Full period
    constant HIGH_TIME : time := PERIOD / 2;          -- High time
    constant LOW_TIME  : time := PERIOD - HIGH_TIME;  -- Low time; always >= HIGH_TIME
  begin
    -- Generate a clock cycle
    loop
      clk <= '1';
      wait for HIGH_TIME;
      clk <= '0';
      wait for LOW_TIME;
    end loop;
  end procedure;

COMPONENT top is
  port (
             M_AXIS_ACLK	: in std_logic;
             M_AXIS_ARESETN : in std_logic;
             cluster_rdy    : in STD_LOGIC;
             cluster_in_ack : in STD_LOGIC;
             cluster_in_str : out STD_LOGIC;
             cluster_in_type : out STD_LOGIC_VECTOR (1 downto 0);
             cluster_in_data : out STD_LOGIC_VECTOR (31 downto 0);
             cluster_in_adr : out STD_LOGIC_VECTOR (StimC_bits-1 downto 0);
             reset         : IN STD_LOGIC;
             clock         : IN STD_LOGIC;
             start         : IN STD_LOGIC;
             init_str    : IN STD_LOGIC;
             init_in_typ    : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
             cell_in_address : IN STD_LOGIC_VECTOR(StimC_bits-1 DOWNTO 0) ;
             pulse_in_address: IN  STD_LOGIC_VECTOR(pulse_number_bits-1 DOWNTO 0);
             init_in_data_top: IN STD_LOGIC_VECTOR(31 DOWNTO 0);
             init_ack    : OUT STD_LOGIC;   
             start_ack    : OUT STD_LOGIC
  );
end COMPONENT top;

	SIGNAL reset : STD_LOGIC := '0';
	SIGNAL clock : STD_LOGIC := '0';
    SIGNAL clock_rt:  std_logic:='0';
	SIGNAL init_str : STD_LOGIC := '0';
	SIGNAL init_in_data : STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL init_ack,cluster_rdy, tvalid : STD_LOGIC;
	SIGNAL pulse_counter : INTEGER RANGE 0 TO pulse_number - 1 := 0;
	SIGNAL cell_counter : INTEGER RANGE 0 TO StimC - 1 := 0;
	SIGNAL phase_amplitude, offset_amplitude, phase_mem, offset_mem, wave_type_mem,inc_factor : boolean := false;
	SIGNAL cell_ready_merged_o:  std_logic;
	SIGNAL start :std_logic:='0';
	CONSTANT Rtc_const :integer := Rtc;
	CONSTANT input_clock : integer := 10;--1/100Mhz clock (in nano seconds)
	SIGNAL phase_counter : integer :=4; --4
	SIGNAL offset_counter : integer :=2;--2
	SIGNAL scheduler_DataOut : float32;
	SIGNAL scheduler_DataOut_top,init_in_data_top: STD_LOGIC_VECTOR(31 DOWNTO 0);
	SIGNAL scheduler_ADDRESS_out : INTEGER RANGE 0 TO StimC - 1;
	SIGNAL start_ack: STD_LOGIC;
	SIGNAL offset_amplitude_value : float32 := to_float(-4.0,8,23);
    SIGNAL phase_amplitude_value : float32 := to_float(6.0,8,23);
	SIGNAL reset_mcount 		:  STD_LOGIC:='0';
	SIGNAL init_in_typ	:  INTEGER RANGE 0 TO 7;
    SIGNAL cell_in_address :  INTEGER RANGE 0 TO StimC - 1;
    SIGNAL pulse_in_address:  INTEGER RANGE 0 TO pulse_number - 1;
    SIGNAL init_in_typ_top	: std_logic_vector(2 downto 0);
    SIGNAL cell_in_address_top :  STD_LOGIC_VECTOR(StimC_bits-1 DOWNTO 0);
    SIGNAL pulse_in_address_top:  STD_LOGIC_VECTOR(pulse_number_bits-1 DOWNTO 0);
    SIGNAL cluster_in_ack : STD_LOGIC := '0';
    SIGNAL cluster_in_str : STD_LOGIC;
    SIGNAL cluster_in_type : STD_LOGIC_VECTOR (1 downto 0);
BEGIN
scheduler_DataOut <= to_float(scheduler_DataOut_top,8,23);-- for input

init_in_typ_top<= std_logic_vector(to_unsigned(init_in_typ,init_in_typ_top'length));
cell_in_address_top<= std_logic_vector(to_unsigned(cell_in_address,cell_in_address_top'length));
pulse_in_address_top<= std_logic_vector(to_unsigned(pulse_in_address,pulse_in_address_top'length));

cluster_rdy <= '1' when start_ack ='1' else '0';
	uut_top : COMPONENT top
		PORT MAP(
		    M_AXIS_ACLK => clock,
            M_AXIS_ARESETN => reset,
			cluster_rdy => cluster_rdy,
            cluster_in_ack => cluster_in_ack,
            cluster_in_str => cluster_in_str,
            cluster_in_type => cluster_in_type,
            cluster_in_data => cluster_in_data,
            cluster_in_adr => cluster_in_adr,
			reset => reset, 
			clock => clock,
			start=> start,
			init_str => init_str, 
			init_in_typ => init_in_typ_top, 
			cell_in_address => cell_in_address_top, 
			pulse_in_address => pulse_in_address_top, 
			init_in_data_top => init_in_data, 
			init_ack => init_ack,
			start_ack => start_ack
		);

			reset <= '1' AFTER 150 ns;
			reset_mcount <= '1' AFTER 150 ns;

			clk_gen(clock,input_clock); -- operating frequency 
			clk_gen(clock_rt,Rtc_const); --   real time clock
			PROCESS (clock, init_ack)

	BEGIN
		IF reset = '1' THEN
			IF (clock'EVENT AND clock = '1') THEN
			    IF cluster_in_str = '1' then
			     cluster_in_ack <= '1';
		      	ELSE 
				 cluster_in_ack <= '0';
				END IF;					
				IF (phase_amplitude = false) THEN
					IF (cell_counter < StimC) THEN
						IF (init_str /= '1') THEN
							init_str <= '1';
							init_in_typ <= 0;
							cell_in_address <= cell_counter;
							pulse_in_address <= pulse_counter;
							init_in_data <= to_slv(phase_amplitude_value);
						END IF;
						IF (init_ack = '1') THEN
							init_str <= '0';
							IF (pulse_counter < pulse_number - 1) THEN
								pulse_counter <= pulse_counter + 1;
							ELSE
								pulse_counter <= 0;
								cell_counter <= cell_counter + 1;
							END IF;
						END IF;
					else
					cell_counter<=0;
					pulse_counter <= 0;
					phase_amplitude <= true;
					END IF;
				END IF;

				IF (phase_amplitude = true AND offset_amplitude = false) THEN
					IF (cell_counter < StimC) THEN
						IF (init_str /= '1') THEN
							init_str <= '1';
							init_in_typ <= 1;
							cell_in_address <= cell_counter;
                            pulse_in_address <= pulse_counter;
							init_in_data <= to_slv(offset_amplitude_value);
						END IF;
						IF (init_ack = '1') THEN
							init_str <= '0';
							IF (pulse_counter < pulse_number - 1) THEN
								pulse_counter <= pulse_counter + 1;
							ELSE
								pulse_counter <= 0;
								cell_counter <= cell_counter + 1;
							END IF;
						END IF;
					else
					cell_counter<=0;
					pulse_counter <= 0;
					offset_amplitude <= true;
					END IF;
				END IF;
				IF ( offset_amplitude = true AND  phase_mem = false) THEN
					IF (cell_counter < StimC) THEN
						IF (init_str /= '1') THEN
							init_str <= '1';
							init_in_typ <= 2;
							cell_in_address <= cell_counter;
                            pulse_in_address <= pulse_counter ;
							init_in_data <= std_logic_vector(to_unsigned(phase_counter,init_in_data'length));
						END IF;
						IF (init_ack = '1') THEN
							init_str <= '0';
							IF (pulse_counter < pulse_number - 1) THEN
								pulse_counter <= pulse_counter + 1;
								phase_counter<=phase_counter+4;--add 4 count more
							ELSE
								pulse_counter <= 0;
								cell_counter <= cell_counter + 1;
								phase_counter<=phase_counter+4;--add 4 count more
							END IF;
						END IF;
					else
					cell_counter<=0;
					pulse_counter <= 0;
					phase_mem <= true;
					END IF;
				END IF;
				IF ( phase_mem = true AND  offset_mem = false) THEN
					IF (cell_counter < StimC) THEN
						IF (init_str /= '1') THEN
							init_str <= '1';
							init_in_typ <= 3;
							cell_in_address <= cell_counter;
                            pulse_in_address <= pulse_counter ;
							init_in_data <= std_logic_vector(to_unsigned(offset_counter,init_in_data'length));
						END IF;
						IF (init_ack = '1') THEN
							init_str <= '0';
							IF (pulse_counter < pulse_number - 1) THEN
								pulse_counter <= pulse_counter + 1;
								offset_counter <=offset_counter+4;--add 4 count more
							ELSE
								pulse_counter <= 0;
								offset_counter <=offset_counter+4;--add 4 count more
								cell_counter  <= cell_counter + 1;
							END IF;
						END IF;
					else
					cell_counter<=0;
					pulse_counter <= 0;
					offset_mem <= true;
					END IF;
				END IF;
				IF ( offset_mem = true AND  wave_type_mem = false) THEN
					IF (cell_counter < StimC) THEN
						IF (init_str /= '1') THEN
							init_str <= '1';
							init_in_typ <= 4;
							cell_in_address <= cell_counter;
                            pulse_in_address <= pulse_counter ;
							init_in_data <= x"00000001";
						END IF;
						IF (init_ack = '1') THEN
							init_str <= '0';
							IF (pulse_counter < pulse_number - 1) THEN
								pulse_counter <= pulse_counter + 1;
							ELSE
								pulse_counter <= 0;
								cell_counter <= cell_counter + 1;
							END IF;
						END IF;
					else
					cell_counter<=0;
					pulse_counter <= 0;
					wave_type_mem <= true;
					END IF;
				END IF;

				IF ( inc_factor = false AND  wave_type_mem = true ) THEN
					IF (cell_counter < StimC) THEN
						IF (init_str /= '1') THEN
							init_str <= '1';
							init_in_typ <= 5;
							cell_in_address <= cell_counter;
                            pulse_in_address <= pulse_counter ;
							init_in_data <= to_slv((phase_amplitude_value - offset_amplitude_value)/ to_float(2.0,8,23));
						END IF;
						IF (init_ack = '1') THEN
							init_str <= '0';
							IF (pulse_counter < pulse_number - 1) THEN
								pulse_counter <= pulse_counter + 1;
							ELSE
								pulse_counter <= 0;
								cell_counter <= cell_counter + 1;
							END IF;
						END IF;
					else
					cell_counter<=0;
					pulse_counter <= 0;
					inc_factor <= true;
					END IF;
				END IF;
				
				IF inc_factor = true then
					start<='1';
				END IF;
			END IF;
		END IF;
	END PROCESS;

END rtl;
