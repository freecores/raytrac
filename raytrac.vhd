-- RAYTRAC
-- Author Julian Andres Guarin
-- raytrac.vhd
-- This file is part of raytrac.
-- 
--     raytrac is free software: you can redistribute it and/or modify
--     it under the terms of the GNU General Public License as published by
--     the Free Software Foundation, either version 3 of the License, or
--     (at your option) any later version.
-- 
--     raytrac is distributed in the hope that it will be useful,
--     but WITHOUT ANY WARRANTY; without even the implied warranty of
--     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--     GNU General Public License for more details.
-- 
--     You should have received a copy of the GNU General Public License
--     along with raytrac.  If not, see <http://www.gnu.org/licenses/>.

library ieee;
use ieee.std_logic_1164.all;
use work.arithpack.all;



entity raytrac is 
	generic (
		registered : string := "NO"
	);
	port (
		A,B,C,D 		: in std_logic_vector(18*3-1 downto 0);
		opcode,addcode	: in std_logic;
		clk,rst,ena		: in std_logic;
		CPX,CPY,CPZ,DP0,DP1 : out std_logic_vector(31 downto 0)
		
		
	);
end raytrac;

architecture raytrac_arch of raytrac is 
	signal SA,SB,SC,SD			: std_logic_vector(18*3-1 downto 0);
	signal sopcode,saddcode		: std_logic;
	signal smf00,smf01,smf10,smf11,smf20,smf21,smf30,smf31,smf40,smf41,smf50,smf51	: std_logic_vector(17 downto 0);
	
begin

	-- Registered or unregistered inputs?
	notreg:
	if registered="NO" generate 
		SA <= A;
		SB <= B;
		SC <= C;
		SD <= D;
		sopcode <= opcode;
		saddcode <= addcode;
	end generate notreg;
	reg:
	if registered="YES" generate
		procReg:
		process(clk,rst)
		begin
			if rst=rstMasterValue then 
				SA <= (others => '0');
				SB <= (others => '0');
				SC <= (others => '0');
				SD <= (others => '0');
				sopcode <= '0';
				saddcode <= '0';
			elsif clk'event and clk='1' then
				if ena <= '1' then
					SA <= A;
					SB <= B;
					SC <= C;
					SD <= D;
					sopcode <= opcode;
					saddcode <= addcode;
				end if;
			end if;
		end process procReg;
	end generate reg;
	-- Instantiate Opcoder 
	opcdr : opcoder
	port map (
		SA(17 downto 0),SB(17 downto 0),SC(17 downto 0),SD(17 downto 0),SA(35 downto 18),SB(35 downto 18),SC(35 downto 18),SD(35 downto 18),SA(53 downto 36),SB(53 downto 36),SC(53 downto 36),SD(53 downto 36),
		smf00,smf01,smf10,smf11,smf20,smf21,smf30,smf31,smf40,smf41,smf50,smf51,
		sopcode,saddcode
	);
	-- Instantiate uf, cross product and dot product functional unit.
	uf0 : uf 
	port map (
		sopcode,
		smf00,smf01,smf10,smf11,smf20,smf21,smf30,smf31,smf40,smf41,smf50,smf51,
		CPX,CPY,CPZ,DP0,DP1,
		clk,rst
	);

end raytrac_arch;

		
		 