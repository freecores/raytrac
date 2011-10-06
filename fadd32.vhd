------------------------------------------------
--! @file fadd32.vhd
--! @brief RayTrac Floating Point Adder  
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------


-- RAYTRAC (FP BRANCH)
-- Author Julian Andres Guarin
-- fadd32.vhd
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
--! Esta entidad recibe dos n&uacutemeros en formato punto flotante IEEE 754, de precision simple y devuelve las mantissas signadas y corridas, y el exponente correspondiente al resultado antes de normalizarlo al formato float. 
--!\nLas 2 mantissas y el exponente entran despues a la entidad add2 que suma las mantissas y entrega el resultado en formato IEEE 754.
entity fadd32 is
	generic (
		propagation_chain : string := "ON"
	); 
	port (
		clk,dpc,prop_in	: in std_logic;
		a32,b32		: in std_logic_vector (31 downto 0);
		c32,prop_out		: out std_logic_vector(31 downto 0)
	);
end fadd32;
architecture fadd32_arch of fadd32 is
	
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
	
	signal s1zero,s5tokena,s5tokenb,s5tokenc,s7sign											: std_logic;
	signal s5token																		: std_logic_vector(2 downto 0);
	signal s1delta																		: std_logic_vector(5 downto 0);
	signal s0delta,s1exp,s2exp,s3exp,s4exp,s5exp,s6exp,s5factor,s6factor,s7exp,s7factor	: std_logic_vector(7 downto 0);
	signal s1shifter,s5factorhot9,s6factorhot9											: std_logic_vector(8 downto 0);
	signal s1pl,s6pl																	: std_logic_vector(17 downto 0);
	signal s6postshift,s7postshift														: std_logic_vector(22 downto 0);
	signal s1umantshift,s1umantfixed,s1postshift,s1xorslab,s2xorslab					: std_logic_vector(23 downto 0);
	signal s5factorhot24																: std_logic_vector(23 downto 0);
	signal s2umantshift,s2mantfixed,s3mantfixed,s3mantshift,s4xorslab					: std_logic_vector(24 downto 0);
	signal s4sresult,s5result,s6result													: std_logic_vector(25 downto 0); -- Signed mantissa result
	signal s1ph,s6ph																	: std_logic_vector(26 downto 0);
	signal s0a,s0b																		: std_logic_vector(31 downto 0); -- Float 32 bit 
	signal sxprop : std_logic_vector(7 downto 0);
	
