------------------------------------------------
--! @file shift.vhd
--! @brief RayTrac TestBench
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------


-- RAYTRAC
-- Author Julian Andres Guarin
-- shift.vhd
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
--     along with raytrac.  If not, see <http://www.gnu.org/licenses/>
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_signed.all;
use ieee.math_real.all;


entity shifter is 
	generic (
		address_width	: integer	:= 9;
		width			: integer	:= 32;
		even_shifter	: string	:= "YES"	
		
	);
	port (
		data			: in std_logic_vector(width - 1 downto 0);
		exp				: out std_logic_vector(integer(ceil(log(real(width),2.0)))-1 downto 0);
		address 		: out std_logic_vector (address_width-1 downto 0);
		zero			: out std_logic
	);	
end shifter;

architecture shifter_arch of shifter is 

	-- signal datamask : std_logic_vector(width+address_width-1 downto 0);
begin
	-- datamask (width+address_width-1 downto address_width) <= data(width-1 downto 0);
	-- datamask (address_width-1 downto 0) <= (others=>'0');
	
	sanityLost:
	process (data)
		variable index: integer range-1 to width+address_width-1:=width+address_width-1;
		
	begin
		address<=(others=>'0');
		exp<=(others=>'0');
		
		zero<=data(0);
		
		if even_shifter="YES" then
			index:=width-1;
		else
			index:=width-2;
		end if;
		
		while index>=1 loop
			if data(index)='1' then
				zero<='0';
				exp<=CONV_STD_LOGIC_VECTOR(index, exp'high+1);
				if index>=address_width then
					address <= data (index-1 downto index-address_width);
				else
					address(address_width-1 downto address_width-index) <= data (index-1 downto 0);
					address(address_width-index-1 downto 0) <= (others =>'0');
				end if;
				exit;
			end if;
			index:=index-2; --Boost
		end loop;
		
		
		
		
	end process sanityLost;
	-- process (data)
	-- begin
		-- if data=0 then
			-- zero<='1';
		-- else
			-- zero<='0';
		-- end if;
	-- end process;
	
end shifter_arch;





		