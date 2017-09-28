------------------------------------------------------------------------
-- Engineer:		Dalmasso Loïc
-- Create Date:	09:28:37 10/11/2016
-- Module Name:	Clkgen - Behavioral
-- Description:
--		Generate clock signal from input clock master with user divide
--		Minimum clk/2
--		WARNING : generated frequence is about Clk USER (error rate)
------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Clkgen is
	 generic ( 	SYS_CLK	: integer := 100000000;	-- Clk Master
					USER_CLK : integer := 25000000		-- Clk User
				);
				
    Port ( clk_in : in  STD_LOGIC;
           rst_in : in  STD_LOGIC;
           clk_out : out  STD_LOGIC
			 );
end Clkgen;

architecture Behavioral of Clkgen is

------------------------------------------------------------------------
-- Constants Declarations
------------------------------------------------------------------------
constant DIVIDER : integer := (SYS_CLK/(USER_CLK*2))-1;

------------------------------------------------------------------------
-- Signal Declarations
------------------------------------------------------------------------
-- Counter divider
signal cpt : integer range 0 to DIVIDER := 0;

-- signal clk output temp to divide
signal clk_out_temp : std_logic := '0';


------------------------------------------------------------------------
-- Module Implementation
------------------------------------------------------------------------
begin
	
	-- Divide clk_in
	process(clk_in,rst_in)
	begin
		if rst_in = '1' then
			cpt <= 0;
			clk_out_temp <= '0';
			
		elsif rising_edge(clk_in) then
			cpt <= cpt+1;
			
			if cpt = DIVIDER then
				cpt <= 0;
				clk_out_temp <= not clk_out_temp;
			end if;
		end if;
	end process;

-- Generate output clock
clk_out <= clk_out_temp;

end Behavioral;