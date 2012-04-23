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
use work.arithpack.all;

entity memblock is 
	generic (
		
		blocksize : integer := 512;
			
		external_readable_widthad	: integer := 3;				
		external_writeable_widthad	: integer := 4		
	);
	port (
		
		clk,rst,dpfifo_rd,normfifo_rd,dpfifo_wr,normfifo_wr : in std_logic;
		instrfifo_rd : in std_logic;
		resultfifo_wr: in std_logic_vector(8-1 downto 0);
		instrfifo_empty: out std_logic; 
		ext_rd,ext_wr: in std_logic;
		ext_wr_add : in std_logic_vector(4+widthadmemblock-1 downto 0);		
		ext_rd_add : in std_logic_vector(2 downto 0);
		ext_d: in std_logic_vector(floatwidth-1 downto 0);
		resultfifo_full  : out std_logic_vector(3 downto 0);
		int_d : in vectorblock08;
		
		--!Python
		ext_q,instrfifo_q : out std_logic_vector(floatwidth-1 downto 0);
		int_q : out vectorblock12; 
		int_rd_add : in std_logic_vector(2*widthadmemblock-1 downto 0);
		dpfifo_d : in std_logic_vector(floatwidth*2-1 downto 0);
		normfifo_d : in std_logic_vector(floatwidth*3-1 downto 0);
		dpfifo_q : out std_logic_vector(floatwidth*2-1 downto 0);
		normfifo_q : out std_logic_vector(floatwidth*3-1 downto 0)
	);
end entity;

architecture memblock_arch of memblock is 

	
	
	
	
	--!TXBXSTART:MEMBLOCK_EXTERNAL_WRITE
	signal s0ext_wr_add_one_hot : std_logic_vector(12-1+1 downto 0); --! La se&ntilde;al extra es para la escritura de la cola de instrucciones.
	signal s0ext_wr_add			: std_logic_vector(4+widthadmemblock-1 downto 0);
	signal s0ext_wr				: std_logic;
	signal s0ext_d				: std_logic_vector(floatwidth-1 downto 0);
	--!TBXEND
	--! Se&ntilde;al de soporte
	signal s0ext_wr_add_choice	: std_logic_vector(3 downto 0);
	
	--!TXBXSTART:MEMBLOCK_EXTERNAL_READ
	signal s0ext_rd_add			: std_logic_vector(2 downto 0);
	signal s0ext_rd				: std_logic;
	signal s0ext_rd_ack			: std_logic_vector(8-1 downto 0);
	signal s0ext_q				: vectorblock08;
	--!TBXEND
	--! Se&ntilde;al de soporte
	signal s0ext_rd_add_choice	: std_logic_vector(3 downto 0);
	
	
	--!TBXSTART:MEMBLOCK_INTERNAL_READ
	signal sint_rd_add			: vectorblockadd02;
	signal s1int_q				: vectorblock12;
	--!TBXEND
	
	--!TXBXSTART:MEMBLOCK_INTERNAL_WRITE
	signal sint_d				: vectorblock08;
	signal sresultfifo_full		: std_logic_vector(7 downto 0);
	--!TBXEND

