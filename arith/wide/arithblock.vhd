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

	--! Altera Compiler Directive, to avoid m9k autoinferring thanks to the guys at http://www.alteraforum.com/forum/archive/index.php/t-30784.html .... 
	attribute altera_attribute : string; 
	attribute altera_attribute of arithblock_arch : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF";


	signal sadd32blko_01 : std_logic_vector(31 downto 0);
	signal ssq32o : std_logic_vector(31 downto 0);
		
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
		clk : std_logic;
		factor0 : in std_logic_vector(31 downto 0);
		factor1 : in std_logic_vector(31 downto 0);
		factor2 : in std_logic_vector(31 downto 0);
		factor3 : in std_logic_vector(31 downto 0);
		factor4 : in std_logic_vector(31 downto 0);
		factor5 : in std_logic_vector(31 downto 0);
		factor6 : in std_logic_vector(31 downto 0);
		factor7 : in std_logic_vector(31 downto 0);
		factor8 : in std_logic_vector(31 downto 0);
		factor9 : in std_logic_vector(31 downto 0);
		factor10: in std_logic_vector(31 downto 0);
		factor11: in std_logic_vector(31 downto 0);
		p0: out std_logic_vector(31 downto 0);
		p1: out std_logic_vector(31 downto 0);
		p2: out std_logic_vector(31 downto 0);
		p3: out std_logic_vector(31 downto 0);
		p4: out std_logic_vector(31 downto 0);
		p5: out std_logic_vector(31 downto 0)
		
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
		dpc => sign,
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
		factor0 => factor0,
		factor1 => factor1,
		factor2 => factor2,
		factor3 => factor3,
		factor4 => factor4,
		factor5 => factor5,
		factor6 => factor6,
		factor7 => factor7,
		factor8 => factor8,
		factor9 => factor9,
		factor10 => factor10,
		factor11 => factor11,
		p0 => p0,
		p1 => p1,
		p2 => p2,
		p3 => p3,
		p4 => p4,
		p5 => p5
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
	
 
	