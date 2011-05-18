---------------------------------
--! @file exposelector.vhd
--! @brief This file selects the biggest 
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------


-- EXPOSELECTOR
-- Author Julian Andres Guarin
-- exposelector.vhd
-- This file is part of raytrac
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
use ieee.math_real.all;


--! 



entity exposelector is 

	generic (
		width			: integer := 32
	
	);

	port (
		
		exp0, exp1	:	in	std_logic_vector (integer(ceil(log(real(width),2.0)))-1 downto 0);
		expout		:	out std_logic
	);
end exposelector;

architecture exposelector_arch of exposelector 

begin

	galileo:
	process (exp0,exp1,addin)
	begin
		if exp0>exp1 then
			expout <= exp0(0);
		else
			expout <= exp1(0);
		end if;
	end process galileo;
end  exposelector_arch;

			 		
		