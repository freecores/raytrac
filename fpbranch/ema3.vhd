------------------------------------------------
--! @file ema3.vhd
--! @brief RayTrac Exponent Managment Adder  
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------


-- RAYTRAC (FP BRANCH)
-- Author Julian Andres Guarin
-- ema3.vhd
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
use ieee.std_logic_arith.all;


entity ema3 is 
	port (
		clk			: in std_logic;
		a32,b32,c32	: in std_logic_vector (31 downto 0);
		exp			: out std_logic_vector (7 downto 0);
		sma,smb,smc	: out std_logic_vector (24 downto 0)
		
						
	
	);
end ema3;

architecture ema3_arch of ema3 is
	signal sa,sb,sc,ssa,ssb,ssc,sssa,sssb,sssc,s4a	: std_logic_vector(31 downto 0);
	signal s4umb,s4umc								: std_logic_vector(23 downto 0);
	signal s4sma,s4smb,s4smc						: std_logic_vector(24 downto 0);								
	signal s4sgb,s4sgc								: std_logic; 
begin

	process (clk)
	begin
		if clk'event and clk='1' then 
		
			--!Registro de entrada
			sa <= a32;
			sb <= b32;
			sc <= c32;

			--!Primera etapa a vs. b
			if sa(30 downto 23) >= sb (30 downto 23) then
				--!signo,exponente,mantissa
				ssb(31) <= sb(31);
				ssb(30 downto 23) <= sb(30 downto 23);
				ssb(22 downto 0) <= sb(22 downto 0);
				--!clasifica a
				ssa <= sa;
			else
				--!signo,exponente,mantissa
				ssb(31) <= sa(31);
				ssb(30 downto 23) <= sa(30 downto 23);
				ssb(22 downto 0) <= sa(22 downto 0);
				--!clasifica b
				ssa <= sb;
			end if;
			ssc <= sc;
			
			--!Segunda Etapa, ganador de a/b vs c, resta de exponentes para saber cuanto se debe correr.
			if ssa(30 downto 23) >= ssc (30 downto 23) then
				--!signo,exponente,mantissa
				sssc(31) <= ssc(31);
				sssc(30 downto 23) <= ssa(30 downto 23)-ssc(30 downto 23);
				sssb(30 downto 23) <= ssa(30 downto 23)-ssb(30 downto 23);
				sssc(22 downto 0) <= ssc(22 downto 0);
				--!clasifica ganador de ab
				sssa <= ssa;
			else				
				--!signo,exponente,mantissa
				sssc(31) <= ssa(31);
				sssc(30 downto 23) <= ssc(30 downto 23)-ssa(30 downto 23);
				sssb(30 downto 23) <= ssc(30 downto 23)-ssb(30 downto 23);
				sssc(22 downto 0) <= ssa(22 downto 0);
				--!clasifica c
				sssa <= ssc;
			end if;
			sssb(31) <= ssb(31);
			sssb(22 downto 0) <= ssb(22 downto 0);
			
			--! Tercera etapa corrimiento y normalizaci&oacute;n de mantissas  
			s4a <= sssa;
			s4sgb <= sssb(31);
			s4sgc <= sssc(31);
			s4umb <= shr('1'&sssb(22 downto 0),sssb(30 downto 23));
			s4umc <= shr('1'&sssc(22 downto 0),sssc(30 downto 23)); 
			
			--! Cuarta etapa signar la mantissa y entregar el exponente.
			sma <= s4sma + s4a(31);
			smb <= s4smb + s4sgb;
			smc <= s4smc + s4sgc;
			exp <= s4a(30 downto 23);
		end if;
	end process;
	--! Combinatorial Gremlin
	
	--!Signar b y c
	signbc:
	for i in 23 downto 0 generate
		s4smb(i) <= s4sgb xor s4umb(i);
		s4smc(i) <= s4sgc xor s4umc(i);
	end generate;
	s4smb(24) <= s4sgb;
	s4smc(24) <= s4sgc;
	
	--!Signar a
	signa:
	for i in 22 downto 0 generate
		s4sma(i) <= s4a(31) xor s4a(i);
	end generate;
	s4sma(23) <= not(s4a(31));
	s4sma(24) <= s4a(31);	
	
	
end ema3_arch;

		