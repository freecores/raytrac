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
		
			
		external_readable_widthad	: integer := 3;				
		external_writeable_widthad	: integer := 4		
	);
	port (
		
		qempty	: out std_logic_vector (4 downto 0); --! Res0:0 Res1:1 Res2:2 Res3:3 Prm:4 
		clk,rst,dpfifo_rd,normfifo_rd,dpfifo_wr,normfifo_wr : in std_logic;
		resultfifo_wr: in std_logic_vector(3 downto 0);
		ext_rd,ext_wr: in std_logic;
		
		ext_d: in xfloat32;
		int_d : in vectorblock04;
		status_register : in std_logic_vector(3 downto 0);
				
		ext_q: out xfloat32;
		int_q : out vectorblock06;
		
		 
		address : in std_logic_vector(1 downto 0);
		
		dpfifo_d : in std_logic_vector(floatwidth*2-1 downto 0);
		normfifo_d : in std_logic_vector(floatwidth*3-1 downto 0);
		dpfifo_q : out std_logic_vector(floatwidth*2-1 downto 0);
		normfifo_q : out std_logic_vector(floatwidth*3-1 downto 0)
	);
end entity;

architecture memblock_arch of memblock is 

	
	

	--!TBXSTART:LOAD_CHAIN
	signal sparams_chain		: std_logic_vector (5 downto 0);
	signal sparams_load			: std_logic_vector (5 downto 0);
	signal scomb				: std_logic;
	signal sgo					: std_logic;
	signal sqparams_q			: xfloat32;
	signal s1int_q				: vectorblock06;
	signal sload_params_cfg		: std_logic;
	signal sqparams_not_empty	: std_logic;
	signal sqparams_empty		: std_logic;
	--!TBXEND 
	
	
	--!TXBXSTART:MEMBLOCK_EXTERNAL_WRITE
	signal s0ext_wr				: std_logic;
	signal s0ext_d				: std_logic_vector(floatwidth-1 downto 0);
	--!TBXEND
	--! Se&ntilde;al de soporte
	signal s0ext_wr_add_choice	: std_logic_vector(3 downto 0);
	
	--!TXBXSTART:MEMBLOCK_EXTERNAL_READ
	signal s0status_register	: std_logic_vector(7 downto 0);
	signal s0ext_rd_add			: std_logic_vector(3 downto 0);
	signal s0ext_rd				: std_logic;
	signal s0ext_rd_ack			: std_logic_vector(8-1 downto 0);
	signal s0ext_q				: vectorblock08;
	--!TBXEND
	
	
	
	--!TXBXSTART:MEMBLOCK_INTERNAL_WRITE
	signal sint_d				: vectorblock08;
	signal sresultfifo_full		: std_logic_vector(7 downto 0);
	--!TBXEND

