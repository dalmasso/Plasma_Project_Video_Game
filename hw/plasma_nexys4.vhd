----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05.09.2017 13:36:17
-- Design Name: 
-- Module Name: plasma_nexys4 - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity plasma_nexys4 is
    Port ( clk : in STD_LOGIC;
    
           -- Reset
           btnC : in STD_LOGIC;
           btnR : in std_logic;
           
           --UART
           RsRx : in STD_LOGIC;
           RsTx : out STD_LOGIC;
           
           --VGA
           hs : out  STD_LOGIC;
           vs : out  STD_LOGIC;
           vgaRed : out  std_logic_vector(3 downto 0);
           vgaBlue : out  std_logic_vector(3 downto 0);
           vgaGreen : out  std_logic_vector(3 downto 0);           
           
           -- Spi interface Signals
           SCLK       : out STD_LOGIC;
           MOSI       : out STD_LOGIC;
           MISO       : in STD_LOGIC;
           SS         : out STD_LOGIC;
           
           -- 7segs
           seg : out  std_logic_vector (6 downto 0);
           an : out  std_logic_vector (7 downto 0);
           
           -- Speed game
           sw : in std_logic_vector(2 downto 0);
           
           -- Accelerometer led display
           led : out std_logic_vector (9 downto 0)
           );
end plasma_nexys4;

architecture Behavioral of plasma_nexys4 is

-- CPU
component plasma
   generic(memory_type : string := "XILINX_16X"; --"DUAL_PORT_" "ALTERA_LPM";
           log_file    : string := "UNUSED";
           ethernet    : std_logic := '0';
           use_cache   : std_logic := '0');
   port(clk          : in std_logic;
        reset        : in std_logic;

        uart_write   : out std_logic;
        uart_read    : in std_logic;

        address      : out std_logic_vector(31 downto 2);
        byte_we      : out std_logic_vector(3 downto 0); 
        data_write   : out std_logic_vector(31 downto 0);
        data_read    : in std_logic_vector(31 downto 0);
        mem_pause_in : in std_logic;
        no_ddr_start : out std_logic;
        no_ddr_stop  : out std_logic;
        
        gpio0_out    : out std_logic_vector(31 downto 0);
        gpioA_in     : in std_logic_vector(31 downto 0));
end component; --entity plasma

-- Horl 25MHz
component Clkgen
	 generic ( 	SYS_CLK	: integer := 100000000;	-- Clk Master
				USER_CLK : integer := 25000000		-- Clk User
			 );
				
    Port ( clk_in : in  STD_LOGIC;
           rst_in : in  STD_LOGIC;
           clk_out : out  STD_LOGIC
		  );
end component;

-- Accelerometer Controller
component AccelerometerCtl
generic 
(
   SYSCLK_FREQUENCY_HZ : integer := 100000000;
   SCLK_FREQUENCY_HZ   : integer := 1000000;
   NUM_READS_AVG       : integer := 16;
   UPDATE_FREQUENCY_HZ : integer := 100
);
port
(
 SYSCLK     : in STD_LOGIC; -- System Clock
 RESET      : in STD_LOGIC;

 -- Spi interface Signals
 SCLK       : out STD_LOGIC;
 MOSI       : out STD_LOGIC;
 MISO       : in STD_LOGIC;
 SS         : out STD_LOGIC;

-- Accelerometer data signals
 ACCEL_X_OUT    : out STD_LOGIC_VECTOR (8 downto 0);
 ACCEL_Y_OUT    : out STD_LOGIC_VECTOR (9 downto 0);
 ACCEL_MAG_OUT  : out STD_LOGIC_VECTOR (11 downto 0);
 ACCEL_TMP_OUT  : out STD_LOGIC_VECTOR (11 downto 0)

);
end component;


-- 7segments Controller
component sSegDisplay is
    Port(ck : in  std_logic;                          -- 100MHz system clock
			number : in  std_logic_vector (55 downto 0); -- eight digit number to be displayed
			seg : out  std_logic_vector (6 downto 0);    -- display cathodes
			an : out  std_logic_vector (7 downto 0));    -- display anodes (active-low, due to transistor complementing)
