library ieee;
use ieee.std_logic_1164.all;

--! Memory Compiler Library
library lpm;
use lpm.all;



package arithpack is
	--! Estados para la maquina de estados.
	type macState is (LOAD_INSTRUCTION,FLUSH_ARITH_PIPELINE,EXECUTE_INSTRUCTION);
	--! Estados para el controlador de interrupciones.
	type iCtrlState is (WAITING_FOR_AN_EVENT,FIRING_INTERRUPTIONS,SUSPEND);
	--! Constante de reseteo
	constant rstMasterValue : std_logic :='0';
	--! Constantes periodicas.
	constant tclk 	: time := 20 ns;
	constant tclk_2 : time := tclk/2;
	constant tclk_4	: time := tclk/4;
	
	--! Contadores para la m&aacute:quina de estados.
	component customCounter
	generic (		
		EOBFLAG		: string ;
		ZEROFLAG	: string ;
		BACKWARDS	: string ;
		EQUALFLAG	: string ;	
		subwidth	: integer;	
		width 		: integer
		
	);
	port (
		clk,rst,go,set	: in std_logic;
		setValue,cmpBlockValue		: in std_Logic_vector(width-1 downto subwidth);
		zero_flag,eob_flag,eq_flag	: out std_logic;
		count			: out std_logic_vector(width-1 downto 0)
	);
	end component;
	
	--! LPM Memory Compiler.
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
		address_a 	: in std_logic_vector(8 downto 0);
		address_b 	: in std_logic_vector(8 downto 0);
		rden_b		: in std_logic;
		q_b			: out std_logic_vector(31 downto 0);
		data_a		: in std_logic_vector(31 downto 0)
		
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
		instrQq:in std_logic_vector(31 downto 0);
		--! Señal de cola vacia.
		instrQ_empty:in std_logic;
		adda,addb:out std_logic_vector (8 downto 0);
		sync_chain_0,instrRdAckd:out std_logic;
		full_r: 	in std_logic;	--! Indica que la cola de resultados no puede aceptar mas de 32 elementos.
		--! End Of Instruction Event
		eoi	: out std_logic;
		
		--! DataPath Control uca code.
		dpc_uca : out std_logic_vector (2 downto 0);
		state	: out macState
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
		rfull_int:		out std_logic_vector(num_events-1downto 0);	--! full results queue related interruptions
		state:			out iCtrlState
	);
	end component;
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
end package;
	