begin
	propagation:
	if propagation_chain="ON" generate
		prop_out <= sxprop(7);
		process (clk)
		begin
			if clk'event and clk='1' then
				for i in 7 downto 1 loop
					sxprop(i) <= sxprop(i-1);
				end loop;
				sxprop(0) <= prop_in; 
			end if;
		end process;
	end generate propagation ;
	process (clk)
	begin
		if clk'event and clk='1'  then 
		
			--!Registro de entrada
			s0a <= a32;
			s0b(31) <= dpc xor b32(31);	--! Importante: Integrar el signo en el operando B
			s0b(30 downto 0) <= b32(30 downto 0);

			--!Etapa 0,Escoger el mayor exponente que sera el resultado desnormalizado, calcula cuanto debe ser el corrimiento de la mantissa con menor exponente y reorganiza los operandos, si el mayor es b, intercambia las posici&oacute;n si el mayor es a las posiciones la mantiene. Zero check.
			--!signo,exponente,mantissa
			if (s0b(30 downto 23)&s0a(30 downto 23))=x"0000" then 
				s1zero <= '0';
			else
				s1zero <= '1';
			end if;
			s1delta <= s0delta(7) & (s0delta(7) xor s0delta(4))&(s0delta(7) xor s0delta(3)) & s0delta(2 downto 0);			
			case s0delta(7) is
				when '1'  => 
					s1exp <= s0b(30 downto 23);
					s1umantshift <= s0a(31)&s0a(22 downto 0);
					s1umantfixed <= s0b(31)&s0b(22 downto 0);
				when others => 
					s1exp <= s0a(30 downto 23);
					s1umantshift <= s0b(31)&s0b(22 downto 0);
					s1umantfixed <= s0a(31)&s0a(22 downto 0);
			end case;
			
			--! Etapa 1: Denormalizaci&oacute;n de la mantissas.  
			case s1delta(4 downto 3) is
				when "00" =>	s2umantshift <= s1umantshift(23)&s1postshift(23 downto 0);
				when "01" =>	s2umantshift <= s1umantshift(23)&x"00"&s1postshift(23 downto 8);
				when "10" =>	s2umantshift <= s1umantshift(23)&x"0000"&s1postshift(23 downto 16);
				when others => 	s2umantshift <= (others => '0');		
			end case;
			s2mantfixed <= s1umantfixed(23) &         ( ( ('1'&s1umantfixed(22 downto 0)) xor s1xorslab)   + ( x"00000"&"000"&s1umantfixed(23)  )   ); 
			s2exp  <= s1exp;
			
			--! Etapa2: Signar la mantissa denormalizada.
			s3mantfixed <= s2mantfixed;
			s3mantshift <= s2umantshift(24)&         (  (      s2umantshift(23 downto 0)  xor s2xorslab)   + ( x"00000"&"000"&s2umantshift(24)  )   ); 
			s3exp 		<= s2exp;
			
			--! Etapa 3: Etapa 3 Realizar la suma, entre la mantissa corrida y la fija.
			s4sresult	<= (s3mantshift(24)&s3mantshift)+(s3mantfixed(24)&s3mantfixed);
			s4exp 		<= s3exp; 
			
			--! Etapa 4: Quitar el signo a la mantissa resultante.
			s5result	<= s4sresult(25)&((s4sresult(24 downto 0) xor s4xorslab)  +(x"000000"&s4sresult(25)));
			s5exp		<= s4exp; 
			
			
			--! Etapa 5: Codificar el corrimiento para la normalizacion de la mantissa resultante.
			s6result		<= s5result;
			s6exp		 	<= s5exp; 
			s6factor		<= s5factor;
			s6factorhot9	<= s5factorhot9;
			
			--! Etapa 6: Ejecutar el corrimiento de la mantissa.
			s7sign 			<= s6result(25);
			s7exp			<= s6exp;
			s7factor		<= s6factor;
			s7postshift		<= s6postshift;
			
			
		end if;
	end process;

	--! Etapa 7: Entregar el resultado.
	c32(31)	<= s7sign;
	process(s7exp,s7postshift,s7factor)
	begin
		c32(30 downto 23)	<= s7exp+s7factor;
		case s7factor(4 downto 3) is 
			when "01" 	=> c32(22 downto 0) <= s7postshift(14 downto 00)&x"00";
			when "10" 	=> c32(22 downto 0) <= s7postshift(06 downto 00)&x"0000";
			when others => c32(22 downto 0)	<= s7postshift;
		end case; 
	end process;
	--! Combinatorial gremlin, Etapa 0 el corrimiento de la mantissa con menor exponente y reorganiza los operandos,\n
	--! si el mayor es b, intercambia las posici&oacute;n si el mayor es a las posiciones la mantiene. 
	s0delta <=  s0a(30 downto 23)-s0b(30 downto 23);
	--! Combinatorial Gremlin, Etapa 1 Codificar el factor de corrimiento de denormalizacion y denormalizar la mantissa no fija. Signar la mantissa que se queda fija.
	decodeshiftfactor:
	process (s1delta(2 downto 0))
	begin
		case s1delta(2 downto 0) is
			when "111" =>  s1shifter(8 downto 0) <= '0'&s1delta(5)&"00000"&not(s1delta(5))&'0';
			when "110" =>  s1shifter(8 downto 0) <= "00"&s1delta(5)&"000"&not(s1delta(5))&"00";
			when "101" =>  s1shifter(8 downto 0) <= "000"&s1delta(5)&'0'&not(s1delta(5))&"000";
			when "100" =>  s1shifter(8 downto 0) <= '0'&x"10";
			when "011" =>  s1shifter(8 downto 0) <= "000"&not(s1delta(5))&'0'&s1delta(5)&"000";
			when "010" =>  s1shifter(8 downto 0) <= "00"&not(s1delta(5))&"000"&s1delta(5)&"00";
			when "001" =>  s1shifter(8 downto 0) <= '0'&not(s1delta(5))&"00000"&s1delta(5)&'0';
			when others => s1shifter(8 downto 0) <=    not(s1delta(5))&"0000000"&s1delta(5);
		end case;
	end process;
	denormhighshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,18,27)
	port 	map (s1shifter,s1zero&s1umantshift(22 downto 06),s1ph);	
	denormlowshiftermult:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port 	map (s1shifter,s1umantshift(5 downto 0)&"000",s1pl);	
	
	s1postshift(23 downto 7) <= s1ph(25 downto 9);
	s1postshift(06 downto 0) <= s1ph(08 downto 2) or s1pl(17 downto 11);
	s1xorslab(23 downto 0) <= (others => s1umantfixed(23)); 
	
	--! Combinatorial Gremlin, Etapa 2: Signar la mantissa denormalizada. 
	s2xorslab <= (others => s2umantshift(24));
	
	--! Combinatorial Gremlin, Etapa 4: Quitar el signo de la mantissa resultante.
	s4xorslab <= (others => s4sresult(25));
	
	--! Combinatorial Gremlin, Etapa 5: Codificar el factor de normalizacion de la mantissa resultante.
	normalizerdecodeshift:
	process (s5result,s5factorhot24,s5token,s5tokena,s5tokenb,s5tokenc,s5factorhot9)
	begin
		s5tokena <= not(s5result(24));
		s5tokenb <= not(s5result(24));
		s5tokenc <= not(s5result(24));
		s5factor(7 downto 5) <= (others => s5result(24));
		s5factorhot24 <= x"000000";
		for i in 23 downto 16 loop
			if s5result(i)='1' then
				s5factorhot24(23-i) <= s5tokena;
				s5tokenb <= '0';
				s5tokenc <= '0';
				exit;
			end if;
		end loop;
		for i in 15 downto 8 loop
			if s5result(i)='1' then
				s5factorhot24(23-i) <= s5tokenb;
				s5tokenc <= '0';
				exit;
			end if;
		end loop;
		for i in 7 downto 0 loop
			if s5result(i)='1' then
				s5factorhot24(23-i) <= s5tokenc;
				exit;
			end if;
		end loop;
		s5token <=s5tokena&s5tokenb&s5tokenc; 
		case (s5token) is
			when "100"  => s5factor(4 downto 3) <= "10";
			when "110"  => s5factor(4 downto 3) <= "01";
			when "111"	=> s5factor(4 downto 3) <= "00";
			when others => s5factor(4 downto 3) <= (others => s5result(24));
		end case;
		s5factorhot9 <= (s5factorhot24(7 downto 0)or s5factorhot24(15 downto 8)or s5factorhot24(23 downto 16)) & s5result(24);
		case s5factorhot9 is
			when "100000000" => s5factor(2 downto 0) <= "111";
			when "010000000" => s5factor(2 downto 0) <= "110";
			when "001000000" => s5factor(2 downto 0) <= "101";
			when "000100000" => s5factor(2 downto 0) <= "100";
			when "000010000" => s5factor(2 downto 0) <= "011";
			when "000001000" => s5factor(2 downto 0) <= "010";
			when "000000100" => s5factor(2 downto 0) <= "001";
			when "000000010" => s5factor(2 downto 0) <= "000";
			when others => s5factor (2 downto 0) <= (others => s5result(24));
		end case;
		
	end process;	
	
	--! Etapa 6: Ejecutar el corrimiento para normalizar la mantissa.
	normhighshiftermult:lpm_mult
	generic map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,18,27)
	port 	map (s6factorhot9,s6result(24 downto 7),s6ph);
	normlowshiftermult:lpm_mult
	generic map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port 	map (s6factorhot9,s6result(06 downto 0)&"00",s6pl);
	s6postshift(22 downto 15) <= s6ph(16 downto 09);
	s6postshift(14 downto 06) <= s6ph(08 downto 00) + s6pl(17 downto 09);
	s6postshift(05 downto 00) <= s6pl(08 downto 03); 
	
	
	
	
	
end fadd32_arch;

	