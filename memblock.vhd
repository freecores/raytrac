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
		
		clk,ena,dpfifo_flush,normfifo_flush,dpfifo_rd,normfifo_rd,dpfifo_wr,normfifo_wr : in std_logic;
		dpfifo_empty, normfifo_empty, dpfifo_full, normfifo_full : out std_logic;
		instrfifo_flush,instrfifo_rd,instrfifo_wr,resultfifo_flush,resultfifo_wr: in std_logic;
		instrfifo_empty,instrfifo_full: out std_logic; 
		ext_rd,ext_wr: in std_logic;
		ext_wr_add : in std_logic_vector(external_writeable_widthad+widthadmemblock-1 downto 0);		
		ext_rd_add : in std_logic_vector(external_readable_widthad-1 downto 0);
		ext_d: in std_logic_vector(width-1 downto 0);
		resultfifo_full,resultfifo_empty : out std_logic_vector(external_readable_blocks-1 downto 0);
		int_d : in std_logic_vector(external_readable_blocks*width-1 downto 0);
		ext_q,instrfifo_q : out std_logic_vector(width-1 downto 0);
		int_q : out std_logic_vector(external_writeable_blocks*width-1 downto 0);
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
		almost_full_value		:natural;
		allow_wrcycle_when_full	:string;
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
		rdreq		: in std_logic;
		aclr		: in std_logic;
		empty		: out std_logic;
		clock		: in std_logic;
		q			: out std_logic_vector(lpm_width-1 downto 0);
		wrreq		: in std_logic;
		data		: in std_logic_vector(lpm_width-1 downto 0);
		almost_full : out std_logic;
		full		: out std_logic
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
	signal s0ext_wr,s0ext_rd	: std_logic;
	signal s0ext_d				: std_logic_vector(width-1 downto 0);
	signal s0ext_rd_ack			: std_logic_vector(external_readable_blocks-1 downto 0);
	signal s0ext_q,sint_d		: vectorblock08;
	signal sint_rd_add			: vectorblock02;
	signal s1int_q				: vectorblock12;

begin 

	dpfifo : scfifo --! Debe ir registrada la salida.
	generic	map ("ON",9,"OFF","Cyclone III","RAM_BLOCK_TYPE=M9K",16,"OFF","SCFIFO",64,4,"OFF","OFF","ON")
	port	map (dpfifo_rd,dpfifo_flush,dpfifo_empty,clk,dpfifo_q,dpfifo_wr,dpfifo_d,dpfifo_full);
	normfifo : scfifo
	generic map ("ON",23,"OFF","Cyclone III","RAM_BLOCK_TYPE=M9K",32,"OFF","SCFIFO",96,5,"OFF","OFF","ON")
	port	map (normfifo_rd,normfifo_flush,normfifo_empty,clk,normfifo_q,normfifo_wr,normfifo_d,normfifo_full);
	instrfifo : scfifo
	generic map ("ON",31,"ON","Cyclone III","RAM_BLOCK_TYPE_M9K",32,"OFF","SCIFIFO",32,5,"ON","OFF","ON")
	port 	map (instrfifo_rd,instrfifo_flush,instrfifo_empty,clk,instrfifo_q,instrfifo_wr,instrfifo_d,instrfifo_full);
	
	
	sint_rd_add (0)<= int_rd_add(widthadmemblock-1 downto 0);
	sint_rd_add (1)<= int_rd_add(2*widthadmemblock-1 downto widthadmemblock);
	
	results_blocks: 
	for i in 7 downto 0 generate
		sint_d(i) <= int_d((i+1)*width-1 downto i*width);
		resultsfifo : scfifo
		generic map	("ON",511,"ON","Cyclone III","RAM_BLOCK_TYPE_M9K",512,"OFF","SCIFIFO",32,9,"ON","OFF","ON")
		port	map (s0ext_rd_ack(i),resultfifo_flush,resultfifo_empty(i),clk,s0ext_q(i),resultfifo_wr,sint_d(i),open,resultfifo_full(i));
--		resultsblock : altsyncram
--		generic map ("NONE","CLOCK0","BYPASS","BYPASS","BYPASS","Cyclone III","altsyncram",2**widthadmemblock,2**widthadmemblock,"DUAL_PORT","NONE","CLOCK0","FALSE","M9K","CLOCK0","OLD_DATA",widthadmemblock,widthadmemblock,width,width,1)
--		port	map (resultfifo_wr,clk,resultfifo_wr_add,ext_rd_add(widthadmemblock-1 downto 0),ext_rd,s1ext_q(i),sint_d(i));
	end generate results_blocks;
	
	operands_blocks: 
	for i in 11 downto 0 generate
		int_q((i+1)*width-1 downto width*i) <= s1int_q(i);
		operandsblock : altsyncram
		generic map ("NONE","CLOCK0","BYPASS","BYPASS","BYPASS","Cyclone III","altsyncram",2**widthadmemblock,2**widthadmemblock,"DUAL_PORT","NONE","CLOCK0","FALSE","M9K","CLOCK0","OLD_DATA",widthadmemblock,widthadmemblock,width,width,1)
		port 	map (s0ext_wr_add_one_hot(i),clk,s0ext_wr_add(widthadmemblock-1 downto 0),sint_rd_add((i/3) mod 2),'1',s1int_q(i),s0ext_d);
	end generate operands_blocks;
	
	
	operands_block_proc: process (clk,ena)
	begin
		if clk'event and clk='1' and ena='1' then
			 --! Registro de entrada
			 s0ext_wr_add <= ext_wr_add;
			 s0ext_wr  <= ext_wr;
			 s0ext_d  <= ext_d;		
		end if;
	end process;
	operands_block_comb: process (s0ext_wr_add,s0ext_wr)
	begin
	
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
	
	end process;
	results_block_proc: process(clk,ena)
	begin
		if clk'event and clk='1' and ena='1' then
			--!Registrar entrada
			s0ext_rd_add	<= ext_rd_add;
			s0ext_rd		<= ext_rd;	
			--!Etapa 0: Decodificar la cola que se va a mover (rdack! fifo showahead mode) y por ende leer ese dato.
			case '0'&s0ext_rd_add is
				when x"0" => ext_q <= s0ext_q(0); 
				when x"1" => ext_q <= s0ext_q(1);
				when x"2" => ext_q <= s0ext_q(2);
				when x"3" => ext_q <= s0ext_q(3);
				when x"4" => ext_q <= s0ext_q(4);
				when x"5" => ext_q <= s0ext_q(5);
				when x"6" => ext_q <= s0ext_q(6);
				when others => ext_q <= s0ext_q(7);
			end case;			
		end if;
	end process;
	results_block_proc_combinatorial_stage: process(s0ext_rd,s0ext_rd_add)
	begin
		case '0'&s0ext_rd_add is 
			when x"0" => s0ext_rd_ack <= x"0"&"000"&s0ext_rd;
			when x"1" => s0ext_rd_ack <= x"0"&"00"&s0ext_rd&'0';
			when x"2" => s0ext_rd_ack <= x"0"&"0"&s0ext_rd&"00";
			when x"3" => s0ext_rd_ack <= x"0"&s0ext_rd&"000";
			when x"4" => s0ext_rd_ack <= "000"&s0ext_rd&x"0";
			when x"5" => s0ext_rd_ack <= "00"&s0ext_rd&'0'&x"0";
			when x"6" => s0ext_rd_ack <= "0"&s0ext_rd&"00"&x"0";
			when others => s0ext_rd_ack <= s0ext_rd&"000"&x"0";
		end case;	
	end process;
end memblock_arch;

