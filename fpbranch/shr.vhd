------------------------------------------------
--! @file shr.vhd
--! @brief RayTrac Arithmetic Addition Substraction Mantissa B Normalizer Shifter 
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------


-- RAYTRAC (FP BRANCH)
-- Author Julian Andres Guarin
-- shr.vhd
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
use ieee.std_logic_unsigned.all;

use work.arithpack.all;


entity shr is
	
	port (
		clk,rst		: in std_logic;
		
		iexp		: in std_logic_vector (exponentWidth-1 downto 0);
		ismantissa	: in std_logic_vector (mantissaWidth+1 downto 0);
		oexp		: out std_logic_vector (exponentWidth-1 downto 0);
		osmantissa	: out std_logic_vector (mantissaWidth+1 downto 0);
		
		smantissb	: in std_logic_vector (mantissaWidth+1 downto 0);
		expshift	: in std_logic_vector (exponentWidth-1 downto 0);
		snmantissb	: out std_logic_vector (mantissaWidth+1 downto 0)
		
	);

end shr;


architecture shr_arch of shr is
	signal ssmb : std_logic_vector (mantissaWidth+1 downto 0);
	signal sshf : std_logic_vector (exponentWidth-1 downto 0);
begin

	--! Inpur Register
	process (clk,rst)
	begin
	
		if rst=rstMasterValue then
			
			oexp <= (others => '0');
			osmantissa <= (others => '0');
			ssmb <= (others => '0');
			sshf <= (others => '0');
			
		elsif clk'event and clk='1' then

			oexp <= iexp;
			osmantissa <= ismantissa;
			ssmb <= smantissb;
			sshf <= expshift; 
		
		end if;
	end process;


	--! Combinatorial Gremlin
	process (ssmb,sshf)
		variable expi : integer;
	begin
		expi:= conv_integer(sshf); --! Por qu'e hasta 1 y no hasta 0!? Porque el corrimiento de la raiz cuadrada es 2^(N/2)  
		
		for i in 10 to mantissaWidth+1 loop

			snmantissb(i)<=ssmb(ssmb'high);			
			if mantissaWidth+1>=i+expi then
				snmantissb(i)<=ssmb(i+expi);
			end if;
			

		end loop;

	end process;

end shr_arch; 

