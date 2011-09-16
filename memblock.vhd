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
		
		width : integer := 32;
		blocksize : integer := 512;
		widthadmemblock : integer :=9;
		
		external_writeable_blocks : integer := 12;
		external_readable_blocks  : integer := 8;
		external_readable_widthad	: integer := 3;				
		external_writeable_widthad	: integer := 4		
	);
	port (
		
		clk,dpfifo_flush,normfifo_flush,dpfifo_rd,normfifo_rd,dpfifo_wr,normfifo_wr : in std_logic;
		dpfifo_empty, normfifo_empty, dpfifo_full, normfifo_full : out std_logic;
		instrfifo_flush,instrfifo_rd,instrfifo_wr: in std_logic;
		instrfifo_empty,instrfifo_full : out std_logic; 
		ext_rd,ext_wr,int_wr: in std_logic;
		ext_wr_add : in std_logic_vector(external_writeable_widthad+widthadmemblock-1 downto 0);		
		ext_rd_add : in std_logic_vector(external_readable_widthad+widthadmemblock-1 downto 0);
		ext_d: in std_logic_vector(width-1 downto 0);
		int_d : in std_logic_vector(external_readable_blocks*width-1 downto 0);
		ext_q : out std_logic_vector(width-1 downto 0);
		int_q : out std_logic_vector(external_writeable_blocks*width-1 downto 0);
		int_wr_add : in std_logic_vector(widthadmemblock-1 downto 0);
		int_rd_add : in std_logic_vector(2*widthadmemblock-1 downto 0);
		instrfifo_d : in std_logic_vector(width-1 downto 0);
		dpfifo_d : in std_logic_vector(width*2-1 downto 0);
		normfifo_d : in std_logic_vector(width*3-1 downto 0);
		dpfifo_q : out std_logic_vector(width*2-1 downto 0);
		normfifo_q : out std_logic_vector(width*3-1 downto 0)
	);
end memblock;

architecture memblock_arch of memblock is 

	type	vectorblock12 is array (11 downto 0) of std_logic_vector(width-1 downto 0);
	type	vectorblock08 is array (07 downto 0) of std_logic_vector(width-1 downto 0);
	type	vectorblock02 is array (01 downto 0) of std_logic_vector(widthadmemblock-1 downto 0);
	
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
		aclr	: in std_logic;
		empty	: out std_logic;
		clock	: in std_logic;
		q		: out std_logic_vector(lpm_width-1 downto 0);
		wrreq	: in std_logic;
		data	: in std_logic_vector(lpm_width-1 downto 0);
		full	: out std_logic
	);
	end component;
	
	component altsyncram
	generic (
		address_aclr_b			: string;
		address_reg_b 			: string;
		clock_enable_input_a 	: string;
		clock_enable_input_b 	: string;
		clock_enable_output_b	: string;
		intended_device_family	: string;
		lpm_type				: string;
		numwords_a				: natural;
		numwords_b				: natural;
		operation_mode			: string;
		outdata_aclr_b			: string;
		outdata_reg_b			: string;
		power_up_uninitialized	: string;
		ram_block_type			: string;
		rdcontrol_reg_b			: string;
		read_during_write_mode_mixed_ports	: string;
		widthad_a				: natural;
		widthad_b				: natural;
		width_a					: natural;
		width_b					: natural;
		width_byteena_a			: natural
	);
	port (
		wren_a		: in std_logic;
		clock0		: in std_logic;
		address_a 	: in std_logic_vector(widthad_a-1 downto 0);
		address_b 	: in std_logic_vector(widthad_b-1 downto 0);
		rden_b		: in std_logic;
		q_b			: out std_logic_vector(width-1 downto 0);
		data_a		: in std_logic_vector(width-1 downto 0)
		
	);
	end component;
	signal s0ext_wr_add_one_hot : std_logic_vector(external_writeable_blocks-1 downto 0);
	signal s0ext_wr_add			: std_logic_vector(external_writeable_widthad+widthadmemblock-1 downto 0);
	signal s0ext_rd_add			: std_logic_vector(external_readable_widthad-1 downto 0);
	signal s0int_rd_add			: std_logic_vector(widthadmemblock-1 downto 0);
	signal s0int_wr_add			: std_logic_vector(widthadmemblock-1 downto 0);
	signal s0ext_wr				: std_logic;
	signal s0ext_d				: std_logic_vector(width-1 downto 0);

	signal s1ext_rd_add			: std_logic_vector(external_readable_widthad-1 downto 0);
	signal s1ext_q,sint_d		: vectorblock08;
	signal sint_rd_add			: vectorblock02;
	signal s1int_q				: vectorblock12;	

