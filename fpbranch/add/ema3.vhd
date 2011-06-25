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
	
	signal bss,css									: std_logic_vector(22 downto 0);	
	signal sa,sb,sc,ssa,ssb,ssc,s4a					: std_logic_vector(31 downto 0);
	signal s4umb,s4umc								: std_logic_vector(23 downto 0);
	signal s4sma,s4smb,s4smc						: std_logic_vector(24 downto 0);
	signal sspHb,sspLb,sspHc,sspLc					: std_logic_vector(35 downto 0);								
	signal s4sgb,s4sgc,zeroa,zerob,zeroc,sszb,sszc	: std_logic; 
begin

	process (clk)
	begin
		if clk'event and clk='1' then 
		
			--!Registro de entrada
			sa <= a32;
			sb <= b32;
			sc <= c32;

			--!Primera etapa a vs. b
			if sa(30 downto 23) >= sb (30 downto 23) and sa(30 downto 23) >=sc(30 downto 23) then
				--!signo,exponente,mantissa de b yc
				ssb(31) <= sb(31);
				ssb(30 downto 23) <= sa(30 downto 23) - sb(30 downto 23);
				ssb(22 downto 0) <= sb(22 downto 0);
				sszb <= zerob;
				ssc(31) <= sc(31);
				ssc(30 downto 23) <= sa(30 downto 23) - sc(30 downto 23);
				ssc(22 downto 0) <= sc(22 downto 0);
				sszc <= zeroc;
				--!clasifica a
				ssa <= sa;
			elsif sb(30 downto 23) >= sc (30 downto 23) then 
				--!signo,exponente,mantissa
				ssb(31) <= sa(31);
				ssb(30 downto 23) <= sb(30 downto 23)-sa(30 downto 23);
				ssb(22 downto 0) <= sa(22 downto 0);
				sszb <= zeroa;
				ssc(31) <= sc(31);
				ssc(30 downto 23) <= sb(30 downto 23) - sc(30 downto 23);
				ssc(22 downto 0) <= sc(22 downto 0);
				sszc <= zeroc;
				--!clasifica b
				ssa <= sb;
			else
				--!signo,exponente,mantissa
				ssb(31) <= sb(31);
				ssb(30 downto 23) <= sc(30 downto 23)-sb(30 downto 23);
				ssb(22 downto 0) <= sb(22 downto 0);
				sszb <= zerob;
				ssc(31) <= sa(31);
				ssc(30 downto 23) <= sc(30 downto 23) - sa(30 downto 23);
				ssc(22 downto 0) <= sa(22 downto 0);
				sszc <= zeroa;
				--!clasifica c
				ssa <= sc;
			end if;
			
			
			
			--! Segunda etapa corrimiento y denormalizaci&oacute;n de mantissas  
			s4a <= ssa;
			s4sgb <= ssb(31);
			s4sgc <= ssc(31);
			
			for i in 17 downto 0 loop
				s4umb(i)  <= sspHb(17-i) or sspLb(23-i);
				s4umc(i)  <= sspHc(17-i) or sspLc(23-i);
				
			end loop;
			for i in 23 downto 18 loop
				s4umb(i)  <= sspLb(23-i);
				s4umc(i)  <= sspLc(23-i);
			end loop;
			
			--! Tercera etapa signar la mantissa y entregar el exponente.
			sma <= s4sma + s4a(31);
			smb <= s4smb + s4sgb;
			smc <= s4smc + s4sgc;
			exp <= s4a(30 downto 23);
		end if;
	end process;
	
	--! Combinatorial Gremlin
	highshiftermultb:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",18,18,36)
	port 	map (shl(conv_std_logic_vector(1,18),ssb(30 downto 23)),bss(22 downto 5),sspHb);	
	lowshiftermultb:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",18,18,36)
	port 	map (shl(conv_std_logic_vector(1,18),ssb(30 downto 23)),conv_std_logic_vector(0,12)&bss(4 downto 0)&sszb,sspLb);	
	highshiftermultc:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",18,18,36)
	port 	map (shl(conv_std_logic_vector(1,18),ssc(30 downto 23)),css(22 downto 5),sspHc);	
	lowshiftermultc:lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",18,18,36)
	port 	map (shl(conv_std_logic_vector(1,18),ssc(30 downto 23)),conv_std_logic_vector(0,12)&css(4 downto 0)&sszc,sspLc);	
	
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
	
	--! zero
	process (sc,sb,sa)
	begin
		
		zeroc <= '0';
		zerob <= '0';
		zeroa <= '0';
		
		for i in 30 downto 23 loop
			if sa(i)='1' then
				zeroa <= '1';
			end if;
			if sb(i)='1' then
				zerob <='1';
			end if;
			if sc(i)='1' then
				zeroc <='1';
			end if;
			
		end loop;
	end process;	
	--! ssb2bssInversor de posicion 
	ssb2bss:
	for i in 22 downto 0 generate
		bss(i) <= ssb(22-i);
		css(i) <= ssc(22-i);
	end generate ssb2bss;
	
end ema3_arch;

		