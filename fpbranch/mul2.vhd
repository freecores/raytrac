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
use ieee.std_logic_arith.all;
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
--		clock 	: in std_logic;
		result	: out std_logic_vector ( 35 downto 0 )
	);
	end component;	

	signal s0sga,s0sgb,s0sg,s1sg,s0significandMSB:std_logic;
	signal s0exa,s0exb,s1ex:std_logic_vector(7 downto 0);
	signal s0ex : std_logic_vector(8 downto 0);
	signal s0uma,s0umb:std_logic_vector(16 downto 0);
	signal s0map:std_logic_vector(35 downto 0);
	signal s1map:std_logic_vector(24 downto 0);
	
begin

	process(clk)
	begin
	
		if clk'event and clk='1' then
			--! Registro de entrada
			s0sga <= a32(31);
			s0sgb <= b32(31);
			s0exa <= a32(30 downto 23);
			s0exb <= b32(30 downto 23);
			s0uma <= a32(22 downto 6);
			s0umb <= b32(22 downto 6);
			--! Etapa 0 multiplicacion de la mantissa, suma de los exponentes y multiplicaci&oacute;n de los signos.
			s1map <= s0map(35 downto 11);
			s1ex <= s0ex(7 downto 0);
			p32(31) <= s0sg;
			
						
		end if;
		
	end process;
	
	--! Combinatorial Gremlin
	mult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",0,"UNSIGNED","LPM_MULT",18,18,36)
	port 	map (s0significandMSB&s0uma,s0significandMSB&s0umb,s0map);
	
	process(s1map,s1ex)
	begin
		p32(30 downto 23) <=s1ex+s1map(24);
		if s1map(24)='1' then
			p32(22 downto 0) <= s1map(23 downto 1);
		else
			p32(22 downto 0) <= s1map(22 downto 0);
		end if;
					
	end process;
	
	
	process (s0sga,s0sgb,s0exa,s0exb,s0uma,s0umb)
		variable i8s0exa,i8s0exb: integer range 0 to 255;
	begin
		s0sg <= s0sga xor s0sgb;
		i8s0exa:=conv_integer(s0exa);
		i8s0exb:=conv_integer(s0exb);
		if i8s0exa = 0 or i8s0exb = 0  then
			s0ex <= (others => '0');
			s0significandMSB <= '0';
		else 
			s0significandMSB<='1';
			s0ex <= conv_std_logic_vector(i8s0exb+i8s0exa+129,9);
		end if;
	end process;
	
end mul2_arch;