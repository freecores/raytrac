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
		clk,dpc		: in std_logic;
		a32,b32		: in std_logic_vector (31 downto 0);
		res32		: out std_logic_vector(31 downto 0)
	);
end ema2;

architecture ema2_arch of ema2 is
	component sadd2 
	port (
		a,b:in std_logic_vector(25 downto 0);
		dpc:in std_logic;
		res:out std_logic_vector(25 downto 0)
	);
	end component;
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
	signal s4lshift,s5lshift						: std_logic_vector (4 downto 0);
	signal sexp,s5exp								: std_logic_vector (7 downto 0);
	signal bss										: std_logic_vector(22 downto 0); -- Inversor de la mantissa
	signal sa,sb,ssa,ssb,sssa,sssb,s4a				: std_logic_vector(31 downto 0); -- Float 32 bit 
	signal s4umb									: std_logic_vector(23 downto 0); -- Unsigned mantissa
	signal s4sma,s4smb,ssma,ssmb,s4ures,s5ures		: std_logic_vector(24 downto 0); -- Signed mantissas
	signal s4res									: std_logic_vector(25 downto 0); -- Signed mantissa result
	signal sspH,sspL,s5nrmL,s5nrmH					: std_logic_vector(35 downto 0); -- Shifter Product								
	signal s4sgb,zeroa,zerob,ssz,s5sgr,s4zero		: std_logic; 
	
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
			

			
			--! Tercera etapa signar la mantissa y entregar el exponente. Obteniendo el numero denormalizado
			ssma <= s4sma + s4a(31);
			ssmb <= s4smb + s4sgb;
			sexp <= s4a(30 downto 23);
			
			--! Cuarta etapa suma/resta de mantissas denormalizadas y quitar el signo al resultado.
			s5ures <= s4ures(24 downto 0)+s4res(25);
			s5sgr  <= s4res(25);
			for i in 7 downto 0 loop
				s5exp(i) <= sexp(i) and s4zero;
			end loop;
			s5lshift <= s4lshift;
			
			--! Quinta etapa corrimientos y normalizaci&oacute;n de mantissas y entrega de resultado.
			res32(31) <= s5sgr;
			if s5ures(24)='1' then 
				res32(22 downto 0) <= s5ures(23 downto 1);
				res32(30 downto 23) <= s5exp+1;
			else
				for i in 22 downto 5 loop
					res32(i) <= s5nrmL(i) or s5nrmH(i-5);
				end loop;
				for i in 4 downto 0 loop
					res32(i) <= s5nrmL(i);
				end loop;
				res32(30 downto 23) <= s5exp - ("000"&s5lshift);
			end if;
			
			
			
		
		
		
		end if;
	end process;
	--! Combinatorial Gremlin
	denormhighshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",18,18,36)
	port 	map (shl(conv_std_logic_vector(1,18),ssb(30 downto 23)),bss(22 downto 5),sspH);	
	denormlowshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",18,18,36)
	port 	map (shl(conv_std_logic_vector(1,18),ssb(30 downto 23)),conv_std_logic_vector(0,12)&bss(4 downto 0)&ssz,sspL);	
--! Combinatorial Gremlin
	normhighshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",18,18,36)
	port 	map (shl(conv_std_logic_vector(1,18),s5lshift),s5ures(22 downto 5),s5nrmH);	
	normlowshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",18,18,36)
	port 	map (shl(conv_std_logic_vector(1,18),s5lshift),conv_std_logic_vector(0,13)&s5ures(4 downto 0),s5nrmL);
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
	
	
	--! Realizar la suma, quitar el signo de la mantissa y codificar el corrimiento hacia la izquierda. 
	adder:sadd2
	port map (ssma(24)&ssma,ssmb(24)&ssmb,dpc,s4res);
	process(s4res)
		variable lshift : integer range 23 downto 0; 
	begin
		lshift:=0;
		s4zero <= '0'; 
		for i in 0 to 23 loop
			s4ures(i) <= s4res(25) xor s4res(i);
			if (s4res(25) xor s4res(i))='1' then
				lshift:=23-i;
				s4zero <= '1';
			end if;
		end loop;
		s4ures(24) <= s4res(24) xor s4res(25);  
		s4lshift <= conv_std_logic_vector(lshift,5);
	end process;	
	
	
end ema2_arch;

		