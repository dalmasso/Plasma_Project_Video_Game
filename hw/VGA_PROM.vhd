----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 25.02.2017 17:11:27
-- Design Name: 
-- Module Name: VGA_PROM - Behavioral
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

entity VGA_PROM_2 is
    Port ( hc : in STD_LOGIC_VECTOR (9 downto 0);
           vc : in STD_LOGIC_VECTOR (9 downto 0);
           vidon : in STD_LOGIC;
           RED : out STD_LOGIC_VECTOR (3 downto 0);
           GREEN : out STD_LOGIC_VECTOR (3 downto 0);
           BLUE : out STD_LOGIC_VECTOR (3 downto 0);
           
           -- Ball (! X Y inv !)
           M_ball : in std_logic_vector (11 DOWNTO 0);
           ball_ROM_ADDR : out std_logic_vector (9 downto 0);
           ball_pos : in STD_LOGIC_Vector (19 downto 0); -- X(19-10) ACC_Y(9-0)
           
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
end VGA_PROM_2;

architecture Behavioral of VGA_PROM_2 is

-- Screen
constant hbp : std_logic_vector (9 downto 0) := "0010010000"; --144
constant vbp : std_logic_vector (9 downto 0) := "0000011111"; --31
signal R,G,B : std_logic;

-- Ball
constant w_ball : std_logic_vector (9 downto 0) := "0000100000" ; --32 
constant h_ball : std_logic_vector (9 downto 0) := "0000100000" ; --32
signal spriteon_ball : std_logic;
signal ball_xpix, ball_ypix : std_logic_vector (9 downto 0);

-- Obstacle 1
constant w_obst : std_logic_vector (9 downto 0) := "0001001111" ; --79
constant h_obst : std_logic_vector (9 downto 0) := "0000011101" ; --29
signal spriteon_obst : std_logic;
signal obst_xpix, obst_ypix : std_logic_vector (9 downto 0);

-- Obstacle 2
signal spriteon_obst2 : std_logic;
signal obst2_xpix, obst2_ypix : std_logic_vector (9 downto 0);

-- Game Over
constant w_gameov : std_logic_vector (9 downto 0) := "0110011100" ; --412
constant h_gameov : std_logic_vector (9 downto 0) := "0010000100" ; --132
constant lign_gameov : std_logic_vector (9 downto 0) := "0010101110" ; --174
constant col_gameov : std_logic_vector (9 downto 0) := "0001101000" ; --102
signal spriteon_gameov : std_logic;
signal gameov_xpix, gameov_ypix : std_logic_vector (9 downto 0);

begin
--------------------------------------------------------------
-- Ball Control
--------------------------------------------------------------
ball_ypix <= vc - vbp - ball_pos(19 downto 10);
ball_xpix <= hc - hbp - ball_pos(9 downto 0);

adrr_ball : process(ball_ypix,ball_xpix)
variable addr1,addr2: std_logic_vector(14 downto 0);
begin
    addr1 := (ball_ypix &"00000");  -- *32 = 0010 0000
    addr2 := addr1 + ("00000" & ball_xpix);   
    ball_ROM_ADDR <= addr2(9 downto 0)+1; -- +1 to avoid first column error display
end process;

sprite_ball : process(vc,hc,ball_pos)
begin
    if (hbp+ball_pos(9 downto 0) <= hc) and (hc < hbp + w_ball + ball_pos(9 downto 0)) and (vbp + ball_pos(19 downto 10) <= vc) and (vc < vbp + h_ball + ball_pos(19 downto 10)) then
        spriteon_ball <= '1';
     else 
        spriteon_ball <= '0';
     end if;
end process;

--------------------------------------------------------------
-- Obstacle 1 Control
--------------------------------------------------------------
obst_ypix <= vc - vbp - obst_pos(19 downto 10);
obst_xpix <= hc - hbp - obst_pos(9 downto 0);

adrr_obst : process(obst_ypix,obst_xpix)
variable addr1,addr2: std_logic_vector(15 downto 0);
begin
    addr1 := (obst_ypix &"000000") + ("000"&obst_ypix &"000") + ("0000"&obst_ypix &"00") + ("00000"&obst_ypix &"0") + ("000000"&obst_ypix); -- *79 = 0100 1111
    addr2 := addr1 + ("000000" & obst_xpix);   
    obst_ROM_ADDR <= addr2(11 downto 0)+1;-- +1 to avoid first column error display
end process;

sprite_obst : process(vc,hc,obst_pos)
begin
    if (hbp+obst_pos(9 downto 0) <= hc) and (hc < hbp + w_obst + obst_pos(9 downto 0)) and (vbp + obst_pos(19 downto 10) <= vc) and (vc < vbp + h_obst + obst_pos(19 downto 10)) then
        spriteon_obst <= '1';
     else 
        spriteon_obst <= '0';
     end if;
end process;

--------------------------------------------------------------
-- Obstacle 2 Control
--------------------------------------------------------------
obst2_ypix <= vc - vbp - obst2_pos(19 downto 10);
obst2_xpix <= hc - hbp - obst2_pos(9 downto 0);

adrr_obst2 : process(obst2_ypix,obst2_xpix)
variable addr1,addr2: std_logic_vector(15 downto 0);
begin
    addr1 := (obst2_ypix &"000000") + ("000"&obst2_ypix &"000") + ("0000"&obst2_ypix &"00") + ("00000"&obst2_ypix &"0") + ("000000"&obst2_ypix); -- *79 = 0100 1111
    addr2 := addr1 + ("000000" & obst2_xpix);   
    obst_ROM_ADDR2 <= addr2(11 downto 0)+1;-- +1 to avoid first column error display
end process;

sprite_obst2 : process(vc,hc,obst2_pos)
begin
    if (hbp+obst2_pos(9 downto 0) <= hc) and (hc < hbp + w_obst + obst2_pos(9 downto 0)) and (vbp + obst2_pos(19 downto 10) <= vc) and (vc < vbp + h_obst + obst2_pos(19 downto 10)) then
        spriteon_obst2 <= '1';
     else 
        spriteon_obst2 <= '0';
     end if;
end process;


--------------------------------------------------------------
-- GAME OVER Control
--------------------------------------------------------------
gameov_ypix <= vc - vbp - lign_gameov;
gameov_xpix <= hc - hbp - col_gameov;

adrr_gmov : process(gameov_ypix,gameov_xpix)
variable addr1,addr2: std_logic_vector(17 downto 0);
begin
    addr1 := (gameov_ypix &"00000000") + ('0'& gameov_ypix &"0000000") +  ("0000"& gameov_ypix &"0000") + ("00000"& gameov_ypix &"000") + ("000000"& gameov_ypix &"00"); -- *412 = 0001 1001 1100
    addr2 := addr1 + ("00000000" & gameov_xpix);   
    gmov_ROM_ADDR <= addr2(15 downto 0)+1;-- +1 to avoid first column error display
end process;

sprite_gmov : process(vc,hc,Enable_GMOV)
begin
    if (Enable_GMOV = '1') and ((hbp+col_gameov) <= hc) and (hc < hbp + w_gameov + col_gameov) and (vbp + lign_gameov <= vc) and (vc < vbp + h_gameov + lign_gameov) then
        spriteon_gameov <= '1';
     else 
        spriteon_gameov <= '0';
     end if;
end process;

--------------------------------------------------------------
-- Display Control
--------------------------------------------------------------
display : process (M_ball,M_obst,M_gmov,spriteon_ball,spriteon_obst,spriteon_gameov,vidon)
begin
  if vidon='1' then
     
     -- Display ball (priority highest)
     if spriteon_ball ='1' then
         RED <= M_ball(11 downto 8);
         GREEN <= M_ball(7 downto 4);
         BLUE <= M_ball(3 downto 0);

     -- Display Game Over (priority highest -1)
     elsif spriteon_gameov ='1' then
         RED <= M_gmov(11 downto 8);
         GREEN <= M_gmov(7 downto 4);
         BLUE <= M_gmov(3 downto 0);

     -- Display obstacle1  (priority highest -2)
     elsif spriteon_obst ='1' then
         RED <= M_obst(11 downto 8);
         GREEN <= M_obst(7 downto 4);
         BLUE <= M_obst(3 downto 0);

     -- Display obstacle2  (priority highest -3)
     elsif spriteon_obst2 ='1' then
         RED <= M_obst2(11 downto 8);
         GREEN <= M_obst2(7 downto 4);
         BLUE <= M_obst2(3 downto 0);
         
    -- Display background (priority lowest)
     else
        RED <="0110";
        GREEN <="0110";
        BLUE <="0110";
    end if;
    
  else
     RED <="0000";
     GREEN <="0000";
     BLUE <="0000";
  end if;
end process;

end Behavioral;