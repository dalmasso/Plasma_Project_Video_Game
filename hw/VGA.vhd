----------------------------------------------------------------------------------
-- Company: Polytech / LIRMM
-- Engineer: Pascal Benoit
-- 
-- Create Date:    14:53:00 07/11/2014 
-- Design Name: 
-- Module Name:    clkdiv - Behavioral 
-- Project Name:  VGA_Nexys3
-- Target Devices: Spartan6 SLX16
-- Tool versions: ISE 14.4
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
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity VGA_640x480 is
    Port ( rst : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           hsync : out  STD_LOGIC;
           vsync : out  STD_LOGIC;
           hc : out  STD_LOGIC_VECTOR (9 downto 0);
           vc : out  STD_LOGIC_VECTOR (9 downto 0);
           vidon : out  STD_LOGIC);
end VGA_640x480;

architecture Behavioral of VGA_640x480 is

constant hpixels: std_logic_vector(9 downto 0)	:= "1100100000"; -- nombre de pixels sur une ligne = 800
constant vlines: std_logic_vector(9 downto 0)	:= "1000001001"; -- nombre de lignes horizontales dans l'affichage = 521
constant hbp: std_logic_vector(9 downto 0)		:= "0010010000"; -- horizontal back porch = 128 + 16 = 144 ou 96 + 48
constant hfp: std_logic_vector(9 downto 0)		:= "1100010000"; -- horizontal front porch = 128 + 16 + 640 = 784
constant vbp: std_logic_vector(9 downto 0)		:= "0000011111"; -- vertical back porch = 2 + 29 = 31
constant vfp: std_logic_vector(9 downto 0)		:= "0111111111"; -- vertical front porch = 2 + 29 + 480 = 511

signal hcs, vcs: std_logic_vector(9 downto 0); -- compteurs horizontal / vertical
signal vsenable: std_logic; -- enable pour le compteur vertical

begin
------------------------------------------------------------
-- Compteur pour le signal de synchronisation horizontale
------------------------------------------------------------
process(clk, rst)
begin
if rst='1' then hcs <= (others =>'0');
elsif rising_edge(clk) then
	if hcs = hpixels - 1 then
		hcs <= (others =>'0');
		vsenable <= '1';
	else
		hcs <= hcs + 1;
		vsenable <= '0';
	end if;
end if;
end process;
------------------------------------------------------------

------------------------------------------------------------
-- Compteur pour le signal de synchronisation verticale
------------------------------------------------------------
process(clk, rst)
begin
if rst='1' then vcs <= (others =>'0');
elsif rising_edge(clk) then
	if vsenable = '1' then
		if vcs = vlines - 1 then
			vcs <= (others =>'0');
		else
			vcs <= vcs + 1;
		end if;
	end if;
end if;
end process;

------------------------------------------------------------
-- GENERATION DES SIGNAUX DE SORTIE
------------------------------------------------------------
hsync <= '0' when hcs < 96 else '1';
vsync <= '0' when vcs < 2 else '1';

vidon <= '1' when ( ((hcs < hfp) and (hcs>= hbp)) and ((vcs < vfp) and (vcs >= vbp)) ) else '0';
	
hc <= hcs;
vc <= vcs;

end Behavioral;