end component;


-- VGA Controler
component VGA_640x480
    Port ( rst : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           hsync : out  STD_LOGIC;
           vsync : out  STD_LOGIC;
           hc : out  STD_LOGIC_VECTOR (9 downto 0);
           vc : out  STD_LOGIC_VECTOR (9 downto 0);
           vidon : out  STD_LOGIC);
end component;

-- VGA PROM
component VGA_PROM_2 is
    Port ( hc : in STD_LOGIC_VECTOR (9 downto 0);
       vc : in STD_LOGIC_VECTOR (9 downto 0);
       vidon : in STD_LOGIC;
       RED : out STD_LOGIC_VECTOR (3 downto 0);
       GREEN : out STD_LOGIC_VECTOR (3 downto 0);
       BLUE : out STD_LOGIC_VECTOR (3 downto 0);
       
       -- Ball (! X Y inv !)
       M_ball : in std_logic_vector (11 DOWNTO 0);
       ball_ROM_ADDR : out std_logic_vector (9 downto 0);
       ball_pos : in STD_LOGIC_Vector (19 downto 0); -- ACC_X(19-10) ACC_Y(9-0)
       
       -- Obstacles (! X Y inv !)
       M_obst : in std_logic_vector (11 DOWNTO 0);
       obst_ROM_ADDR : out std_logic_vector (11 downto 0);
       M_obst2 : in std_logic_vector (11 DOWNTO 0);
       obst_ROM_ADDR2 : out std_logic_vector (11 downto 0);
       obst_pos : in STD_LOGIC_Vector (19 downto 0); -- X (19-10) Y (9-0)
       obst2_pos : in STD_LOGIC_Vector (19 downto 0); -- X (19-10) Y (9-0) 
       
       -- Game Over
       M_gmov : in std_logic_vector (11 DOWNTO 0);
       gmov_ROM_ADDR : out std_logic_vector (15 downto 0);
       Enable_GMOV : in std_logic
       );
end component;

-- PROM (ball)
component PROM_Ball IS
  PORT (
  clka : IN STD_LOGIC;
  addra : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
  douta : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
);
END component;

-- PROM (obstacles)
component PROM_Obst IS
  PORT (
  clka : IN STD_LOGIC;
  addra : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
  douta : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
  clkb : IN STD_LOGIC;
  addrb : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
  doutb : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
);
END component;

-- PROM (GAME OVER)
component PROM_GMOV IS
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
  );
END component;

