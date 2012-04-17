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
	
		f	: in vectorblock12;
		a	: in vectorblock08;
		
		s	: out vectorblock04;
		p	: out vectorblock06
			
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
		a32 => a(0),
		b32 => a(1),
		c32 => s(0)
	);
	--!TBXINSTANCESTART
	adder_i_1 : fadd32 
	port map (
		clk => clk,
		dpc => dpc,
		a32 => a(2),
		b32 => a(3),
		c32 => s(1)
	);
	--!TBXINSTANCESTART
	adder_i_2 : fadd32 
	port map (
		clk => clk,
		dpc => dpc,
		a32 => a(4),
		b32 => a(5),
		c32 => s(2)
	);
	--!TBXINSTANCESTART
	adder_i_3 : fadd32 
	port map (
		clk => clk,
		dpc => dpc,
		a32 => a(6),
		b32 => a(7),
		c32 => s(3)
	);
	--!TBXINSTANCESTART
	mul_i_0 : fmul32 
	port map (
		clk => clk,
		a32 => f(0),
		b32 => f(1),
		p32 => p(0)
	);
	--!TBXINSTANCESTART
	mul_i_1 : fmul32 
	port map (
		clk => clk,
		a32 => f(2),
		b32 => f(3),
		p32 => p(1)
	);
	--!TBXINSTANCESTART
	mul_i_2 : fmul32 
	port map (
		clk => clk,
		a32 => f(4),
		b32 => f(5),
		p32 => p(2)
	);
	--!TBXINSTANCESTART
	mul_i_3 : fmul32 
	port map (
		clk => clk,
		a32 => f(6),
		b32 => f(7),
		p32 => p(3)
	);
	--!TBXINSTANCESTART
	mul_i_4 : fmul32 
	port map (
		clk => clk,
		a32 => f(8),
		b32 => f(9),
		p32 => p(4)
	);
	--!TBXINSTANCESTART
	mul_i_5 : fmul32 
	port map (
		clk => clk,
		a32 => f(10),
		b32 => f(11),
		p32 => p(5)
	);
	
	
	
end architecture;
	
 
	