begin 

	--! Cola interna de producto cccccpunto, ubicada entre el pipe line aritm&eacute;co. 
	q0q1 : scfifo --! Debe ir registrada la salida.
	generic map (
		add_ram_output_register	=> "OFF",
		allow_rwcycle_when_full => "OFF",
		intended_device_family	=> "CycloneIII",
		lpm_hint				=> "RAM_BLOCK_TYPE=M9K",
		almost_full_value		=> 8,
		lpm_numwords			=> 8,
		lpm_showahead			=> "ON",
		lpm_type				=> "SCIFIFO",
		lpm_width				=> 64,
		lpm_widthu				=> 3,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		rdreq		=> dpfifo_rd,
		aclr		=> '0',
		empty		=> open,
		clock		=> clk,
		q			=> dpfifo_q,
		wrreq		=> dpfifo_wr,
		data		=> dpfifo_d
	);
	
	--! Cola interna de normalizaci&oacute;n de vectores, ubicada entre el pipeline aritm&eacute;tico
	qxqyqz : scfifo
	generic map (
		add_ram_output_register => "OFF",
		allow_rwcycle_when_full => "OFF",
		intended_device_family  => "Cyclone III",
		lpm_hint                => "RAM_BLOCK_TYPE=M9K",
		almost_full_value		=> 32,
		lpm_numwords			=> 32,
		lpm_showahead			=> "ON",
		lpm_type				=> "SCFIFO",
		lpm_width				=> 96,
		lpm_widthu				=> 5,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		rdreq		=> normfifo_rd,
		aclr		=> '0',
		empty	 	=> open,
		clock		=> clk,
		q			=> normfifo_q,
		wrreq		=> normfifo_wr,
		data		=> normfifo_d,
		almost_full => open,
		full		=> open
	);
	
	--! Cola de instrucciones 
	qi : scfifo
	generic map (
		add_ram_output_register => "OFF",
		allow_rwcycle_when_full => "OFF",
		intended_device_family	=> "Cyclone III",
		lpm_hint				=> "RAM_BLOCK_TYPE=M9K",
		almost_full_value		=> 32,
		lpm_numwords			=> 32,
		lpm_showahead			=> "ON",
		lpm_type				=> "SCIFIFO",
		lpm_width				=> 32,
		lpm_widthu				=> 5,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port 	map (
		rdreq		=> instrfifo_rd,
		aclr		=> '0',
		empty		=> instrfifo_empty,
		clock		=> clk,
		q			=> instrfifo_q,
		wrreq		=> s0ext_wr_add_one_hot(12),
		data		=> s0ext_d,
		almost_full => open
	);
	
	--! Conectar los registros de lectura interna del bloque de operandos a los arreglos > abstracci&oacute:n de c&oacute;digo, no influye en la sintesis del circuito.
	sint_rd_add (0)<= int_rd_add(widthadmemblock-1 downto 0);
	sint_rd_add (1)<= int_rd_add(2*widthadmemblock-1 downto widthadmemblock);
	
	--! Instanciaci&oacute;n de la cola de resultados de salida.
	int_q <= s1int_q;
	operands_blocks: 
	for i in 11 downto 0 generate
		--!int_q((i+1)*floatwidth-1 downto floatwidth*i) <= s1int_q(i);
		operandsblock : altsyncram
		generic map (
			address_aclr_b 						=> "NONE",
			address_reg_b						=> "CLOCK0",
			clock_enable_input_a				=> "BYPASS",
			clock_enable_input_b				=> "BYPASS",
			clock_enable_output_b				=> "BYPASS",
			intended_device_family				=> "Cyclone III",
			lpm_type							=> "altsyncram",
			numwords_a							=> 2**widthadmemblock,
			numwords_b							=> 2**widthadmemblock,
			operation_mode						=> "DUAL_PORT",
			outdata_aclr_b						=> "NONE",
			outdata_reg_b						=> "CLOCK0",
			power_up_uninitialized				=> "FALSE",
			ram_block_type						=> "M9K",
			rdcontrol_reg_b						=> "CLOCK0",
			read_during_write_mode_mixed_ports	=> "OLD_DATA",
			widthad_a							=> widthadmemblock,
			widthad_b							=> widthadmemblock,
			width_a								=> floatwidth,
			width_b								=> floatwidth,
			width_byteena_a						=> 1
		)
		port map (
			wren_a		=> s0ext_wr_add_one_hot(i),
			clock0		=> clk,
			address_a	=> s0ext_wr_add(widthadmemblock-1 downto 0),
			address_b	=> sint_rd_add((i/3) mod 2),
			rden_b		=> '1',
			q_b			=> s1int_q(i),
			data_a		=> s0ext_d
		);
	end generate operands_blocks;
	
	--! Instanciaci&oacute;n de la cola de resultados.
	resultfifo_full(3) <= sresultfifo_full(7) or sresultfifo_full(6) or sresultfifo_full(5);
	resultfifo_full(2) <= sresultfifo_full(4) or sresultfifo_full(2);
	resultfifo_full(1) <= sresultfifo_full(3) or sresultfifo_full(2) or sresultfifo_full(1);
	resultfifo_full(0) <= sresultfifo_full(0);  
	sint_d <= int_d;
	results_blocks: 
	for i in 7 downto 0 generate
		resultsfifo : scfifo
		generic map	(
			add_ram_output_register => "OFF",
			almost_full_value 		=> 480,
			allow_rwcycle_when_full => "OFF",
			intended_device_family	=> "Cyclone III",
			lpm_hint				=> "RAM_BLOCK_TYPE=M9K",
			lpm_numwords			=> 512,
			lpm_showahead			=> "ON",
			lpm_type				=> "SCIFIFO",
			lpm_width				=> 32,
			lpm_widthu				=> 9,
			overflow_checking		=> "ON",
			underflow_checking		=> "ON",
			use_eab					=> "ON"
		)
		port	map (
			rdreq		=> s0ext_rd_ack(i),
			aclr		=> '0',
			empty		=> open,
			clock		=> clk,
			q			=> s0ext_q(i),
			wrreq		=> resultfifo_wr(i),
			data		=> sint_d(i),
			almost_full	=> sresultfifo_full(i),
			full		=> open
		);
	end generate results_blocks;
	
	--! Escritura en registros de operandos de entrada.
	operands_block_proc: process (clk,rst)
	begin
		if rst=rstMasterValue then
			s0ext_wr_add	<= (others => '0');
			s0ext_wr 		<= '0';
			s0ext_d			<= (others => '0'); 
		elsif clk'event and clk='1' then
			--! Registro de entrada
			s0ext_wr_add <= ext_wr_add;
			s0ext_wr  <= ext_wr;
			s0ext_d  <= ext_d;		
		end if;
	end process;
	
	--! Decodificaci&oacute;n de se&ntilde;al escritura x bloque de memoria, selecciona la memoria en la que se va a escribir a partir de la direcci&oacute;n de entrada.
	s0ext_wr_add_choice <= s0ext_wr_add(4+widthadmemblock-1 downto widthadmemblock);
	operands_block_comb: process (s0ext_wr_add_choice,s0ext_wr)
	begin
	
		--! Etapa 0: Decodificacion de las se&ntilde:ales de escritura.Revisar el capitulo de bloques de memoria para chequear como est&aacute; el pool de direcciones por bloques de vectores.
		--! Las direcciones de bloque 3,7,11,15 corresponden a la cola de instrucciones.
		case s0ext_wr_add_choice is
			when "0000" => 
				s0ext_wr_add_one_hot <= '0'&x"00"&"000"&s0ext_wr;
			when x"1" => 
				s0ext_wr_add_one_hot <= '0'&x"00"&"00"&s0ext_wr&'0';
			when x"2" => 
				s0ext_wr_add_one_hot <= '0'&x"00"&'0'&s0ext_wr&"00";
			when x"4" => 
				s0ext_wr_add_one_hot <= '0'&x"00"&s0ext_wr&"000";
			when x"5" => 
				s0ext_wr_add_one_hot <= '0'&x"0"&"000"&s0ext_wr&x"0";
			when x"6" => 
				s0ext_wr_add_one_hot <= '0'&x"0"&"00"&s0ext_wr&'0'&x"0";
			when x"8" => 
				s0ext_wr_add_one_hot <= '0'&x"0"&'0'&s0ext_wr&"00"&x"0";
			when x"9" => 
				s0ext_wr_add_one_hot <= '0'&x"0"&s0ext_wr&"000"&x"0";
			when x"A" => 
				s0ext_wr_add_one_hot <= '0'&"000"&s0ext_wr&x"00";
			when x"C" => 
				s0ext_wr_add_one_hot <= '0'&"00"&s0ext_wr&'0'&x"00";
			when x"D" => 
				s0ext_wr_add_one_hot <= '0'&'0'&s0ext_wr&"00"&x"00";
			when x"E" => 
				s0ext_wr_add_one_hot <= '0'&s0ext_wr&"000"&x"00";
			when others => 
				s0ext_wr_add_one_hot <= s0ext_wr&x"000";
		end case;
	
	end process;
	
	--! Decodificaci&oacute;n para seleccionar que cola de resultados se conectar&acute; a la salida del RayTrac. 
	s0ext_rd_add_choice <= '0'&s0ext_rd_add;
	results_block_proc: process(clk,rst)
	begin
		if rst=rstMasterValue then
			s0ext_rd_add	<= (others => '0');
			s0ext_rd 		<= '0';
		elsif clk'event and clk='1' then
			--!Registrar entrada
			s0ext_rd_add	<= ext_rd_add;
			s0ext_rd		<= ext_rd;	
			--!Etapa 0: Decodificar la cola que se va a mover (rdack! fifo showahead mode) y por ende leer ese dato.
			case s0ext_rd_add_choice is
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
	
	--! rdack decoder para las colas de resultados de salida.
	results_block_proc_combinatorial_stage: process(s0ext_rd,s0ext_rd_add_choice)
	begin
		case s0ext_rd_add_choice is 
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
end architecture;

