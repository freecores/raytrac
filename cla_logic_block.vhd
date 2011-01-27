-- RAYTRAC
-- Author Julian Andres Guarin
-- cla_logic_block.vhd
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
--     along with raytrac.  If not, see <http://www.gnu.org/licenses/>.library ieee;

-- Check out arithpack.vhd to understand in general terms what this file describes,
-- or checkout this file to check in detailed way what this file intends to.

use ieee.std_logic_1164.all;
entity cla_logic_block is
	generic (
		w : integer := 4							-- Carry Look Ahead Block Default Size 
	);

	port (
		p,g : in std_logic_vector(w-1 downto 0);	-- Propagation and Generation Inputs
		cin : in std_logic;							-- Carry In input
		
		c : out std_logic_vector(w downto 1)		-- Generated Carry Out outputs
	);
end cla_logic_block;


architecture cla_logic_block_arch of cla_logic_block is

	

begin

	claProc:	-- claProc instancia funciones combinatorias en las variables iCarry,
			-- pero notese que los valores de iCarry(i) no dependen jamas de iCarry(i-1) a diferencia de rcaProc
	process(p,g,cin)

		variable i,j,k :	integer range 0 to w;				-- Variables de control de loop
		variable iCarry:	std_logic_vector(w downto 1);			-- Carry Interno
		variable iResults:	std_logic_vector(((w+w**2)/2)-1 downto 0);	-- Resultados intermedios			
		variable index:		integer;
	begin

		iCarry(w downto 1) := g(w-1 downto 0);
		index := 0; 
		for j in 0 to w-1 loop
			for i in 1 to j+1 loop
				iResults(index) := '1'; 
				for k in j-i+1 to j loop
					iResults(index) := iResults(index) and p(k);
				end loop;
				if j>=i then
					iResults(index) := iResults(index) and g(j-i);
				else
					iResults(index) := iResults(index) and cin;
				end if;
				iCarry(j+1) := iCarry(j+1) or iResults(index);
				index := index + 1;
			end loop;  	  		 			

			c(j+1) <= iCarry(j+1);	

		end loop;

		
		
	end process claProc;

	

end cla_logic_block_arch;