begin 
	
	
	load_chain_proc: process (clk,rst,sparams_chain,sparams_load,sload_params_cfg,scomb,sgo,sparams_unload)
	begin
		if rst=rstMasterValue then
			--!LD Section
			sparams_chain <= (others => '0');
			for i in 5 downto 0 loop
				s1int_q <= (others => '0');
			end loop;
			
			
			
		elsif clk'event and clk='1' then
			--LOAD SECTION COMBINATORIAL CIRCUIT
			--! Ax enabler.	
			if sload_params_cfg='1' then
				sparams_chain(0) <= sparams_load(0);
			elsif sgo='1' then
				sparams_chain(0) <= sparams_chain(5) and not(scomb);
			else
				sparams_chain(0) <= sparams_chain(0);
			end if;
			--! Ay Az By Bz Enabler.
			for i in 2 downto 1 loop
				if sload_params_cfg='1' then
					sparams_chain(i) <= sparams_load(i);
					sparams_chain(i+3) <= sparams_load(i+3);
				elsif sgo='1' tjem
					sparams_chain(i) <= sparams_chain(i-1);
					sparams_chain(i+3) <= sparams_chain(i-2);
				else
					sparams_chain(i) <= sparams_chain(i);
					sparams_chain(i+3) <= sparams_chain(i+3);
				end if;
			end loop;
			--! Bx enabler.	
			if sload_params_cfg='1' then
				sparams_chain(3) <= sparams_load(3);
			elsif sgo='1' then
			
				if scomb='1' then
					sparams_chain(3) <= sparams_chain(5);
				else
					sparams_chain(3) <= sparams_chain(2);
				end if;
			else
				sparams_chain(3) <= sparams_chain(3);
			end if;
			
			for i in 5 downto 0 loop
				if sparams_chain(i)='1' then
					s1int_q(i) <= sqparams_q;
				end if;
			end loop;
			
			
			
					
			
		end if 
	end process; 
	
	--! Instanciaci&oacute;n de la cola de resultados de salida.
	int_q <= s1int_q;
	qempty(4) <= sqparams_empty;
	sgo <= not(sqparams_empty); 
	qparams : scififo
	generic map(
		add_ram_output_register => "OFF",
		allow_rwcycle_when_full => "OFF",
		intended_device_family	=> "Cyclone III",
		lpm_hint				=> "RAM_BLOCK_TYPE=M9K",
		lpm_numwords			=> 256,
		lpm_showahead			=> "ON",
		lpm_type				=> "SCIFIFO",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
		
	)
	port map (
		rdreq 	=> 
		aclr 	=> '0',
		empty	=> qparams_empty,
		clock 	=> clk,
		q		=> sqparams_q,
		wrreq	=> ext_wr,
		data	=> ext_d
		   
	)
	--! Instanciaci&oacute;n de la cola de resultados.
	resultfifo_full(3) <= sresultfifo_full(7) or sresultfifo_full(6) or sresultfifo_full(5);
	resultfifo_full(2) <= sresultfifo_full(4) or sresultfifo_full(2);
	resultfifo_full(1) <= sresultfifo_full(3) or sresultfifo_full(2) or sresultfifo_full(1);
	resultfifo_full(0) <= sresultfifo_full(0);  
	sint_d <= int_d;
	results_blocks: 
	for i in 3 downto 0 generate
		resultsfifo : scfifo
		generic map	(
			add_ram_output_register => "OFF",
			allow_rwcycle_when_full => "OFF",
			intended_device_family	=> "Cyclone III",
			lpm_hint				=> "RAM_BLOCK_TYPE=M9K",
			lpm_numwords			=> 256,
			lpm_showahead			=> "ON",
			lpm_type				=> "SCIFIFO",
			lpm_width				=> 32,
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
	
	
	
	--! Decodificaci&oacute;n para seleccionar que cola de resultados se conectar&acute; a la salida del RayTrac. 
	
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
			case s0ext_rd_add is
				when x"0" => ext_q <= s0ext_q(0); 
				when x"1" => ext_q <= s0ext_q(1);
				when x"2" => ext_q <= s0ext_q(2);
				when x"3" => ext_q <= s0ext_q(3);
				when x"4" => ext_q <= s0ext_q(4);
				when x"5" => ext_q <= s0ext_q(5);
				when x"6" => ext_q <= s0ext_q(6);
				when x"7" => ext_q <= s0ext_q(7);
				when others => ext_q <= x"000000"&s0status_register;
			end case;			
		end if;
	end process;
	
	--! rdack decoder para las colas de resultados de salida.
	results_block_proc_combinatorial_stage: process(s0ext_rd,s0ext_rd_add)
	begin
		case s0ext_rd_add(3 downto 0) is 
			when x"0" => s0ext_rd_ack <= x"0"&"000"&s0ext_rd;
			when x"1" => s0ext_rd_ack <= x"0"&"00"&s0ext_rd&'0';
			when x"2" => s0ext_rd_ack <= x"0"&"0"&s0ext_rd&"00";
			when x"3" => s0ext_rd_ack <= x"0"&s0ext_rd&"000";
			when x"4" => s0ext_rd_ack <= "000"&s0ext_rd&x"0";
			when x"5" => s0ext_rd_ack <= "00"&s0ext_rd&'0'&x"0";
			when x"6" => s0ext_rd_ack <= "0"&s0ext_rd&"00"&x"0";
			when x"7" => s0ext_rd_ack <= s0ext_rd&"000"&x"0";
			when others => s0ext_rd_ack <= (others => '0');
		end case;	
	end process;
	
	--!Proceso para escribir el status register.
	
	--!Independiente del valor rfull(i) o si se lee o no, los bits correspondientes a los eventos de cola de resultados llena, se escriben reloj a reloj.
	--!Final de Instrucci&oacute;n: Si ocurre un evento de final de instrucci&oacute;n se escribe el bit de registro correspondiente. 
	--!Si no hay un evento de final de instrucci&oacute;n entonces se verifica si hay un evento de lectura del status register, si es asi todos los bits correspondientes dentro del registro al evento de fin de instrucci&oacute;n se borran y quedan en cero.
	--!Si no hay un evento de final de instrucci&oacite;n y tampoco de lectura del status register entonces se deja el mismo valor del estatus register.
	sreg_proc: process (clk,rst,s0ext_rd_add,status_register(3 downto 0))
	begin
		if rst=rstMasterValue then
			s0status_register(7 downto 0) <= (others => '0');
		elsif clk'event and clk='1' then 

			--!Sin importar el valor de las se&ntilde;ales de cola de resultados llena, escribir el registro.
			s0status_register(7) <= sresultfifo_full(7) or sresultfifo_full(6) or sresultfifo_full(5);
			s0status_register(6) <= sresultfifo_full(4) or sresultfifo_full(2);
			s0status_register(5) <= sresultfifo_full(3) or sresultfifo_full(2) or sresultfifo_full(1);
			s0status_register(4) <= sresultfifo_full(0);  
			
			for i in 3 downto 0 loop
				--! Si hay evento de fin de instrucci&oacute;n entonces escribir en el bit correspondiente un uno.
				if status_register(i)='1' then
					s0status_register(i) <= '1';
				--! Como no hubo final de instrucci&oacute;n revisar si hay lectura de Status Register y borrarlo.
				elsif s0ext_rd_add(3)='1' then 
					s0status_register(i) <= '0';
				--! No ocurrio nada de lo anterior, dejar entonces en el mismo valor el Status Register.
				else
					s0status_register(i) <= s0status_register(i);
				end if;
			end loop;
		end if;
	end process;
	
	--! Colas internas de producto punto, ubicada en el pipe line aritm&eacute;co. Paralelo a los sumadores a0 y a2.  
	q0q1 : scfifo --! Debe ir registrada la salida.
	generic map (
		add_ram_output_register	=> "OFF",
		allow_rwcycle_when_full => "OFF",
		intended_device_family	=> "CycloneIII",
		lpm_hint				=> "MAXIMUM_DEPTH=8",
		almost_full_value		=> 8,
		lpm_numwords			=> 8,
		lpm_showahead			=> "ON",
		lpm_type				=> "SCIFIFO",
		lpm_width				=> 64,
		lpm_widthu				=> 3,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "OFF"
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
		lpm_showahead			=> "OFF",
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
	
end architecture;

