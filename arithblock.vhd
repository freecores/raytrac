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
--     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
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
	
		dpc : in std_logic;
	
		f	: in std_logic_vector (12*32-1 downto 0);
		a	: in std_logic_vector (8*32-1 downto 0);
		
		s	: out std_logic_vector (4*32-1 downto 0);
		p	: out std_logic_vector (6*32-1 downto 0)
			
	);
end entity;

architecture arithblock_arch of arithblock is

	


begin 
	--! 4 sumadores.	
--	arithblock:
--	for i in 3 downto 0 generate
--		adder_i : fadd32 
--		port map (
--			clk => clk,
--			dpc => dpc,
--			a32 => a( ((i*2)+1)*32-1	downto (i*2)*32),
--			b32 => a( ((i*2)+2)*32-1	downto ((i*2)+1)*32),
--			c32 => s( (i+1)*32-1		downto 32*i)
--		);
--	end generate arithblock;
	--! 6 multiplicadores.
--	mulblock:
--	for i in 5 downto 0 generate
--		mul_i	: fmul32
--		port map (
--			clk => clk,
--			a32 => f( ((i*2)+1)*32-1	downto (i*2)*32),
--			b32 => f( ((i*2)+2)*32-1	downto ((i*2)+1)*32),
--			p32 => p( (i+1)*32-1		downto 32*i)
--		);
--	end generate mulblock;
	--!TBXINSTANCESTART
	adder_i_0 : fadd32 
	port map (
		clk => clk,
		dpc => dpc,
		a32 => a( 31	downto 0),
		b32 => a( 63	downto 32),
		c32 => s( 31	downto 0)
	);
	--!TBXINSTANCESTART
	adder_i_1 : fadd32 
	port map (
		clk => clk,
		dpc => dpc,
		a32 => a( 95	downto 64),
		b32 => a( 127	downto 96),
		c32 => s( 63	downto 32)
	);
	--!TBXINSTANCESTART
	adder_i_2 : fadd32 
	port map (
		clk => clk,
		dpc => dpc,
		a32 => a( 159	downto 128),
		b32 => a( 191	downto 160),
		c32 => s( 95	downto 64)
	);
	--!TBXINSTANCESTART
	adder_i_3 : fadd32 
	port map (
		clk => clk,
		dpc => dpc,
		a32 => a( 223	downto 192),
		b32 => a( 255	downto 224),
		c32 => s( 127	downto 96)
	);
	--!TBXINSTANCESTART
	mul_i_0 : fmul32 
	port map (
		clk => clk,
		a32 => f( 31	downto 0),
		b32 => f( 63	downto 32),
		p32 => p( 31	downto 0)
	);
	--!TBXINSTANCESTART
	mul_i_1 : fmul32 
	port map (
		clk => clk,
		a32 => f( 95	downto 64),
		b32 => f( 127	downto 96),
		p32 => p( 63	downto 32)
	);
	--!TBXINSTANCESTART
	mul_i_2 : fmul32 
	port map (
		clk => clk,
		a32 => f( 159	downto 128),
		b32 => f( 191	downto 160),
		p32 => p( 95	downto 64)
	);
	--!TBXINSTANCESTART
	mul_i_3 : fmul32 
	port map (
		clk => clk,
		a32 => f( 223	downto 192),
		b32 => f( 255	downto 224),
		p32 => p( 127	downto 96)
	);
	--!TBXINSTANCESTART
	mul_i_4 : fmul32 
	port map (
		clk => clk,
		a32 => f( 287	downto 256),
		b32 => f( 319	downto 288),
		p32 => p( 159	downto 128)
	);
	--!TBXINSTANCESTART
	mul_i_5 : fmul32 
	port map (
		clk => clk,
		a32 => f( 351	downto 320),
		b32 => f( 383	downto 352),
		p32 => p( 191	downto 160)
	);
	
	
	
end architecture;
	
 
	