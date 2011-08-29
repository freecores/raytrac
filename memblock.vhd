--! @file memblock.vhd
--! @brief Bloque de memoria. 
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
entity memblock is 
	generic (
		width : integer := 32	
	);
	port (
		clk,
		
		
	);
end memblock;

architecture memblock_arch of memblock is 

	component scfifo
	generic (
		add_ram_output_register	:string;
		intended_device_family	:string;
		lpm_hint				:string;
		lpm_numwords			:natural;
		lpm_showahead			:string;
		lpm_type				:string;
		lpm_width				:natural;
		lpm_widthu				:natural;
		overflow_checking		:string;
		underflow_checking		:string;
		use_eab					:string	
	);
	port(
		rdreq	: in std_logic;
		empty	: out std_logic;
		clock	: in std_logic;
		q		: out std_logic_vector(width-1 downto 0);
		wrreq	: in std_logic;
		data	: in std_logic_vector(width-1 downto 0);
		full	: out std_logic
	);
	end component;


begin 

	dpfifo : scfifo 
	generic	map ("OFF","Cyclone III","RAM_BLOCK_TYPE=M9K",9,"OFF","SCFIFO",64,4,"OFF","ON","ON");
	port	map (dpfifo_rd,clk,dpfifo_wr,dpfifo_d,dpfifo_empty,dpfifo_q,dpfifo_full);
	normfifo : scfifo
	generic map ("OFF","Cyclone III","RAM_BLOCK_TYPE=M9K",26,"OFF","SCFIFO",96,5,"OFF","ON","ON");
	port	map (normfifo_rd,clk,normfifo_wr,normfifo_d,normfifo_empty,normfifo_q,normfifo_full);
	
	



end memblock_arch;