begin 

	dpfifo : scfifo 
	generic	map ("OFF","Cyclone III","RAM_BLOCK_TYPE=M9K",9,"OFF","SCFIFO",64,4,"OFF","OFF","ON")
	port	map (dpfifo_rd,dpfifo_flush,dpfifo_empty,clk,dpfifo_q,dpfifo_wr,dpfifo_d,dpfifo_full);
	normfifo : scfifo
	generic map ("OFF","Cyclone III","RAM_BLOCK_TYPE=M9K",26,"OFF","SCFIFO",96,5,"OFF","OFF","ON")
	port	map (normfifo_rd,normfifo_flush,normfifo_empty,clk,normfifo_q,normfifo_wr,normfifo_d,normfifo_full);
	instrfifo : scififo
	generic map ("OFF","Cyclone III","RAM_BLOCK_TYPE_M9K",64,"OFF","SCIFIFO",32,6,"OFF","OFF","ON")
	port 	map (instrfifo_rd,instrfifo_flush,instrfifo_empty,clk,instrfifo_q,instrfifo_wr,instrfifo_d,instrifo_full);
	
	
	sint_rd_add (0)<= int_rd_add(widthadmemblock-1 downto 0);
	sint_rd_add (1)<= int_rd_add(2*widthadmemblock-1 downto widthadmemblock);
	
	results_blocks: 
	for i in 7 downto 0 generate
		sint_d(i) <= int_d((i+1)*width-1 downto i*width);
		resultsblock : altsyncram
		generic map ("NONE","CLOCK0","BYPASS","BYPASS","BYPASS","Cyclone III","altsyncram",2**widthadmemblock,2**widthadmemblock,"DUAL_PORT","NONE","CLOCK0","FALSE","M9K","CLOCK0","OLD_DATA",widthadmemblock,widthadmemblock,width,width,1)
		port	map (int_wr,clk,int_wr_add,ext_rd_add(widthadmemblock-1 downto 0),ext_rd,s1ext_q(i),sint_d(i));
	end generate results_blocks;
	
	operands_blocks: 
	for i in 11 downto 0 generate
		int_q((i+1)*width-1 downto width*i) <= s1int_q(i);
		operandsblock : altsyncram
		generic map ("NONE","CLOCK0","BYPASS","BYPASS","BYPASS","Cyclone III","altsyncram",2**widthadmemblock,2**widthadmemblock,"DUAL_PORT","NONE","CLOCK0","FALSE","M9K","CLOCK0","OLD_DATA",widthadmemblock,widthadmemblock,width,width,1)
		port 	map (s0ext_wr_add_one_hot(i),clk,s0ext_wr_add(widthadmemblock-1 downto 0),sint_rd_add((i/3) mod 2),'1',s1int_q(i),s0ext_d);
	end generate operands_blocks;
	
	
	operands_block_proc: process (clk)
	begin
		if clk'event and clk='1' then
			 --! Registro de entrada
			 s0ext_wr_add <= ext_wr_add;
			 s0ext_wr  <= ext_wr;
			 s0ext_d  <= ext_d;
			--! Etapa 0: Decodificacion de las se&ntilde:ales de escritura.
			case s0ext_wr_add(external_writeable_widthad+widthadmemblock-1 downto widthadmemblock) is 
				when x"0" => s0ext_wr_add_one_hot <= x"00"&"000"&s0ext_wr;
				when x"1" => s0ext_wr_add_one_hot <= x"00"&"00"&s0ext_wr&'0';
				when x"2" => s0ext_wr_add_one_hot <= x"00"&'0'&s0ext_wr&"00";
				when x"3" => s0ext_wr_add_one_hot <= x"00"&s0ext_wr&"000";
				when x"4" => s0ext_wr_add_one_hot <= x"0"&"000"&s0ext_wr&x"0";
				when x"5" => s0ext_wr_add_one_hot <= x"0"&"00"&s0ext_wr&'0'&x"0";
				when x"6" => s0ext_wr_add_one_hot <= x"0"&'0'&s0ext_wr&"00"&x"0";
				when x"7" => s0ext_wr_add_one_hot <= x"0"&s0ext_wr&"000"&x"0";
				when x"8" => s0ext_wr_add_one_hot <= "000"&s0ext_wr&x"00";
				when x"9" => s0ext_wr_add_one_hot <= "00"&s0ext_wr&'0'&x"00";
				when x"A" => s0ext_wr_add_one_hot <= '0'&s0ext_wr&"00"&x"00";
				when others => s0ext_wr_add_one_hot <= s0ext_wr&"000"&x"00";
			end case;
		end if;
	end process;
	results_block_proc: process(clk)
	begin
		if clk'event and clk='1' then
			--!Registrar entrada
			s0ext_rd_add <= ext_rd_add(external_readable_widthad+widthadmemblock-1 downto widthadmemblock);
			--!Etapa 0: Leer memorias
			s1ext_rd_add <= s0ext_rd_add;
			--!Etapa 1: Seleccionar dato a leer;
			case '0'&s1ext_rd_add is
				when x"0" => ext_q <= s1ext_q(0);
				when x"1" => ext_q <= s1ext_q(1);
				when x"2" => ext_q <= s1ext_q(2);
				when x"3" => ext_q <= s1ext_q(3);
				when x"4" => ext_q <= s1ext_q(4);
				when x"5" => ext_q <= s1ext_q(5);
				when x"6" => ext_q <= s1ext_q(6);
				when others => ext_q <= s1ext_q(7);
			end case;			
		end if;
	end process;
end memblock_arch;

