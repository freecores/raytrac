--! @file arithblock.vhd
--! @brief Bloque Aritmético de 4 sumadores y 6 multiplicadores. 
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------------------
-- RAYTRAC
-- Author Julian Andres Guarin
-- memblock.vhd
-- This file is part of raytrac.
-- 
--     raytrac is free software: you can redistribute it and/or modify
--     it under the terms of the GNU General Public License as published by
--     the Free Software Foundation, either version 3 of the License, or
--     (at your option) any later version.
-- 
--     raytrac is distributed in the hope that it will be useful,
--     but WITHOUT ANY WARRANTY; without even the implied warranty of
--     MERCHANTABILITY or FITNESS FOR a PARTICULAR PURPOSE.  See the
--     GNU General Public License for more details.
-- 
--     You should have received a copy of the GNU General Public License
--     along with raytrac.  If not, see <http://www.gnu.org/licenses/>.


library ieee;
use ieee.std_logic_1164.all;
use work.arithpack.all;

entity arithblock is
	port (
		
		clk	: in std_logic;
		rst : in std_logic;
	
		sign : in std_logic;
		sign_switch	: in std_logic;
	
		factor0		: in std_logic_vector(31 downto 0);
		factor1		: in std_logic_vector(31 downto 0);
		factor2		: in std_logic_vector(31 downto 0);
		factor3		: in std_logic_vector(31 downto 0);
		factor4		: in std_logic_vector(31 downto 0);
		factor5		: in std_logic_vector(31 downto 0);
		factor6		: in std_logic_vector(31 downto 0);
		factor7		: in std_logic_vector(31 downto 0);
		factor8		: in std_logic_vector(31 downto 0);
		factor9		: in std_logic_vector(31 downto 0);
		factor10	: in std_logic_vector(31 downto 0);
		factor11	: in std_logic_vector(31 downto 0);
		--factor	: in vectorblock06;
	
		sumando0	: in std_logic_vector(31 downto 0);
		sumando1	: in std_logic_vector(31 downto 0);
		sumando2	: in std_logic_vector(31 downto 0);
		sumando3	: in std_logic_vector(31 downto 0);
		sumando4	: in std_logic_vector(31 downto 0);
		sumando5	: in std_logic_vector(31 downto 0);
		--add32blki	: in vectorblock06;
		
		a0			: out std_logic_vector(31 downto 0);
		a1			: out std_logic_vector(31 downto 0);
		a2			: out std_logic_vector(31 downto 0);
		--add32blko	: out vectorblock03;
		
		p0			: out std_logic_vector(31 downto 0);
		p1			: out std_logic_vector(31 downto 0);
		p2			: out std_logic_vector(31 downto 0);
		p3			: out std_logic_vector(31 downto 0);
		p4			: out std_logic_vector(31 downto 0);
		p5			: out std_logic_vector(31 downto 0);
		--p	: out vectorblock06;
		
		sq32o		: out std_logic_vector(31 downto 0);
		inv32o		: out std_logic_vector(31 downto 0)
		
		
			
	);
end entity;

architecture arithblock_arch of arithblock is

	signal sadd32blko_01 : std_logic_vector(31 downto 0);
	signal ssq32o : std_logic_vector(31 downto 0);
	signal ssigna1 : std_logic;
		
	--! Componentes Aritm&eacute;ticos
	component fadd32long
	port (
		clk : in std_logic;
		dpc : in std_logic;
		a32 : in std_logic_vector(31 downto 0);
		b32 : in std_logic_vector(31 downto 0);
		c32 : out std_logic_vector(31 downto 0)
	);
	end component;
	component fmul32 
	port (
		clk : in std_logic;
		a32 : in std_logic_vector(31 downto 0);
		b32 : in std_logic_vector(31 downto 0);
		p32 : out std_logic_vector(31 downto 0)
	);
	end component;
	--! Bloque de Raiz Cuadrada
	component sqrt32
	port (
		
		clk	: in std_logic;
		rd32: in std_logic_vector(31 downto 0);		
		sq32: out std_logic_vector(31 downto 0)
	);
	end component;
	--! Bloque de Inversores.
	component invr32
	port (
		
		clk		: in std_logic;
		dvd32	: in std_logic_vector(31 downto 0);		
		qout32	: out std_logic_vector(31 downto 0)
	);
	end component;


begin 

	sq32o <= ssq32o;
	a1 <= sadd32blko_01;
	ssigna1 <= sign_switch or sign; 

	--!TBXINSTANCESTART
	adder_i_0 : fadd32long 
	port map (
		clk => clk,
		dpc => sign,
		a32 => sumando0,
		b32 => sumando1,
		c32 => a0
	);
	--!TBXINSTANCESTART
	adder_i_1 : fadd32long 
	port map (
		clk => clk,
		dpc => ssigna1,
		a32 => sumando2,
		b32 => sumando3,
		c32 => sadd32blko_01
	);
	--!TBXINSTANCESTART
	adder_i_2 : fadd32long 
	port map (
		clk => clk,
		dpc => sign,
		a32 => sumando4,
		b32 => sumando5,
		c32 => a2
	);
	--!TBXINSTANCESTART
	mul_i_0 : fmul32 
	port map (
		clk => clk,
		a32 => factor0,
		b32 => factor1,
		p32 => p0
	);
	--!TBXINSTANCESTART
	mul_i_1 : fmul32 
	port map (
		clk => clk,
		a32 => factor2,
		b32 => factor3,
		p32 => p1
	);
	--!TBXINSTANCESTART
	mul_i_2 : fmul32 
	port map (
		clk => clk,
		a32 => factor4,
		b32 => factor5,
		p32 => p2
	);
	--!TBXINSTANCESTART
	mul_i_3 : fmul32 
	port map (
		clk => clk,
		a32 => factor6,
		b32 => factor7,
		p32 => p3
	);
	--!TBXINSTANCESTART
	mul_i_4 : fmul32 
	port map (
		clk => clk,
		a32 => factor8,
		b32 => factor9,
		p32 => p4
	);
	--!TBXINSTANCESTART
	mul_i_5 : fmul32 
	port map (
		clk => clk,
		a32 => factor10,
		b32 => factor11,
		p32 => p5
	);
	--!TBXINSTANCESTART
	square_root : sqrt32
	port map (
		clk 	=> clk,
		rd32	=> sadd32blko_01,
		sq32	=> ssq32o 
	);
	--!TBXINSTANCESTART
	inversion_block : invr32
	port map (
		clk		=> clk,
		dvd32	=> ssq32o,
		qout32	=> inv32o
	);
	
	
	
	
	
end architecture;
	
 
	