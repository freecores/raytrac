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
	component lpm_mult 
	generic (
		lpm_hint			: string;
		lpm_representation	: string;
		lpm_type			: string;
		lpm_widtha			: natural;
		lpm_widthb			: natural;
		lpm_widthp			: natural
	);
	port (
		dataa	: in std_logic_vector ( lpm_widtha-1 downto 0 );
		datab	: in std_logic_vector ( lpm_widthb-1 downto 0 );
		result	: out std_logic_vector( lpm_widthp-1 downto 0 )
	);
	end component;	
	
	signal bss								: std_logic_vector(22 downto 0); -- Inversor de la mantissa
	signal sa,sb,ssa,ssb,sssa,sssb,s4a		: std_logic_vector(31 downto 0); -- Float 32 bit 
	signal s4umb							: std_logic_vector(23 downto 0); -- Unsigned mantissa
	signal s4sma,s4smb						: std_logic_vector(24 downto 0); -- Signed mantissas
	signal sspH,sspL						: std_logic_vector(35 downto 0); -- Shifter Product								
	signal s4sgb,zeroa,zerob,ssz			: std_logic; 
	
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
				ssz <= zerob;
				--!clasifica a
				ssa <= sa;
				
			else
				--!signo,exponente,mantissa
				ssb(31) <= sa(31);
				ssb(30 downto 23) <= sb(30 downto 23)-sa(30 downto 23);
				ssb(22 downto 0) <= sa(22 downto 0);
				--! zero signaling
				ssz <= zeroa;
				--!clasifica b
				ssa <= sb;
			end if;
			
			--! Segunda etapa corrimiento y denormalizaci&oacute;n de mantissas  
			s4a <= ssa;
			s4sgb <= ssb(31);
			
			for i in 17 downto 0 loop
				s4umb(i)  <= sspH(17-i) or sspL(23-i);
			end loop;
			for i in 23 downto 18 loop
				s4umb(i)  <= sspL(23-i);
			end loop;
			

			
			--! Tercera etapa signar la mantissa y entregar el exponente.
			sma <= s4sma + s4a(31);
			smb <= s4smb + s4sgb;
			exp <= s4a(30 downto 23);
		end if;
	end process;
	--! Combinatorial Gremlin
	highshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",18,18,36)
	port 	map (shl(conv_std_logic_vector(1,18),ssb(30 downto 23)),bss(22 downto 5),sspH);	
	lowshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",18,18,36)
	port 	map (shl(conv_std_logic_vector(1,18),ssb(30 downto 23)),conv_std_logic_vector(0,12)&bss(4 downto 0)&ssz,sspL);	

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
		zerob <='0';
		zeroa <='0';
		for i in 30 downto 23 loop
			if sa(i)='1' then
				zeroa <= '1';
			end if;
			if sb(i)='1' then
				zerob <='1';
			end if;
			
		end loop;
	end process;
	--! ssb2bssInversor de posicion 
	ssb2bss:
	for i in 22 downto 0 generate
		bss(i) <= ssb(22-i);
	end generate ssb2bss;
	
end ema2_arch;

		