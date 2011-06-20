------------------------------------------------
--! @file mmp.vhd
--! @brief RayTrac Mantissa Multiplier  
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------


-- RAYTRAC (FP BRANCH)
-- Author Julian Andres Guarin
-- mmp.vhd
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
library lpm;
use lpm.all;

entity mul2 is
	port (
		clk 		: in std_logic;
		a32,b32		: in std_logic_vector(31 downto 0);
		p32			: out std_logic_vector(31 downto 0)
		
	);
end mul2;

architecture mul2_arch of mul2 is 
	signal s0sga,s0sgb:std_logic;
	signal s0exa,s0exb:std_logic_vector(7 downto 0);
	component lpm_mult 
	generic (
		lpm_hint			: string;
		lpm_pipeline		: natural;
		lpm_representation	: string;
		lpm_type			: string;
		lpm_widtha			: natural;
		lpm_widthb			: natural;
		lpm_widthp			: natural
	);
	port (
		dataa	: in std_logic_vector ( 17 downto 0 );
		datab	: in std_logic_vector ( 17 downto 0 );
		clock 	: in std_logic;
		result	: out std_logic_vector ( 35 downto 0 )
	);
	end component;	


begin

	
	

	process(clk,rst)
	begin
	
		if clk'event and clk='1' then
			--! Registro de entrada
			s0sga <= a32(31);
			s0sgb <= b32(31);
			s0exa <= a32(30 downto 23);
			s0exb <= b32(30 downto 23);
			
		end if;
	end process;
	
	--! Combinatorial Gremlin
	mult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",2,"UNSIGNED","LPM_MULT",18,18,36)
	port 	map ('1'&uma,'1'&umb,clk,sp);
	normadd <= sp(sp'high);
	process (sp,iexpadd)
	begin
	
		if sp(sp'high)='1' then
			mmp <= sp(sp'high-1 downto sp'high - (mantissaWidth));   
			oexpadd <= iexpadd+1;
		else
			mmp <= sp(sp'high downto sp'high - (mantissaWidth-1));   
			oexpadd <= iexpadd;
		end if;
	end process;
	
end mul2_arch;