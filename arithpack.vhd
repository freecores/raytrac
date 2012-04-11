library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;

library std;
use std.textio.all;

--! Memory Compiler Library
library lpm;
use lpm.all;



package arithpack is
	--! Estados para la maquina de estados.
	type macState is (LOAD_INSTRUCTION,FLUSH_ARITH_PIPELINE,EXECUTE_INSTRUCTION);
	--! Estados para el controlador de interrupciones.
	type iCtrlState is (WAITING_FOR_AN_EVENT,FIRING_INTERRUPTIONS,SUSPEND);
	
	--! Float data blocks
	constant floatwidth : integer := 32;
	constant widthadmemblock : integer := 9;
	
	type	vectorblock12 is array (11 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblock08 is array (07 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblock06 is array (05 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblock04 is array (03 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblock03 is array (02 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblock02 is array (01 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblockadd02 is array (01 downto 0) of std_logic_vector(widthadmemblock-1 downto 0);
	
	type	v3f	is array(02 downto 0) of std_logic_vector(31 downto 0);
	
	
	
	--! Constante de reseteo
	constant rstMasterValue : std_logic :='0';
	--! Constantes periodicas.
	constant tclk 	: time := 20 ns;
	constant tclk_2 : time := tclk/2;
	constant tclk_4	: time := tclk/4;
	
	
	component raytrac
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
	end component;
	
	--! Componentes Aritm&eacute;ticos
	
	component fadd32
	port (
		clk : in std_logic;
		dpc : in std_logic;
		a32 : in std_logic_vector (31 downto 0);
		b32 : in std_logic_vector (31 downto 0);
		c32 : out std_logic_vector (31 downto 0)
	);
	end component;
	component fmul32 
	port (
		clk : in std_logic;
		a32 : in std_logic_vector (31 downto 0);
		b32 : in std_logic_vector (31 downto 0);
		p32 : out std_logic_vector (31 downto 0)
	);
	end component;
	
	
	--! Contadores para la m&aacute;quina de estados.
	
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
	
	port (
		
		--! Se&ntilde;ales normales de secuencia.
		clk,rst:			in std_logic;
		--! Vector con las instrucci&oacute;n codficada
		instrQq:in std_logic_vector(31 downto 0);
		--! Se&ntilde;al de cola vacia.
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
		blocksize					: integer;
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
		ext_d: in std_logic_vector(floatwidth-1 downto 0);
		int_d : in std_logic_vector(external_readable_blocks*floatwidth-1 downto 0);
		resultfifo_full  : out std_logic_vector(3 downto 0);
		ext_q,instrfifo_q : out std_logic_vector(floatwidth-1 downto 0);
		int_q : out std_logic_vector(external_writeable_blocks*floatwidth-1 downto 0);
		int_rd_add : in std_logic_vector(2*widthadmemblock-1 downto 0);
		dpfifo_d : in std_logic_vector(floatwidth*2-1 downto 0);
		normfifo_d : in std_logic_vector(floatwidth*3-1 downto 0);
		dpfifo_q : out std_logic_vector(floatwidth*2-1 downto 0);
		normfifo_q : out std_logic_vector(floatwidth*3-1 downto 0)
	);	
	end component;
	--! Bloque decodificacion DataPath Control.
	component dpc
	port (
		clk,rst					: in	std_logic;
		paraminput				: in	std_logic_vector ((12*floatwidth)-1 downto 0);	--! Vectores A,B,C,D
		prd32blko			 	: in	std_logic_vector ((06*floatwidth)-1 downto 0);	--! Salidas de los 6 multiplicadores.
		add32blko 				: in	std_logic_vector ((04*floatwidth)-1 downto 0);	--! Salidas de los 4 sumadores.
		sqr32blko,inv32blko		: in	std_logic_vector (floatwidth-1 downto 0);		--! Salidas de la raiz cuadradas y el inversor.
		fifo32x23_q				: in	std_logic_vector (03*floatwidth-1 downto 0);		--! Salida de la cola intermedia.
		fifo32x09_q				: in	std_logic_vector (02*floatwidth-1 downto 0); 	--! Salida de las colas de producto punto. 
		unary,crossprod,addsub	: in	std_logic;									--! Bit con el identificador del bloque AB vs CD e identificador del sub bloque (A/B) o (C/D). 
		sync_chain_0			: in	std_logic;									--! Se&ntilde;al de dato valido que se va por toda la cadena de sincronizacion.
		eoi_int					: in 	std_logic;									--! Se&ntilde;al de interrupci&oacute;n de final de instrucci&ocaute;n.
		eoi_demuxed_int			: out	std_logic_vector (3 downto 0);				--! Se&ntilde;al de interrup&ocaute;n de final de instrucci&oacute;n pero esta vez va asociada a la instrucc&oacute;n UCA.
		sqr32blki,inv32blki		: out	std_logic_vector (floatwidth-1 downto 0);		--! Salidas de las 2 raices cuadradas y los 2 inversores.
		fifo32x26_d				: out	std_logic_vector (03*floatwidth-1 downto 0);		--! Entrada a la cola intermedia para la normalizaci&oacute;n.
		fifo32x09_d				: out	std_logic_vector (02*floatwidth-1 downto 0);		--! Entrada a las colas intermedias del producto punto.  	
		prd32blki				: out	std_logic_vector ((12*floatwidth)-1 downto 0);	--! Entrada de los 12 factores en el bloque de multiplicaci&oacute;n respectivamente.
		add32blki				: out	std_logic_vector ((08*floatwidth)-1 downto 0);	--! Entrada de los 8 sumandos del bloque de 4 sumadores.  
		resw					: out	std_logic_vector (4 downto 0);				--! Salidas de escritura y lectura en las colas de resultados.
		fifo32x09_w				: out	std_logic;
		fifo32x23_w,fifo32x09_r	: out	std_logic;
		fifo32x23_r				: out	std_logic;
		resf_vector				: in 	std_logic_vector(3 downto 0);				--! Entradas de la se&ntilde;al de full de las colas de resultados. 
		resf_event				: out	std_logic;									--! Salida decodificada que indica que la cola de resultados de la operaci&oacute;n que est&aacute; en curso.
		resultoutput			: out	std_logic_vector ((08*floatwidth)-1 downto 0) 	--! 8 salidas de resultados, pues lo m&aacute;ximo que podr&aacute; calcularse por cada clock son 2 vectores.
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
	
	
	
	
	type apCamera is record
		resx,resy : integer;
		width,height : real;
		dist : real;
	end record;
	
	--! Funci&oacute;n que convierte un std_logic_vector en un numero entero
	function ap_slv2int(sl:std_logic_vector) return integer;
	
	--! Funci&oacute;n que convierte un n&uacute;mero flotante IEE754 single float, en un n&uacute;mero std_logic_vector.
	function ap_fp2slv (f:real) return std_logic_vector;
	
	--! Funci&oacute;n que convierte un n&uacute;mero std_logic_vector en un ieee754 single float.
	function ap_slv2fp (sl:std_logic_vector) return real;
	
	--! Funci&oacute;n que devuelve un vector en punto flotante IEEE754 a trav&eacute;s de un   
	function ap_slv_calc_xyvec (x,y:integer; cam:apCamera) return v3f;
	
	
	
	
	
end package;


package body arithpack is

	function ap_slv2int (sl:std_logic_vector) return integer is
		alias s : std_logic_vector (sl'high downto sl'low) is sl;
		variable i : integer; 
	begin
		i:=0;
		for index in s'high downto s'low loop
			if s(index)='1' then
				i:=i*2+1;
			else
				i:=i*2;
			end if;
		end loop;
		return i;
			
	end function;
	function ap_fp2slv (f:real) return std_logic_vector is
		variable faux : real;
		variable sef : std_logic_vector (31 downto 0);
	begin
		--! Signo
		if (f<0.0) then
			sef(31) := '1';
		else
			sef(31) := '0';
		end if;
		
		--! Exponente
		sef(30 downto 23) := conv_std_logic_vector(integer(floor(log(f,2.0))),8);
		
		--! Fraction
		faux :=f/floor(log(f,2.0));
		faux := faux - 1.0;
		
		sef(22 downto 0)  := conv_std_logic_vector(integer(faux),23);
		
		return sef;				
		 
	end function;

	function ap_slv2fp(sl:std_logic_vector) return real is
		variable expo,frc:integer;
		alias s: std_logic_vector(31 downto 0) is sl;
		variable f: real;
		
	begin
		
		
		expo:=ap_slv2int(s(30 downto 23)) - 127;
		expo:=2**expo;
		frc:=ap_slv2int('1'&s(22 downto 0));
		f:=real(frc)*(2.0**(-23.0));
		f:=f*real(expo);
		
		if s(31)='1' then
			return -f;
		else
			return f;
		end if; 
		
		
	end function;

	function ap_slv_calc_xyvec (x,y:integer; cam:apCamera) return v3f is
	
		
		variable dx,dy : real;
		variable v : v3f;
	begin
	
		dx := cam.width/real(cam.resx);
		dy := cam.height/real(cam.resy);
		
		--! Eje X: Tomando el dedo &iacute;ndice de la mano derecha, este eje queda apuntando en la direcci&on en la que mira la c&aacute;mara u observador siempre.
		v(0):=ap_fp2slv(cam.dist);
		
		--! Eje Y: Tomando el dedo coraz&oacute;n de la mano derecha, este eje queda apuntando a la izquierda del observador, desde el observador.
		v(1):=ap_fp2slv(dx*real(cam.resx)*0.5-dx*0.5);
		
		--! Eje Z: Tomando el dedo pulgar de la mano derecha, este eje queda apuntando hacia arriba del observador, desde el observador.
		v(2):=ap_fp2slv(dy*real(cam.resy)*0.5-dy*0.5);
		
		return v;
	
	end function;

end package body;