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
	
		prd32blki	: in vectorblock12;
		add32blki	: in vectorblock06;
		
		add32blko	: out vectorblock03;
		prd32blko	: out vectorblock06;
		
		sq32o		: out xfloat32;
		inv32o		: out xfloat32
		
		
			
	);
end entity;

architecture arithblock_arch of arithblock is

	signal sadd32blko_01 : xfloat32;
	signal ssq32o : xfloat32;
		
	--! Componentes Aritm&eacute;ticos
	component fadd32
	port (
		clk : in std_logic;
		dpc : in std_logic;
		a32 : in xfloat32;
		b32 : in xfloat32;
		c32 : out xfloat32
	);
	end component;
	component fmul32 
	port (
		clk : in std_logic;
		a32 : in xfloat32;
		b32 : in xfloat32;
		p32 : out xfloat32
	);
	end component;
	--! Bloque de Raiz Cuadrada
	component sqrt32
	port (
		
		clk	: in std_logic;
		rd32: in xfloat32;		
		sq32: out xfloat32
	);
	end component;
	--! Bloque de Inversores.
	component invr32
	port (
		
		clk		: in std_logic;
		dvd32	: in xfloat32;		
		qout32	: out xfloat32
	);
	end component;


begin 

	sq32o <= ssq32o;
	add32blko(1) <= sadd32blko_01;

	--!TBXINSTANCESTART
	adder_i_0 : fadd32 
	port map (
		clk => clk,
		dpc => sign,
		a32 => add32blki(0),
		b32 => add32blki(1),
		c32 => add32blko(0)
	);
	--!TBXINSTANCESTART
	adder_i_1 : fadd32 
	port map (
		clk => clk,
		dpc => sign,
		a32 => add32blki(2),
		b32 => add32blki(3),
		c32 => sadd32blko_01
	);
	--!TBXINSTANCESTART
	adder_i_2 : fadd32 
	port map (
		clk => clk,
		dpc => sign,
		a32 => add32blki(4),
		b32 => add32blki(5),
		c32 => add32blko(2)
	);
	--!TBXINSTANCESTART
	mul_i_0 : fmul32 
	port map (
		clk => clk,
		a32 => prd32blki(0),
		b32 => prd32blki(1),
		p32 => prd32blko(0)
	);
	--!TBXINSTANCESTART
	mul_i_1 : fmul32 
	port map (
		clk => clk,
		a32 => prd32blki(2),
		b32 => prd32blki(3),
		p32 => prd32blko(1)
	);
	--!TBXINSTANCESTART
	mul_i_2 : fmul32 
	port map (
		clk => clk,
		a32 => prd32blki(4),
		b32 => prd32blki(5),
		p32 => prd32blko(2)
	);
	--!TBXINSTANCESTART
	mul_i_3 : fmul32 
	port map (
		clk => clk,
		a32 => prd32blki(6),
		b32 => prd32blki(7),
		p32 => prd32blko(3)
	);
	--!TBXINSTANCESTART
	mul_i_4 : fmul32 
	port map (
		clk => clk,
		a32 => prd32blki(8),
		b32 => prd32blki(9),
		p32 => prd32blko(4)
	);
	--!TBXINSTANCESTART
	mul_i_5 : fmul32 
	port map (
		clk => clk,
		a32 => prd32blki(10),
		b32 => prd32blki(11),
		p32 => prd32blko(5)
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
	
 
	