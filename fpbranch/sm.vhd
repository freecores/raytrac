--! @file sm.vhd
--! @brief Bloque que le coloca signo a la mantissa 
--! @author Julián Andrés Guarín Reyes.
--------------------------------------------------------------
-- RAYTRAC (FP BRANCH)
-- Author Julian Andres Guarin
-- sm.vhd
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
use ieee.std_logic_unsigned.all;

use work.arithpack.all;




entity sm is
	port (
		clk,rst		: in std_logic;		
		umantissa	: in std_logic_vector	(mantissaWidth-1	downto	0);
		sign	 	: in std_logic;
		smantissa	: out std_logic_vector	(mantissaWidth 		downto	0)
	);
end entity;

architecture sm_arch of sm is
	signal sum		: std_logic_vector (mantissaWidth-1 downto 0);
	signal ss		: std_logic;
	signal ssm		: std_logic_vector (mantissaWidth+1 downto 0);
begin

	--! Input Register;	
	process (clk,rst)
	begin
		if rst=rstMasterValue then 
			sum <= (others => '0');
			ss <= '0';
		elsif clk'event and clk='1' then
			sum <= umantissa;
			ss <= sign;
		end if;
	end process;
	
	--! Combinatorial Gremlin
	xorsign:
	for i in mantissaWidth-1 downto 0 generate
		ssm(i) <= sum(i) xor ss;
	end generate;
	ssm(mantissaWidth) <= not ss;
	ssm(mantissaWidth+1)  <= ss;
	smantissa <= ssm+ss;
	
end sm_arch;

	
	
		