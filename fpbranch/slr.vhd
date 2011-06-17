--! @file slr.vhd
--! @brief Bloque para seleccionar cual de las mantissas se debe correr a la derecha. 
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


use work.arithpack.all;


entity slr is 
	port (
		clk,rst				: in std_logic;
		iexpsub,iexpshift	: in std_logic_vector (exponentWidth-1 downto 0);
		iexpsum				: in std_logic_vector (exponentWidth-1 downto 0);
		ge					: in std_logic;
		smantissa			: in std_logic_vector (mantissaWidth+1 downto 0);
		smantissb			: in std_logic_vector (mantissaWidth+1 downto 0);
		mantissA			: out std_logic_vector (mantissaWidth+1 downto 0);
		mantissB			: out std_logic_vector (mantissaWidth+1 downto 0);
		oexpsub,oexpshift	: out std_logic_vector (exponentWidth-1 downto 0);
		oexpsum				: out std_loigc_vector (exponentWidth-1 downto 0)
	);
end entity;

architecture slr_arch of slr is 
		signal ssma,ssmb		: std_logic_vector (mantissaWidth+1 downto 0);
		signal snotSwap			: std_logic;
begin
	--! Input Register
	process (clk,rst)
	begin
		if rst=rstMasterValue then
			ssma <= (others => '0');
			ssmb <= (others => '0');
			snotSwap <= '0';
			oexpsub <= (others => '0');
			oexpshift <= (others => '0');
			oexpsum <= (others => '0');
		elsif clk'event and clk='1' then
			ssma <= smantissa;
			ssmb <= smantissb;
			snotSwap <= ge;
			oexpsub <= iexpsub;
			oexpsum <= iexpsum;
			oexpshift <= iexpshift;
		end if;
	end process;
	
	--! Combinatorial Gremlin
	process (ssma,ssmb,snotSwap)
	begin
		
		if snotSwap='1' then 
			mantissA <= ssma;
			mantissB <= ssmb;
		else
			mantissA <= ssmb;
			mantissB <= ssma;
		end if;	
	end process;

end slr_arch;