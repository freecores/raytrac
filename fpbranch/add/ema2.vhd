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
	signal s2slr										: std_logic_vector(1 downto 0); 
	signal s3lshift,s4lshift							: std_logic_vector(4 downto 0);
	signal s2exp,s3exp,s4exp							: std_logic_vector(7 downto 0);
	signal s4slab										: std_logic_vector(15 downto 0);
	signal s2slab										: std_logic_vector(16 downto 0);
	signal b1s,s4nrmP									: std_logic_vector(22 downto 0); -- Inversor de la mantissa
	signal s0a,s0b,s1a,s1b,sssa,sssb,s3a				: std_logic_vector(31 downto 0); -- Float 32 bit 
	signal s1sma,s2sma,s2smb,s3sma,s3smb,s3ures,s4ures	: std_logic_vector(24 downto 0); -- Signed mantissas
	signal s3res										: std_logic_vector(25 downto 0); -- Signed mantissa result
	signal s1pS,s1pH,s1pL,s4nrmL,s4nrmH,s4nrmS			: std_logic_vector(17 downto 0); -- Shifert Product
	signal s3sgb,s0zeroa,s0zerob,s1z,s4sgr				: std_logic; 
	
begin

	process (clk)
	begin
		if clk'event and clk='1' then 
		
			--!Registro de entrada
			s0a <= a32;
			s0b <= b32;

			--!Etapa 0,Escoger el mayor exponente que sera el resultado desnormalizado, calcula cuanto debe ser el corrimiento de la mantissa con menor exponente y reorganiza los operandos, si el mayor es b, intercambia las posici&oacute;n si el mayor es a las posiciones la mantiene. Zero check.
			if s0a(30 downto 23) >= s0b (30 downto 23) then
				--!signo,exponente,mantissa
				s1b(31) <= s0b(31);
				s1b(30 downto 23) <= s0a(30 downto 23)-s0b(30 downto 23);
				s1b(22 downto 0) <= s0b(22 downto 0);
				--! zero signaling
				s1z <= s0zerob;
				--!clasifica a
				s1a <= s0a;
				
			else
				--!signo,exponente,mantissa
				s1b(31) <= s0a(31);
				s1b(30 downto 23) <= s0b(30 downto 23)-s0a(30 downto 23);
				s1b(22 downto 0) <= s0a(22 downto 0);
				--! zero signaling
				s1z <= s0zeroa;
				--!clasifica b
				s1a <= s0b;
			end if;
			
			--! Etapa 1: Denormalizaci&oacute;n de las mantissas.  
			--! A
			s2exp <= s1a(30 downto 23);
			s2sma <= s1sma;
			
			--! B
			for i in 23 downto 15 loop
				s2smb(i)	<= s1pL(23-i) xor s1b(31);
			end loop;
			for i in 14 downto 6 loop
				s2smb(i) 	<= (s1pH(14-i) or s1pL(14-i+9)) xor s1b(31);
			end loop;			
			for i in 5 downto 0 loop
				s2smb(i) 	<= (s1pS(5-i) or s1pH(5-i+9)) xor s1b(31);
			end loop;
			 
			if s1b(30 downto 28)>"000" then
				s2slr <= "11";
			else
				s2slr <= s1b(27 downto 26);
			end if;
			
			s2smb(24) <= s1b(31);
			
			--! Etapa2: Finalizar la denormalizaci&oacute;n de b.
			--! A
			s3sma <= s2sma;		
			s3exp <= s2exp;
			
			--! B
			case (s2slr) is
				when "00" =>
					s3smb 	<= s2smb(24 downto 0)+s2smb(24);
				when "01" => 
					s3smb 	<= ( s2slab(8 downto 0) & s2smb(23 downto 8) ) + s2smb(24);
				when "10"  =>
					s3smb 	<= ( s2slab(16 downto 0) & s2smb(23 downto 16)) + s2smb(24);
				when others => 
					s3smb 	<= (others => '0');
			end case;  
				
			
			--! Etapa 3: Etapa 3 Realizar la suma, quitar el signo de la mantissa y codificar el corrimiento hacia la izquierda.
			s4ures	<= s3ures+s3res(25); 				--Resultado no signado
			s4sgr	<= s3res(25);						--Signo
			s4exp 	<= s3exp;							--Exponente 
			s4lshift <= s3lshift;						--Corrimiento hacia la izquierda. 
			
			--! Etapa 4: Corrimiento y normalizaci&oacute;n de la mantissa resultado.
			res32(31) <= s4sgr;
			if s4ures(24)='1' then 
				res32(22 downto 0) <= s4ures(23 downto 1);
				res32(30 downto 23) <= s4exp+1;
			else
				case s4lshift(4 downto 3) is
					when "00" => 
						res32(22 downto 0) 	<= s4nrmP(22 downto 0);
						res32(30 downto 23) <= s4exp - s4lshift;
					when "01" => 
						res32(22 downto 0) 	<= s4nrmP(14 downto 0)	& s4slab(7 downto 0);
						res32(30 downto 23) <= s4exp - s4lshift;
					when "10" => 
						res32(22 downto 0)	<= s4nrmP(6 downto 0)	& s4slab(15 downto 0);
						res32(30 downto 23) <= s4exp - s4lshift;  
					when others => 
						res32(30 downto 0) <= (others => '0');	
				end case;	
				
			end if;
		
		end if;
	end process;
	--! Combinatorial gremlin, Etapa 0, Escoger el mayor exponente que sera el resultado desnormalizado,\n 
	--! calcula cuanto debe ser el corrimiento de la mantissa con menor exponente y reorganiza los operandos,\n
	--! si el mayor es b, intercambia las posici&oacute;n si el mayor es a las posiciones la mantiene. Zero check.\n 
	process (s0b(30 downto 23),s0a(30 downto 23))
	begin
		s0zerob <='0';
		s0zeroa <='0';
		for i in 30 downto 23 loop
			if s0a(i)='1' then
				s0zeroa <= '1';
			end if;
			if s0b(i)='1' then
				s0zerob <='1';
			end if;
			
		end loop;
	end process;
	
	
	--! Combinatorial Gremlin, Etapa 1 Denormalizaci&oacute;n de las mantissas. 
	denormsupershiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port 	map ("00"&shl(conv_std_logic_vector(1,7),s1b(25 downto 23)),conv_std_logic_vector(0,3)&b1s(22 downto 17),s1pS);	
	denormhighshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port 	map ("00"&shl(conv_std_logic_vector(1,7),s1b(25 downto 23)),b1s(16 downto 8),s1pH);	
	denormlowshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port 	map ("00"&shl(conv_std_logic_vector(1,7),s1b(25 downto 23)),b1s(7 downto 0)&s1z,s1pL);	
	s1b2b1s:
	for i in 22 downto 0 generate
		b1s(i) <= s1b(22-i);
	end generate s1b2b1s;
	signa:
	for i in 22 downto 0 generate
		s1sma(i) <= s1a(31) xor s1a(i);
	end generate;
	s1sma(23) <= not(s1a(31));
	s1sma(24) <= s1a(31);	
	
	
	--! Combinatorial Gremlin, Etapa2: Finalizar la denormalizaci&oacute;n de b.
	s2signslab:
	for i in 16 downto 0 generate
		s2slab(i) <= s2smb(24);
	end generate s2signslab;
	
	--! Combinatorial Gremlin, Etapa 3 Realizar la suma, quitar el signo de la mantissa y codificar el corrimiento hacia la izquierda. 
	adder:sadd2
	port map (s3sma(24)&s3sma,s3smb(24)&s3smb,dpc,s3res);
	process(s3res)
		variable lshift : integer range 24 downto 0; 
	begin
		lshift:=24;
 
		for i in 0 to 23 loop
			s3ures(i) <= s3res(25) xor s3res(i);
			if (s3res(25) xor s3res(i))='1' then
				lshift:=23-i;
			end if;
		end loop;
		s3ures(24) <= s3res(24) xor s3res(25);  
		s3lshift <= conv_std_logic_vector(lshift,5);
	end process;	
	
	
	--! Combinatorial Gremlin, Etapa 4 corrimientos y normalizaci&oacute;n de la mantissa resultado.
	normsupershiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port 	map (shl(conv_std_logic_vector(1,9),s4lshift(2 downto 0)),s4ures(22 downto 14),s4nrmS);	
	normhighshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port 	map (shl(conv_std_logic_vector(1,9),s4lshift(2 downto 0)),s4ures(13 downto 5),s4nrmH);	
	normlowshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port 	map (shl(conv_std_logic_vector(1,9),s4lshift(2 downto 0)),s4ures(4 downto 0)&conv_std_logic_vector(0,4),s4nrmL);
	process (s4nrmS,s4nrmH,s4nrmL)
	begin 
		s4nrmP(22 downto 14) <= s4nrmS(8 downto 0) or s4nrmH(17 downto 9);
		s4nrmP(13 downto 5) <= s4nrmH(8 downto 0) or s4nrmL(17 downto 9);
		s4nrmP(4 downto 0) <= s4nrmL(8 downto 4);
	end process;
	s4signslab:
	for i in 15 downto 0 generate
		s4slab(i) <= '0';
	end generate s4signslab;
end ema2_arch;

		