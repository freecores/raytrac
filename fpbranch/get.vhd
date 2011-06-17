--! @file get.vhd
--! @brief Bloque para comparar los exponentes y seleccionar el mayor 
--! @author Julián Andrés Guarín Reyes.
--------------------------------------------------------------
-- RAYTRAC (FP BRANCH)
-- Author Julian Andres Guarin
-- get.vhd
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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use work.arithpack.all;




entity get is
	port (
		clk,rst		: in std_logic;		
		expa,expb	: in std_logic_vector	(exponentWidth-1	downto	0);
		expshift	: out std_logic_vector  (exponentWidth-1 	downto  0);
		expsub			: out std_logic_vector	(exponentWidth-1 	downto 	0);
		expsum		: out std_logic_vector	(exponentWidth-1	downto  0);
		ge			: out std_logic
	
	);
end entity;

architecture get_arch of get is
	signal sexpa,sexpb : std_logic_vector	(exponentWidth-1 downto 0);  
begin
	--! Input Register
	process (clk,rst)
	begin 
		if rst=rstMasterValue then
			sexpa <= (others => '0');
			sexpb <= (others => '0');
		elsif clk'event and clk='1' then
			sexpa <= expa;
			sexpb <= expb;
		end if;
	end process;
	
	--! Combinatorial Gremlin
	process (sexpa,sexpb)
	
		variable sum : integer range 0 to 511;  
	
	begin
		sum := conv_integer(sexpa)+conv_integer(sexpb)-fpExponentBias;
		expsum <= conv_std_logic_vector(sum,exponentWidth);
		if sexpa >= sexpb then
			ge <= '1';
			expshift <= sexpa-sexpb;
			expsub <= sexpa+conv_std_logic_vector(fpExponentBias,exponentWidth);
		else
			ge <= '0';
			expshift <= sexpb-sexpa;
			expsub <= sexpb+conv_std_logic_vector(fpExponentBias,exponentWidth);
		end if;
	end process;
	
	
end get_arch;
	