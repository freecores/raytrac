
-- RAYTRAC
-- Author Julian Andres Guarin
-- arithpack.vhd
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
--     along with raytrac.  If not, see <http://www.gnu.org/licenses/>.library ieee;



use ieee.std_logic_1164.all;




package arithpack is
	
	constant rstMasterValue : std_logic := '1';

	component uf
	port (
		opcode		: in std_logic;
		m0f0,m0f1,m1f0,m1f1,m2f0,m2f1,m3f0,m3f1,m4f0,m4f1,m5f0,m5f1 : in std_logic_vector(17 downto 0);
		cpx,cpy,cpz,dp0,dp1 : out std_logic_vector(31 downto 0);
		clk,rst		: in std_logic
	);
	end component;
		
	component opcoder 
	port (
		Ax,Bx,Cx,Dx,Ay,By,Cy,Dy,Az,Bz,Cz,Dz : in std_logic_vector (17 downto 0);
		m0f0,m0f1,m1f0,m1f1,m2f0,m2f1,m3f0,m3f1,m4f0,m4f1,m5f0,m5f1 : out std_logic_vector (17 downto 0);
		opcode,addcode : in std_logic
	);
	end component;

	
	component r_a18_b18_smul_c32_r
	port (
		aclr,clock:in std_logic;
		dataa,datab:in std_logic_vector (17 downto 0);
		result: out std_logic_vector(31 downto 0)
	);
	end component;
	component cla_logic_block 
	generic ( w: integer:=4);
	port (
		p,g:in std_logic_vector(w-1 downto 0);
		cin:in std_logic;
		c:out std_logic_vector(w downto 1)
	);
	end component;
	component rca_logic_block
	generic ( w : integer := 4);
	port (
		p,g: in std_logic_vector(w-1 downto 0);
		cin: in std_logic;
		c: out std_logic_vector(w downto 1)
	);
	end component;
	component adder
	generic ( 
		w 						: integer := 4;
		carry_logic				: string := "CLA";
		substractor_selector	: string := "YES"
	);
	port (
		a,b		:	in std_logic_vector (w-1 downto 0);
		s,ci	:	in	std_logic;
		result	:	out std_logic_vector (w-1 downto 0);
		cout	:	out std_logic
	);	 		
	end component;
		
end package; 
