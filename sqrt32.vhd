------------------------------------------------
--! @file fsqrt32.vhd
--! @brief RayTrac Floating Point Adder  
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------


-- RAYTRAC (FP BRANCH)
-- Author Julian Andres Guarin
-- fsqrt32.vhd
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
use work.arithpack.all;
entity sqrt32 is 
	
	port (
		
		clk	: in std_logic;
		rd32: in xfloat32;		
		sq32: out xfloat32
	);
end entity;
architecture sqrt32_arch of sqrt32 is 

	component altsyncram
	generic (
		address_aclr_a		: string;
		clock_enable_input_a		: string;
		clock_enable_output_a		: string;
		init_file		: string;
		intended_device_family		: string;
		lpm_hint		: string;
		lpm_type		: string;
		numwords_a		: natural;
		operation_mode		: string;
		outdata_aclr_a		: string;
		outdata_reg_a		: string;
		widthad_a		: natural;
		width_a		: natural;
		width_byteena_a		: natural
	);
	port (
			clock0		:	in std_logic;
			rden_a		:	in std_logic;
			address_a	: 	in std_logic_vector (9 downto 0);
			q_a			: 	out std_logic_vector (17 downto 0)
	);
	end component;

	signal s0sgn			: std_logic;
	signal s0uexp,s0e129	: std_logic_vector(7 downto 0);
	signal s0q				: std_logic_vector(17 downto 0);
	signal sxprop			: std_logic;
begin
	
	--! SNAN?
	process (clk)
	begin
		if clk'event and clk='1'  then
			
			--!Carga de Operando.
			s0sgn <= rd32(31);
			s0uexp <= rd32(30 downto 23);

		end if;
	end process;
	
	--! Etapa 0: Calcular direcci&oacute;n a partir del exponente y el exponente.
	sq32(31) <= s0sgn;
	sq32(30 downto 23) <= (s0e129(7)&s0e129(7 downto 1))+127;
	sq32(22 downto 6) <= s0q(16 downto 0);
	
	
	--! Combinatorial Gremlin: Etapa 0, calculo del exponente. 
	s0e129<=s0uexp+("1000000"&s0uexp(0));
	sq32(5 downto 0) <= (others => '0');
	--! Combinatorial Gremlin, Etapa 0, calcula la ra&iacute;z cuadrada de la mantissa
	--! Recuerde que aunque rd32(23) no pertenece a la mantissa indica si el exponente es par o impar, 1 (par) y 0 (impar)
	altsyncram_component : altsyncram
	generic map (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		--init_file => "X:/Code/Indigo/fp/fp/memsqrt.mif",
		init_file => "//IMACJULIAN/imac/Code/Indigo/fp/fp/memsqrt.mif",		
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 1024,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "UNREGISTERED",
		widthad_a => 10,
		width_a => 18,
		width_byteena_a => 1
	)
	port map (rden_a => '1', clock0 => clk, address_a => rd32(23 downto 14), q_a => s0q);

end architecture;