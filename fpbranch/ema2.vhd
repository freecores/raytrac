------------------------------------------------
--! @file ema2.vhd
--! @brief RayTrac Exponent Managment Adder  
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------


-- RAYTRAC (FP BRANCH)
-- Author Julian Andres Guarin
-- ema2.vhd
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

--! Esta entidad recibe dos n&uacutemeros en formato punto flotante IEEE 754, de precision simple y devuelve las mantissas signadas y corridas, y el exponente correspondiente al resultado antes de normalizarlo al formato float. 
--!\nLas 2 mantissas y el exponente entran despues a la entidad add2 que suma las mantissas y entrega el resultado en formato IEEE 754.
entity ema2 is 
	port (
		clk			: in std_logic;
		a32,b32		: in std_logic_vector (31 downto 0);
		exp			: out std_logic_vector (7 downto 0);
		sma,smb		: out std_logic_vector (24 downto 0)
	);
end ema2;

architecture ema2_arch of ema2 is
	signal sa,sb,ssa,ssb,sssa,sssb,s4a		: std_logic_vector(31 downto 0);
	signal s4umb							: std_logic_vector(23 downto 0);
	signal s4sma,s4smb						: std_logic_vector(24 downto 0);								
	signal s4sgb,za,zb,ssz					: std_logic; 
begin

	process (clk)
	begin
		if clk'event and clk='1' then 
		
			--!Registro de entrada
			sa <= a32;
			sb <= b32;

			--!Primera etapa a vs. b
			if sa(30 downto 23) >= sb (30 downto 23) then
				--!signo,exponente,mantissa
				ssb(31) <= sb(31);
				ssb(30 downto 23) <= sa(30 downto 23)-sb(30 downto 23);
				ssb(22 downto 0) <= sb(22 downto 0);
				--! zero signaling
				ssz <= zb;
				--!clasifica a
				ssa <= sa;
				
			else
				--!signo,exponente,mantissa
				ssb(31) <= sa(31);
				ssb(30 downto 23) <= sb(30 downto 23)-sa(30 downto 23);
				ssb(22 downto 0) <= sa(22 downto 0);
				--! zero signaling
				ssz <= za;
				--!clasifica b
				ssa <= sb;
			end if;
			
			--! Tercera etapa corrimiento y normalizaci&oacute;n de mantissas  
			s4a <= ssa;
			s4sgb <= ssb(31);
			s4umb <= shr(ssz&ssb(22 downto 0),ssb(30 downto 23));
			
			--! Cuarta etapa signar la mantissa y entregar el exponente.
			sma <= s4sma + s4a(31);
			smb <= s4smb + s4sgb;
			exp <= s4a(30 downto 23);
		end if;
	end process;
	--! Combinatorial Gremlin
	
	--!Signar b y c
	signbc:
	for i in 23 downto 0 generate
		s4smb(i) <= s4sgb xor s4umb(i);
	end generate;
	s4smb(24) <= s4sgb;
	
	--!Signar a
	signa:
	for i in 22 downto 0 generate
		s4sma(i) <= s4a(31) xor s4a(i);
	end generate;
	s4sma(23) <= not(s4a(31));
	s4sma(24) <= s4a(31);	
	
	--! zero
	process (sb,sa)
	begin
		zb <='0';
		za <='0';
		for i in 30 downto 23 loop
			if sa(i)='1' then
				za <= '1';
			end if;
			if sb(i)='1' then
				zb <='1';
			end if;
			
		end loop;
	end process;
	
	
end ema2_arch;

		