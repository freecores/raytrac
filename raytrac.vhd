--! @file raytrac.vhd
--! @brief Archivo con el RTL que describe al RayTrac en su totalidad.
 
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

entity raytrac is
	port (
		
		clk : in std_logic;
		rst : in std_logic;
		
		--! Se&ntilde;al de lectura de alguna de las colas de resultados.
		rd	: in std_logic;
		
		--! Se&ntilde;al de escritura en alguno de los bloques de memoria de operandos o en la cola de instrucciones.
		wr	: in std_logic;
		
		--! Direccion de escritura o lectura
		add : in std_logic_vector (12 downto 0);
		
		--! datos de entrada
		d	: in std_logic_vector (31 downto 0);
		
		--! Interrupciones
		int	: out std_logic_vector (7 downto 0);
		
		--! Salidas
		q : out std_logic_vector (31 downto 0)
		
				
	);
end entity;

architecture raytrac_arch of raytrac is 

--! Definicion de Tipos y de Constantes
	constant rstMasterValue : std_logic := '0';
	
--! Definición de componentes del sistema.

	--! Bloque de memorias
	component memblock
	generic ( 
		width						: integer;
		blocksize					: integer;
		widthadmemblock				: integer;
		external_writeable_blocks 	: integer;
		external_readable_blocks  	: integer;
		external_readable_widthad	: integer;				
		external_writeable_widthad	: integer
	);
	port (
		
		
		clk,rst,dpfifo_rd,normfifo_rd,dpfifo_wr,normfifo_wr : in std_logic;
		instrfifo_rd : in std_logic;
		resultfifo_wr: in std_logic_vector(external_readable_blocks-1 downto 0);
		instrfifo_empty: out std_logic; ext_rd,ext_wr: in std_logic;
		ext_wr_add : in std_logic_vector(external_writeable_widthad+widthadmemblock-1 downto 0);		
		ext_rd_add : in std_logic_vector(external_readable_widthad-1 downto 0);
		ext_d: in std_logic_vector(width-1 downto 0);
		int_d : in std_logic_vector(external_readable_blocks*width-1 downto 0);
		resultfifo_full  : out std_logic_vector(3 downto 0);
		ext_q,instrfifo_q : out std_logic_vector(width-1 downto 0);
		int_q : out std_logic_vector(external_writeable_blocks*width-1 downto 0);
		int_rd_add : in std_logic_vector(2*widthadmemblock-1 downto 0);
		dpfifo_d : in std_logic_vector(width*2-1 downto 0);
		normfifo_d : in std_logic_vector(width*3-1 downto 0);
		dpfifo_q : out std_logic_vector(width*2-1 downto 0);
		normfifo_q : out std_logic_vector(width*3-1 downto 0)
	);	
	end component;
	--! Bloque decodificacion DataPath Control.
	component dpc
	generic (
		width : integer
	);
	port (
		clk,rst					: in	std_logic;
		paraminput				: in	std_logic_vector ((12*width)-1 downto 0);	--! Vectores A,B,C,D
		prd32blko			 	: in	std_logic_vector ((06*width)-1 downto 0);	--! Salidas de los 6 multiplicadores.
		add32blko 				: in	std_logic_vector ((04*width)-1 downto 0);	--! Salidas de los 4 sumadores.
		sqr32blko,inv32blko		: in	std_logic_vector (width-1 downto 0);		--! Salidas de la raiz cuadradas y el inversor.
		fifo32x23_q				: in	std_logic_vector (03*width-1 downto 0);		--! Salida de la cola intermedia.
		fifo32x09_q				: in	std_logic_vector (02*width-1 downto 0); 	--! Salida de las colas de producto punto. 
		unary,crossprod,addsub	: in	std_logic;									--! Bit con el identificador del bloque AB vs CD e identificador del sub bloque (A/B) o (C/D). 
		sync_chain_0			: in	std_logic;									--! Señal de dato valido que se va por toda la cadena de sincronizacion.
		eoi_int					: in 	std_logic;									--! Sennal de interrupción de final de instrucción.
		eoi_demuxed_int			: out	std_logic_vector (3 downto 0);				--! Señal de interrupción de final de instrucción pero esta vez va asociada a la instruccón UCA.
		sqr32blki,inv32blki		: out	std_logic_vector (width-1 downto 0);		--! Salidas de las 2 raices cuadradas y los 2 inversores.
		fifo32x26_d				: out	std_logic_vector (03*width-1 downto 0);		--! Entrada a la cola intermedia para la normalizaci&oacute;n.
		fifo32x09_d				: out	std_logic_vector (02*width-1 downto 0);		--! Entrada a las colas intermedias del producto punto.  	
		prd32blki				: out	std_logic_vector ((12*width)-1 downto 0);	--! Entrada de los 12 factores en el bloque de multiplicaci&oacute;n respectivamente.
		add32blki				: out	std_logic_vector ((08*width)-1 downto 0);	--! Entrada de los 8 sumandos del bloque de 4 sumadores.  
		resw					: out	std_logic_vector (4 downto 0);				--! Salidas de escritura y lectura en las colas de resultados.
		fifo32x09_w				: out	std_logic;
		fifo32x23_w,fifo32x09_r	: out	std_logic;
		fifo32x23_r				: out	std_logic;
		resf_vector				: in 	std_logic_vector(3 downto 0);				--! Entradas de la se&ntilde;al de full de las colas de resultados. 
		resf_event				: out	std_logic;									--! Salida decodificada que indica que la cola de resultados de la operaci&oacute;n que est&aacute; en curso.
		resultoutput			: out	std_logic_vector ((08*width)-1 downto 0) 	--! 8 salidas de resultados, pues lo m&aacute;ximo que podr&aacute; calcularse por cada clock son 2 vectores.
	);
	end component;
	--! Bloque Aritmetico de Sumadores y Multiplicadores (madd)
	component arithblock
	port (
		
		clk	: in std_logic;
		rst : in std_logic;
	
		dpc : in std_logic;
	
		f	: in std_logic_vector (12*32-1 downto 0);
		a	: in std_logic_vector (8*32-1 downto 0);
		
		s	: out std_logic_vector (4*32-1 downto 0);
		p	: out std_logic_vector (6*32-1 downto 0)
			
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
	--! Maquina de Estados.
	component sm
	generic (
		width : integer ;
		widthadmemblock : integer 
		--!external_readable_widthad : 				
	);
	port (
		
		--! Se&ntilde;ales normales de secuencia.
		clk,rst:			in std_logic;
		--! Vector con las instrucción codficada
		instrQq:in std_logic_vector(width-1 downto 0);
		--! Señal de cola vacia.
		instrQ_empty:in std_logic;
		
				
		adda,addb:out std_logic_vector (widthadmemblock-1 downto 0);
		sync_chain_0,instrRdAckd:out std_logic;
		
		
		full_r: 	in std_logic;	--! Indica que la cola de resultados no puede aceptar mas de 32 elementos.
	
		
		
		--! End Of Instruction Event
		eoi	: out std_logic;
		
		--! DataPath Control uca code.
		dpc_uca : out std_logic_vector (2 downto 0)
	);
	end component;
	--! Maquina de Interrupciones
	component im 
	generic (
		num_events : integer ;
		cycles_to_wait : integer 
	);
	port (
		clk,rst:		in std_logic;
		rfull_events:	in std_logic_vector(num_events-1 downto 0);	--! full results queue events
		eoi_events:		in std_logic_vector(num_events-1 downto 0);	--! end of instruction related events
		eoi_int:		out std_logic_vector(num_events-1 downto 0);--! end of instruction related interruptions
		rfull_int:		out std_logic_vector(num_events-1downto 0)	--! full results queue related interruptions
		
	);
	end component;
	
	
	--! Se&ntilde;ales de Memblock -> State Machine
	signal s_iq_empty		: std_logic; 
	signal s_iq				: std_logic_vector (31 downto 0);
	

	--! Se&ntilde;ales de Memblock -> Interruption Machine
	signal s_rfull_events 	: std_logic_vector (3 downto 0); --Estas se&ntilde;ales tambien entran a DPC.
	
	--! Se&ntilde;ales de Memblock -> DPC.
	signal s_q				: std_logic_vector (12*32-1 downto 0);
	signal s_normfifo_q		: std_logic_vector (3*32-1 downto 0);
	signal s_dpfifo_q		: std_logic_vector (2*32-1 downto 0);
	
	--! Se&ntilde;ales de State Machine -> Memblock
	signal s_adda			: std_logic_vector (8 downto 0);
	signal s_addb			: std_logic_vector (8 downto 0);
	signal s_iq_rd_ack		: std_logic;
	
	
	--! Se&ntilde;ales de State Machine -> DataPathControl
	signal s_sync_chain_0	: std_logic;
	signal s_dpc_uca		: std_logic_vector(2 downto 0);
	signal s_eoi			: std_logic;
	 
	--! Se&ntilde;ales de DataPathControl -> State Machine
	signal s_full_r			: std_logic;

	
	--! Se&ntilde;ales de State Machin a Interruption Machine.
	signal s_eoi_events		: std_logic_vector (3 downto 0);
	
	--! Se&ntilde;ales de DPC a ArithBlock
	signal s_f				: std_logic_vector (12*32-1 downto 0);
	signal s_a 				: std_logic_vector (8*32-1 downto 0);
	--! Parcialmente las se&ntilde;ales de salida de los sumadores van al data path control.
	signal s_s				: std_logic_vector (4*32-1 downto 0); 
	signal s_p				: std_logic_vector (6*32-1 downto 0);

	--! Se&ntilde;ales de DPC a sqrt32.
	signal s_rd32			: std_logic_vector (31 downto 0);
	signal s_sq32			: std_logic_vector (31 downto 0);

	--! Se&ntilde;ales de DPC  a invr32.
	signal s_dvd32			: std_logic_vector (31 downto 0);
	signal s_qout32			: std_logic_vector (31 downto 0);
	
	--! Se&ntilde que va desde DPC -> Memblock
	signal s_resultsfifo_w	: std_logic_vector (4 downto 0);
	signal s_dpfifo_w		: std_logic;
	signal s_dpfifo_r		: std_logic;
	signal s_dpfifo_d		: std_logic_vector (2*32-1 downto 0);
	signal s_normfifo_w		: std_logic;
	signal s_normfifo_r		: std_logic;
	signal s_results_d		: std_logic_vector (8*32-1 downto 0);
	signal s_normfifo_d		: std_logic_vector (3*32-1 downto 0);
	 	
begin
	--! Instanciar el bloque de memorias MEMBLOCK
	MemoryBlock : memblock
	generic map (
		width 						=> 32,
		blocksize 					=> 512,
		widthadmemblock		 		=> 9,
		external_writeable_blocks 	=> 12,
		external_readable_blocks	=> 8,
		external_readable_widthad	=> 3,				
		external_writeable_widthad	=> 4			
	)
	port map (
		clk					=> clk,
		rst					=> rst,
		dpfifo_rd			=> s_dpfifo_r,
		normfifo_rd			=> s_normfifo_r,
		dpfifo_wr			=> s_dpfifo_w,
		normfifo_wr			=> s_normfifo_w,
		instrfifo_rd		=> s_iq_rd_ack,
		resultfifo_wr		=> s_resultsfifo_w(4)&s_resultsfifo_w(4)&s_resultsfifo_w(4)&s_resultsfifo_w(3)&s_resultsfifo_w(2)&s_resultsfifo_w(1)&s_resultsfifo_w(2)&s_resultsfifo_w(0),
		instrfifo_empty		=> s_iq_empty,
		ext_rd				=> rd,
		ext_wr				=> wr,
		ext_wr_add			=> add,
		ext_rd_add			=> add(12 downto 10),
		ext_d				=> d,
		resultfifo_full		=> s_rfull_events,
		int_d				=> s_results_d,
		ext_q				=> q,
		instrfifo_q			=> s_iq,
		int_q				=> s_q,
		int_rd_add			=> s_addb&s_adda,
		dpfifo_d			=> s_dpfifo_d,
		normfifo_d			=> s_normfifo_d,
		dpfifo_q			=> s_dpfifo_q,
		normfifo_q			=> s_normfifo_q
	);

	--! Instanciar el bloque DPC
	DataPathControl_And_Syncronization_Block: dpc
	generic map (
		width => 32
	)
	port map (
		
		clk				=> clk,
		rst				=> rst,
		paraminput		=> s_q,
		prd32blko		=> s_p,
		add32blko		=> s_s,
		sqr32blko		=> s_sq32,
		inv32blko		=> s_qout32,
		fifo32x23_q		=> s_normfifo_q,
		fifo32x09_q		=> s_dpfifo_q,
		unary			=> s_dpc_uca(2),
		crossprod		=> s_dpc_uca(1),
		addsub			=> s_dpc_uca(0),
		sync_chain_0	=> s_sync_chain_0,
		eoi_int			=> s_eoi,
		eoi_demuxed_int => s_eoi_events,
		sqr32blki		=> s_rd32,
		inv32blki		=> s_dvd32,
		fifo32x26_d		=> s_normfifo_d,
		fifo32x09_d		=> s_dpfifo_d,
		prd32blki		=> s_f,
		add32blki		=> s_a,
		resw			=> s_resultsfifo_w,
		fifo32x09_w		=> s_dpfifo_w,
		fifo32x23_w		=> s_normfifo_w,
		fifo32x09_r		=> s_dpfifo_r,
		fifo32x23_r		=> s_normfifo_r,
		resf_vector		=> s_rfull_events,
		resf_event		=> s_full_r,
		resultoutput	=> s_results_d
	);
	

	--! Instanciar el bloque de inversion
	inversion_block : invr32
	port map (
		clk		=> clk,
		dvd32	=> s_dvd32,
		qout32	=> s_qout32
	);

	--! Instanciar el bloque de raíz cuadrada.
	square_root : sqrt32
	port map (
		clk 	=> clk,
		rd32	=> s_rd32,
		sq32	=> s_sq32 
	);
	
	
	--! Instanciar el bloque aritmético.
	arithmetic_block : arithblock
	port map (
		clk => clk,
		rst => rst,
		dpc => s_dpc_uca(1),
		f	=> s_f,
		a	=> s_a,
		s	=> s_s,
		p	=> s_p
	);
	 
	--! Instanciar la maquina de interrupciones
	interruption_machine : im
	generic map (
		num_events 		=> 4,
		cycles_to_wait	=> 1023 
	)
	port map (
		clk				=> clk,
		rst				=> rst,
		rfull_events	=> s_rfull_events,
		eoi_events		=> s_eoi_events,
		eoi_int 		=> int(3 downto 0),
		rfull_int		=> int(7 downto 4)
		
	);
	--!Instanciar la maquina de estados
	state_machine : sm
	generic map (
		width => 32,
		widthadmemblock => 9
	)
	port map (
		clk 			=> clk,
		rst 			=> rst,
		instrQq			=> s_iq,
		instrQ_empty	=> s_iq_empty,
		adda			=> s_adda,
		addb			=> s_addb,
		sync_chain_0	=> s_sync_chain_0,
		instrRdAckd		=> s_iq_rd_ack,
		full_r			=> s_full_r,
		eoi				=> s_eoi,
		dpc_uca			=> s_dpc_uca
	);
	

end architecture;