-- RAM CODE
component RAM_CODE IS
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(12 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END component;

-- DIV clk signal
signal clk25 : std_logic := '0';

-- Plasma signals
-- GPIOOUT :
--          31 : enable game over
--          30 downto 23 : ...
--          22 downto 20 : select digit
--          19 downto 13 : 7segments value
--          12 downto 10 : selection type of position
--                         000 pos ball col
--                         001 pos ball line
--                         011 pos obst1 col
--                         010 pos obst2 col
--                         110 pos obst1 line
--                         100 pos obst2 line  
--          9 downto 0 : positions (ball col/line, obst1 col/line, obst2 col/line)

-- GPIOA_IN: 31 downto 14 : ...
--                     13 : BTNR (restart game)  
--			 12 downto 10 : SW (speed)
--           9 downto 0   : ACCEL_Y (ball_col)
           
signal sig_mem_pause_in,noddr_start,noddr_stop : std_logic;
signal sig_data_read,dat_write,gpio_out : std_logic_vector(31 downto 0);
signal addr : std_logic_vector(31 downto 2);
signal bytewe : std_logic_vector(3 downto 0);

-- VGA signals
signal hc,vc : STD_LOGIC_VECTOR (9 downto 0);
signal vid : STD_LOGIC;

-- PROMs signals
signal M_Ball : std_logic_vector (11 downto 0);
signal ball_ROM_ADDR : std_logic_vector (9 downto 0);
signal M_Obst,M_Obst2 : STD_LOGIC_VECTOR(11 DOWNTO 0);
signal obst_ROM_ADDR,obst_ROM_ADDR2 : STD_LOGIC_VECTOR(11 DOWNTO 0);
signal M_gmov : std_logic_vector (11 DOWNTO 0);
signal gmov_ROM_ADDR : std_logic_vector (15 downto 0);

-- Positions signals
signal pos_ball_col : std_logic_vector (9 downto 0);
signal pos_ball_lign : std_logic_vector (9 downto 0);
signal pos_obst_col : std_logic_vector (9 downto 0);
signal pos_obst_lign : std_logic_vector (9 downto 0);
signal pos_obst2_col : std_logic_vector (9 downto 0);
signal pos_obst2_lign : std_logic_vector (9 downto 0);

-- Accelerometer signals
signal ACCEL_X_OUT_sig    : STD_LOGIC_VECTOR (8 downto 0);
signal ACCEL_Y_OUT_sig     : STD_LOGIC_VECTOR (9 downto 0);
signal ACCEL_MAG_OUT_sig   : STD_LOGIC_VECTOR (11 downto 0);
signal ACCEL_TMP_OUT_sig   : STD_LOGIC_VECTOR (11 downto 0);

-- DIGITS signal
signal digit7_value : std_logic_vector(6 downto 0);
signal digit6_value : std_logic_vector(6 downto 0);
signal digit5_value : std_logic_vector(6 downto 0);
signal digit4_value : std_logic_vector(6 downto 0);
signal digit3_value : std_logic_vector(6 downto 0);
signal digit2_value : std_logic_vector(6 downto 0);
signal digit1_value : std_logic_vector(6 downto 0);
signal digit0_value : std_logic_vector(6 downto 0);

begin

clkdiv: Clkgen port map(clk,btnC,clk25);

plasm: plasma port map(clk25,btnC,RsTx,RsRx,addr,bytewe,dat_write,sig_data_read,sig_mem_pause_in,
                       noddr_start,noddr_stop,
                       gpio_out,
                       gpioA_in(31 downto 14) => (others =>'0'),
                       gpioA_in(13) => btnR,
                       gpioA_in(12 downto 10) => sw,
                       gpioA_in(9 downto 0) => ACCEL_Y_OUT_sig);

ext_ram_code : RAM_CODE port map (clka => clk,
            wea => bytewe,
            addra => addr(14 downto 2),
            dina => dat_write,
            douta => sig_data_read
          );  
          
vga: VGA_640x480 port map(btnC,clk25,hs,vs,hc,vc,vid);

vga_prom: VGA_PROM_2 port map(hc,vc,vid,vgaRed,vgaGreen,vgaBlue,
           
           -- ball
           M_Ball,
           ball_ROM_ADDR,      
           ball_pos(19 downto 10) => pos_ball_lign, -- X
           ball_pos(9 downto 0) => pos_ball_col,-- ACC_Y
           
           -- obstacles
           M_obst => M_Obst,
           obst_ROM_ADDR => obst_ROM_ADDR,
           M_obst2 => M_Obst2,
           obst_ROM_ADDR2 => obst_ROM_ADDR2,
           obst_pos(19 downto 10) => pos_obst_lign, -- X
           obst_pos(9 downto 0) => pos_obst_col,-- Y
           obst2_pos(19 downto 10) => pos_obst2_lign, -- X
           obst2_pos(9 downto 0) => pos_obst2_col,-- Y
     
           -- Gameover
           M_gmov => M_gmov,
           gmov_ROM_ADDR => gmov_ROM_ADDR,
           Enable_GMOV =>gpio_out(31)
           );
       
accelero: AccelerometerCtl port map(
         clk,btnC,SCLK,MOSI,MISO,SS,
         ACCEL_X_OUT_sig,ACCEL_Y_OUT_sig,
         ACCEL_MAG_OUT_sig,ACCEL_TMP_OUT_sig);
         
segments : sSegDisplay port map(clk,
                        -- DIGIT 7
                        number(55 downto 49) => digit7_value,
                        -- DIGIT 6
                        number(48 downto 42) => digit6_value,
                        -- DIGIT 5
                        number(41 downto 35) => digit5_value,
                        -- DIGIT 4
                        number(34 downto 28) => digit4_value,
                        -- DIGIT 3
                        number(27 downto 21) => digit3_value,
                        -- DIGIT 2
                        number(20 downto 14) => digit2_value,
                        -- DIGIT 1 
                        number(13 downto 7) => digit1_value,
                        -- DIGIT 0                     
                        number(6 downto 0) => digit0_value,
                        seg => seg,
                        an => an);

rom_ball: PROM_Ball port map(clk25,ball_ROM_ADDR,M_Ball);
rom_obstacle: PROM_Obst port map(clk25,obst_ROM_ADDR,M_Obst,clk25,obst_ROM_ADDR2,M_Obst2);
rom_GAMEOVER: PROM_GMOV port map(clk25,gmov_ROM_ADDR,M_gmov);

-- 12 downto 10 : 000 pos ball col
--                001 pos ball line
--                011 pos obst1 col
--                010 pos obst2 col
--                110 pos obst1 line
--                100 pos obst2 line
-- 9 downto 0   : position value             
-- NOTE : POSITION IN GRAY CODE TO AVOID INTERMEDIATE STATE OF BITS
-- The cycle of position is according to the loop in software
demux_positions : process(gpio_out(12 downto 0))
begin
    if (gpio_out(12 downto 10) = "000") then   -- position ball column
        pos_ball_col    <= gpio_out(9 downto 0);
        pos_ball_lign   <= pos_ball_lign;
        pos_obst_col    <= pos_obst_col;
        pos_obst2_col   <= pos_obst2_col;
        pos_obst_lign   <= pos_obst_lign;
        pos_obst2_lign  <= pos_obst2_lign;

        
    elsif (gpio_out(12 downto 10) = "001") then   -- position ball line
        pos_ball_col    <= pos_ball_col;
        pos_ball_lign   <= gpio_out(9 downto 0);
        pos_obst_col    <= pos_obst_col;
        pos_obst2_col   <= pos_obst2_col;
        pos_obst_lign   <= pos_obst_lign;
        pos_obst2_lign  <= pos_obst2_lign;

    elsif (gpio_out(12 downto 10) = "011") then -- position obst column
        pos_ball_col    <= pos_ball_col;
        pos_ball_lign   <= pos_ball_lign;
        pos_obst_col    <= gpio_out(9 downto 0);
        pos_obst2_col   <= pos_obst2_col;
        pos_obst_lign   <= pos_obst_lign;
        pos_obst2_lign  <= pos_obst2_lign;
        
    elsif (gpio_out(12 downto 10) = "010") then -- position obst2 column
        pos_ball_col    <= pos_ball_col;
        pos_ball_lign   <= pos_ball_lign;
        pos_obst_col    <= pos_obst_col;
        pos_obst2_col   <= gpio_out(9 downto 0);
        pos_obst_lign   <= pos_obst_lign;
        pos_obst2_lign  <= pos_obst2_lign;
 
     elsif (gpio_out(12 downto 10) = "110") then -- position obst line
        pos_ball_col    <= pos_ball_col;
        pos_ball_lign   <= pos_ball_lign;
        pos_obst_col    <= pos_obst_col;
        pos_obst2_col   <= pos_obst2_col;
        pos_obst_lign   <= gpio_out(9 downto 0);
        pos_obst2_lign  <= pos_obst2_lign;
 
     elsif (gpio_out(12 downto 10) = "100") then -- position obst2 line
        pos_ball_col    <= pos_ball_col;
        pos_ball_lign   <= pos_ball_lign;
        pos_obst_col    <= pos_obst_col;
        pos_obst2_col   <= pos_obst2_col;
        pos_obst_lign   <= pos_obst_lign;
        pos_obst2_lign  <= gpio_out(9 downto 0);
     
    else -- none (avoid intermediate state !)
        pos_ball_col    <= pos_ball_col;
        pos_ball_lign   <= pos_ball_lign;
        pos_obst_col    <= pos_obst_col;
        pos_obst2_col   <= pos_obst2_col;
        pos_obst_lign   <= pos_obst_lign;
        pos_obst2_lign  <= pos_obst2_lign;
    end if;
end process;


-- 22 downto 20 : 000 digit 0
--                001 digit 1
--                011 digit 2
--                010 digit 3
--                110 digit 4
--                111 digit 5
--                101 digit 6
--                100 digit 7
-- 19 downto 13 : 7segments value
-- NOTE : POSITION IN GRAY CODE TO AVOID INTERMEDIATE STATE OF BITS
manage_7digits : process(gpio_out(22 downto 13))
begin
   if (gpio_out(22 downto 20) = "000") then      -- Digit 0
       digit7_value <= digit7_value;
       digit6_value <= digit6_value;
       digit5_value <= digit5_value;
       digit4_value <= digit4_value;
       digit3_value <= digit3_value;
       digit2_value <= digit2_value;
       digit1_value <= digit1_value;
       digit0_value <= gpio_out(19 downto 13);
       
   elsif (gpio_out(22 downto 20) = "001") then   -- Digit 1
       digit7_value <= digit7_value;
       digit6_value <= digit6_value;
       digit5_value <= digit5_value;
       digit4_value <= digit4_value;
       digit3_value <= digit3_value;
       digit2_value <= digit2_value;
       digit1_value <= gpio_out(19 downto 13);
       digit0_value <= digit0_value;
       
   elsif (gpio_out(22 downto 20) = "011") then   -- Digit 2
       digit7_value <= digit7_value;
       digit6_value <= digit6_value;
       digit5_value <= digit5_value;
       digit4_value <= digit4_value;
       digit3_value <= digit3_value;
       digit2_value <= gpio_out(19 downto 13);
       digit1_value <= digit1_value;
       digit0_value <= digit0_value;
       
   elsif (gpio_out(22 downto 20) = "010") then   -- Digit 3
       digit7_value <= digit7_value;
       digit6_value <= digit6_value;
       digit5_value <= digit5_value;
       digit4_value <= digit4_value;
       digit3_value <= gpio_out(19 downto 13);
       digit2_value <= digit2_value;
       digit1_value <= digit1_value;
       digit0_value <= digit0_value;
       
   elsif (gpio_out(22 downto 20) = "110") then   -- Digit 4
       digit7_value <= digit7_value;
       digit6_value <= digit6_value;
       digit5_value <= digit5_value;
       digit4_value <= gpio_out(19 downto 13);
       digit3_value <= digit3_value;
       digit2_value <= digit2_value;
       digit1_value <= digit1_value;
       digit0_value <= digit0_value;
   elsif (gpio_out(22 downto 20) = "111") then   -- Digit 5
       digit7_value <= digit7_value;
       digit6_value <= digit6_value;
       digit5_value <= gpio_out(19 downto 13);
       digit4_value <= digit4_value;
       digit3_value <= digit3_value;
       digit2_value <= digit2_value;
       digit1_value <= digit1_value;
       digit0_value <= digit0_value;
       
   elsif (gpio_out(22 downto 20) = "101") then   -- Digit 6
       digit7_value <= digit7_value;
       digit6_value <= gpio_out(19 downto 13);
       digit5_value <= digit5_value;
       digit4_value <= digit4_value;
       digit3_value <= digit3_value;
       digit2_value <= digit2_value;
       digit1_value <= digit1_value;
       digit0_value <= digit0_value;
   else                                          -- Digit 7
       digit7_value <= gpio_out(19 downto 13);
       digit6_value <= digit6_value;
       digit5_value <= digit5_value;
       digit4_value <= digit4_value;
       digit3_value <= digit3_value;
       digit2_value <= digit2_value;
       digit1_value <= digit1_value;
       digit0_value <= digit0_value;
   end if;
end process;   
      
led <= ACCEL_Y_OUT_sig;
end Behavioral;