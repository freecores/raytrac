--! @file clockgen.vhd
--! @brief Test bench clock generator.
--! @author Julian Andres Guarin Reyes.
-- RAYTRAC
-- Author Julian Andres Guarin
-- clockgen.vhd
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

entity clock_gen is
	generic	(tclk : time := 20 ns);
	port	(clk,rst : out std_logic);
end entity clock_gen;

architecture clock_gen_arch of clock_gen is

	constant 

begin
	resetproc: process
	begin
		rst<= '1';
		wait for 50 ns;
		rst<= '0';
		wait;
	end process;
	clockproc: process
	
		


