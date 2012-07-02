library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.math_real.all;

library std;
use std.textio.all;



--! Memory Compiler Library
library altera_mf;
use altera_mf.all;
library lpm;
use lpm.all;



package arithpack is
	--! Estados para la maquina de estados.
	type macState is (LOAD_INSTRUCTION,FLUSH_ARITH_PIPELINE,EXECUTE_INSTRUCTION);
	--! Estados para el controlador de interrupciones.
	type iCtrlState is (WAITING_FOR_A_RFULL_EVENT,INHIBIT_RFULL_INT);
	
	--! Float data blocks
	constant floatwidth : integer := 32;
	
	--! Control de tama&ntilde;os de memoria.
	constant widthadmemblock : integer := 9;
	
	--! Reducci&oacute de memoria por mitades
	constant memoryreduction : integer := 1;
	
	subtype	xfloat32 is std_logic_vector(31 downto 0);
	type	v3f	is array(02 downto 0) of xfloat32;
	
	--! Constantes para definir 
	
	--!type	vectorblock12 is array (11 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblock12 is array (11 downto 0) of xfloat32;
	
	type	vectorblock08 is array (07 downto 0) of xfloat32;
	type	vectorblock06 is array (05 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblock04 is array (03 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblock03 is array (02 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblock02 is array (01 downto 0) of std_logic_vector(floatwidth-1 downto 0);
	type	vectorblockadd02 is array (01 downto 0) of std_logic_vector(widthadmemblock-1-memoryreduction downto 0);
	
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
		int	: out std_logic;
		
		--! Salidas
		q : out std_logic_vector (31 downto 0)
		
		
				
	);
	end component;
	
	--! Componentes Aritm&eacute;ticos
	
	component fadd32
	port (
		clk : in std_logic;
		dpc : in std_logic;
		a32 : in xfloat32;
		b32 : in xfloat32;
		c32 : out xfloat32
	);
	end component;
	component fmul32 
	port (
		clk : in std_logic;
		a32 : in xfloat32;
		b32 : in xfloat32;
		p32 : out xfloat32
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
	
	--! LPM_MULTIPLIER
	component lpm_mult 
	generic (
		lpm_hint			: string;
		lpm_pipeline		: natural;
		lpm_representation	: string;
		lpm_type			: string;
		lpm_widtha			: natural;
		lpm_widthb			: natural;
		lpm_widthp			: natural
	);
	port (
		dataa	: in std_logic_vector ( lpm_widtha-1 downto 0 );
		datab	: in std_logic_vector ( lpm_widthb-1 downto 0 );
		result	: out std_logic_vector( lpm_widthp-1 downto 0 )
	);
	end component;	
	--! LPM Memory Compiler.
	component scfifo
	generic (
		add_ram_output_register	:string;
		almost_full_value		:natural;
		allow_rwcycle_when_full	:string;
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
		address_a 	: in std_logic_vector(widthadmemblock-1-memoryreduction downto 0);
		address_b 	: in std_logic_vector(widthadmemblock-1-memoryreduction downto 0);
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
		rfull_event:	in std_logic;	--! full results queue events
		eoi_event:		in std_logic;	--! end of instruction related events
		int:			out std_logic;
		state:			out iCtrlState
	);
	end component;
	--! Bloque de memorias
	component memblock
	port (
		
		
		clk,rst,dpfifo_rd,normfifo_rd,dpfifo_wr,normfifo_wr : in std_logic;
		instrfifo_rd : in std_logic;
		resultfifo_wr: in std_logic_vector(8-1 downto 0);
		instrfifo_empty: out std_logic; ext_rd,ext_wr: in std_logic;
		ext_wr_add : in std_logic_vector(4+widthadmemblock-1 downto 0);		
		ext_rd_add : in std_logic_vector(3 downto 0);
		ext_d: in std_logic_vector(floatwidth-1 downto 0);
		int_d : in vectorblock08;
		
		status_register : in std_logic_vector(3 downto 0);
		
		resultfifo_full  : out std_logic_vector(3 downto 0);
		ext_q,instrfifo_q : out std_logic_vector(floatwidth-1 downto 0);
		int_q : out vectorblock12;
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
		paraminput				: in	vectorblock06;	--! Vectores A,B
		prd32blko			 	: in	vectorblock06;	--! Salidas de los 6 multiplicadores.
		add32blko 				: in	vectorblock03;	--! Salidas de los 4 sumadores.
		sqr32blko,inv32blko		: in	std_logic_vector (floatwidth-1 downto 0);	--! Salidas de la raiz cuadradas y el inversor.
		fifo32x19_q				: in	std_logic_vector (03*floatwidth-1 downto 0);--! Salida de la cola intermedia.
		fifo32x09_q				: in	std_logic_vector (floatwidth-1 downto 0);--! Salida de las colas de producto punto. 
		d,c,s					: in	std_logic;		--! Bit con el identificador del bloque AB vs CD e identificador del sub bloque (A/B) o (C/D). 
		sync_chain_0			: in	std_logic;		--! Se&ntilde;al de dato valido que se va por toda la cadena de sincronizacion.
		sqr32blki,inv32blki		: out	std_logic_vector (floatwidth-1 downto 0);		--! Salidas de las 2 raices cuadradas y los 2 inversores.
		fifo32x19_d				: out	std_logic_vector (03*floatwidth-1 downto 0);		--! Entrada a la cola intermedia para la normalizaci&oacute;n.
		q0_32x03_d				: out	std_logic_vector (floatwidth-1 downto 0);		--! Entrada a las colas intermedias del producto punto.  	
		prd32blki				: out	vectorblock12;	--! Entrada de los 12 factores en el bloque de multiplicaci&oacute;n respectivamente.
		add32blki				: out	vectorblock06;	--! Entrada de los 6 sumandos del bloque de 3 sumadores.  
		resw					: out	std_logic_vector (3 downto 0);				--! Salidas de escritura y lectura en las colas de resultados.
		q0_32x03_w				: out	std_logic;
		q1xyz_32x20_w			: out	std_logic;
		q0_32x03_r				: out	std_logic;
		q1xyz_32x20_r			: out	std_logic;
		resf_vector				: in 	std_logic_vector (3 downto 0);				--! Entradas de la se&ntilde;al de full de las colas de resultados. 
		resultoutput			: out	vectorblock04 --! 4 salidas de resultados, pues lo m&aacute;ximo que podr&aacute; calcularse por cada clock son 2 vectores.
	);
	end component;
	--! Bloque Aritmetico de Sumadores y Multiplicadores (madd)
	component arithblock
	port (
		
		clk	: in std_logic;
		rst : in std_logic;
	
		dpc : in std_logic;
	
		f	: in vectorblock12;
		a	: in vectorblock08;
		
		s	: out vectorblock04;
		p	: out vectorblock06
			
	);
	end component;
	--! Bloque de Raiz Cuadrada
	component sqrt32
	port (
		
		clk	: in std_logic;
		rd32: in xfloat32;		
		sq32: out xfloat32
	);
	end component;
	--! Bloque de Inversores.
	component invr32
	port (
		
		clk		: in std_logic;
		dvd32	: in xfloat32;		
		qout32	: out xfloat32
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
	
	--! Funci&oacute;n que devuelve una cadena con el n&uacute;mero flotante IEEE 754 &oacute; a una cadena de cifras hexadecimales.
	procedure ap_slvf2string(l:inout line;sl:std_logic_vector);
	procedure ap_slv2hex (l:inout line;h:in std_logic_vector) ;
	--! Funci&oacute;n que devuelve una cadena con el estado de macState.
	procedure ap_macState2string(l:inout line;s:in macState);
	
	--! Funci&oacute;n que convierte un array de 2 std_logic_vectors que contienen un par de direcciones en string
	procedure ap_vnadd022string(l:inout line; va2:in vectorblockadd02);
	
	--! Funci&oacute;n que devuelve una cadena de caracteres con el estado de la maquina de estados que controla las interrupciones
	procedure ap_iCtrlState2string(l:inout line;i:in iCtrlState) ;	
	
	--! Funci&oacute;n que devuelve una cadena con los componentes de un vector R3 en punto flotante IEEE754	
	procedure ap_v3f2string(l:inout line;v:in v3f);
	procedure ap_xfp032string(l:inout line;vb03:in vectorblock03);
	
	--! Funci&oacute;n que formatea una instrucci&oacute;n
	function ap_format_instruction(i:string;ac_o,ac_f,bd_o,bd_f:std_logic_vector;comb:std_logic) return std_logic_vector;
	
	--! Funci&oacute;n que devuelve una cadena de caracteres de un solo caracter con el valor de un bit std_logic
	procedure ap_sl2string(l:inout line;s:std_logic);
	
	--! Procedimiento para mostrar vectores en forma de arreglos de flotantes
	procedure ap_xfp122string(l:inout line;vb12:in vectorblock12);
	procedure ap_xfp082string(l:inout line;vb08:in vectorblock08);
	procedure ap_xfp062string(l:inout line;vb06:in vectorblock06);
	procedure ap_xfp042string(l:inout line;vb04:in vectorblock04);
	procedure ap_xfp022string(l:inout line;vb02:in vectorblock02);
	
	 
end package;


package body arithpack is
	
	procedure ap_xfp022string(l:inout line; vb02:in vectorblock02) is
	begin
		for i in 01 downto 0 loop
			write(l,string'(" ["&integer'image(i)&"]"));
			write(l,string'(" "));
			ap_slvf2string(l,vb02(i));
		end loop;  
	
	end procedure;
	procedure ap_xfp122string(l:inout line; vb12:in vectorblock12) is

	begin
		for i in 11 downto 0 loop
			write(l,string'(" ["&integer'image(i)&"]"));
			write(l,string'(" "));
			ap_slvf2string(l,vb12(i));
		end loop;  
	end procedure;
	
	procedure ap_xfp082string(l:inout line; vb08:in vectorblock08) is

	begin
		for i in 07 downto 0 loop
			write(l,string'(" ["&integer'image(i)&"]"));
			write(l,string'(" "));
			ap_slvf2string(l,vb08(i));
		end loop;  
	end procedure;
	
	procedure ap_xfp062string(l:inout line; vb06:in vectorblock06) is

	begin
		for i in 05 downto 0 loop
			write(l,string'(" ["&integer'image(i)&"]"));
			write(l,string'(" "));
			ap_slvf2string(l,vb06(i));
		end loop;  
	end procedure;
	
	procedure ap_xfp042string(l:inout line; vb04:in vectorblock04) is

	begin
		for i in 03 downto 0 loop
			write(l,string'(" ["&integer'image(i)&"]"));
			write(l,string'(" "));
			ap_slvf2string(l,vb04(i));
		end loop;  
	end procedure;
	
	
	procedure ap_sl2string(l:inout line; s:in std_logic)is
		variable tmp:string(1 to 1);
	begin
		
		case s is
			when '1' => 
				tmp:="1";
			when '0' => 
				tmp:="0";
			when 'U' => 
				tmp:="U";
			when 'X' => 
				tmp:="X";
			when 'Z' => 
				tmp:="Z";
			when 'W' => 
				tmp:="W";
			when 'L' => 
				tmp:="L";
			when 'H' => 
				tmp:="H";
			when others => 
				tmp:="-"; -- Don't care
		end case;
		write(l,string'(" "));
		write(l,string'(tmp));
		write(l,string'(" "));
		
		
		
	end procedure;

	function ap_format_instruction(i:string;ac_o,ac_f,bd_o,bd_f:std_logic_vector;comb:std_logic) return std_logic_vector is
		
		alias aco : std_logic_vector (4 downto 0) is ac_o;
		alias acf : std_logic_vector (4 downto 0) is ac_f;
		alias bdo : std_logic_vector (4 downto 0) is bd_o;
		alias bdf : std_logic_vector (4 downto 0) is bd_f;
		variable ins : std_logic_vector (31 downto 0);
		alias it : string (1 to 3) is i;
	begin
	
		case it is 
			when "mag" => 
				ins(31 downto 29) := "100";
				ins(04 downto 00) := '1'&x"8";
			when "nrm" => 
				ins(31 downto 29) := "110";
				ins(04 downto 00) := '1'&x"d";
			when "add" => 
				ins(31 downto 29) := "001";
				ins(04 downto 00) := '0'&x"a";
			when "sub" => 
				ins(31 downto 29) := "011";
				ins(04 downto 00) := '0'&x"a";
			when "dot" => 
				ins(31 downto 29) := "000";
				ins(04 downto 00) := '1'&x"7";
			when "crs" => 
				ins(31 downto 29) := "010";
				ins(04 downto 00) := '0'&x"e";
			when others => 
				ins(31 downto 29) := "111";
				ins(04 downto 00) := '0'&x"5";
		end case;
		ins(28 downto 24) := aco;
		ins(23 downto 19) := acf;
		ins(18 downto 14) := bdo;
		ins(13 downto 09) := bdf;
		ins(08) := comb;
		ins(07 downto 05) := "000";	
		return ins;
		
	
	end function;
	
	

	procedure ap_v3f2string(l:inout line;v:in v3f) is
	begin
		write(l,string'("[X]"));
		write(l,string'(" "));
		ap_slvf2string(l,v(2));
		write(l,string'("[Y]"));
		write(l,string'(" "));
		ap_slvf2string(l,v(1));
		write(l,string'("[Z]"));
		write(l,string'(" "));
		ap_slvf2string(l,v(0));
	end procedure;
	procedure ap_xfp032string(l:inout line;vb03:in vectorblock03) is
	begin
		write(l,string'("[X]"));
		write(l,string'(" "));
		ap_slvf2string(l,vb03(2));
		write(l,string'("[Y]"));
		write(l,string'(" "));
		ap_slvf2string(l,vb03(1));
		write(l,string'("[Z]"));
		write(l,string'(" "));
		ap_slvf2string(l,vb03(0));
	end procedure;

	procedure ap_iCtrlState2string(l:inout line;i:in iCtrlState) is
		variable tmp:string (1 to 9);
	begin
		
		write(l,string'("<< "));
		case i is 
			when WAITING_FOR_A_RFULL_EVENT =>
				tmp:="WAIT_RF_EVNT";
			when INHIBIT_RFULL_INT => 
				tmp:="INHB_RF_INT";
			when others => 
				tmp:="ILGL__VAL";
		end case;
		write(l,string'(tmp));
		write(l,string'(" >>"));
	
	end procedure;
	
	procedure ap_vnadd022string(l:inout line;va2:in vectorblockadd02) is 
	begin

		write(l,string'("<<[1] "));
		ap_slv2hex(l,va2(1));
		write(l,string'(" [0] "));
		ap_slv2hex(l,va2(0));
		write(l,string'(" >>"));

	end procedure;
	
	procedure ap_macState2string(l:inout line;s:in macState) is
		variable tmp:string (1 to 6);
	begin
		
		write(l,string'("<< "));
		case s is
			when LOAD_INSTRUCTION => 
				tmp:="LD_INS";
			when FLUSH_ARITH_PIPELINE => 
				tmp:="FL_ARP";
			when EXECUTE_INSTRUCTION => 
				tmp:="EX_INS";
			when others => 
				tmp:="HEL_ON";
		end case;
		write(l,string'(tmp));
		write(l,string'(" >>"));
		
	end procedure;
	
	constant hexchars : string (1 to 16) := "0123456789ABCDEF";
	procedure ap_slv2hex (l:inout line;h:in std_logic_vector) is 
		variable index_high,index_low,highone,nc : integer;
	begin 
		highone := h'high-h'low;
		nc:=0;
		for i in h'high downto h'low loop
			if h(i)/='0' and h(i)/='1' then
				nc:=1;
			end if;
		end loop;
		
		if nc=1 then
			for i in h'high downto h'low loop
				ap_sl2string(l,h(i));
			end loop;
		else
			for i in (highone)/4 downto 0 loop
				index_low:=i*4;
				if (index_low+3)>highone then
					index_high := highone;
				else
					index_high := i*4+3;
				end if;
				write(l,hexchars(1+ieee.std_logic_unsigned.conv_integer(h(index_high+h'low downto index_low+h'low))));
			end loop;
		end if; 
	end procedure;
	
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
			faux:=f*(-1.0);
		else
			sef(31) := '0';
			faux:=f;
		end if;
		
		--! Exponente
		sef(30 downto 23) := conv_std_logic_vector(127+integer(floor(log(faux,2.0))),8);
		
		--! Fraction
		faux :=faux/(2.0**real(floor(log(faux,2.0))));
		faux := faux - 1.0;
		
		sef(22 downto 0)  := conv_std_logic_vector(integer(faux*(2.0**23.0)),23);
		
		return sef;				
		 
	end function;

	function ap_slv2fp(sl:std_logic_vector) return real is
		variable frc:integer;
		alias s: std_logic_vector(31 downto 0) is sl;
		variable f,expo: real;
		
	begin
		
		
		expo:=real(ap_slv2int(s(30 downto 23)) - 127);
		expo:=(2.0)**(expo);
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
		
		--! Eje Z: Tomando el dedo &iacute;ndice de la mano derecha, este eje queda apuntando en la direcci&on en la que mira la c&aacute;mara u observador siempre.
		v(0):=ap_fp2slv(cam.dist);
		
		--! Eje X: Tomando el dedo coraz&oacute;n de la mano derecha, este eje queda apuntando a la izquierda del observador, desde el observador.
		v(2):=ap_fp2slv(dx*real(cam.resx)*0.5-real(x)*dx-dx*0.5);
		
		--! Eje Y: Tomando el dedo pulgar de la mano derecha, este eje queda apuntando hacia arriba del observador, desde el observador.
		v(1):=ap_fp2slv(dy*real(cam.resy)*0.5-real(y)*dy-dy*0.5);
		
		return v;
	
	end function;
	
	procedure ap_slvf2string(l:inout line;sl:std_logic_vector) is 
		alias f: std_logic_vector(31 downto 0) is sl;
		variable r: real;
		
	begin 
		
		r:=ap_slv2fp(f);
		write(l,string'(real'image(r)));
		write(l,string'(" [ s:"));
		ap_slv2hex(l,f(31 downto 31));
		write(l,string'(" f: "));
		ap_slv2hex(l,f(30 downto 23));
		write(l,string'(" m: "));
		ap_slv2hex(l,f(22 downto 00));
		write(l,string'(" ]"));
		
	end procedure;   
	
	
	

end package body;