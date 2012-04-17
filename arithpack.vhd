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
	type iCtrlState is (WAITING_FOR_AN_EVENT,FIRING_INTERRUPTIONS,SUSPEND);
	
	--! Float data blocks
	constant floatwidth : integer := 32;
	constant widthadmemblock : integer := 9;
	
	
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
	type	vectorblockadd02 is array (01 downto 0) of std_logic_vector(widthadmemblock-1 downto 0);
	
	
	
	
	
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
		external_readable_widthad	: integer;				
		external_writeable_widthad	: integer
	);
	port (
		
		
		clk,rst,dpfifo_rd,normfifo_rd,dpfifo_wr,normfifo_wr : in std_logic;
		instrfifo_rd : in std_logic;
		resultfifo_wr: in std_logic_vector(8-1 downto 0);
		instrfifo_empty: out std_logic; ext_rd,ext_wr: in std_logic;
		ext_wr_add : in std_logic_vector(external_writeable_widthad+widthadmemblock-1 downto 0);		
		ext_rd_add : in std_logic_vector(external_readable_widthad-1 downto 0);
		ext_d: in std_logic_vector(floatwidth-1 downto 0);
		int_d : in vectorblock08;
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
		paraminput				: in	vectorblock12;	--! Vectores A,B,C,D
		prd32blko			 	: in	vectorblock06;	--! Salidas de los 6 multiplicadores.
		add32blko 				: in	vectorblock04;	--! Salidas de los 4 sumadores.
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
		prd32blki				: out	vectorblock12;	--! Entrada de los 12 factores en el bloque de multiplicaci&oacute;n respectivamente.
		add32blki				: out	vectorblock08;	--! Entrada de los 8 sumandos del bloque de 4 sumadores.  
		resw					: out	std_logic_vector (4 downto 0);				--! Salidas de escritura y lectura en las colas de resultados.
		fifo32x09_w				: out	std_logic;
		fifo32x23_w,fifo32x09_r	: out	std_logic;
		fifo32x23_r				: out	std_logic;
		resf_vector				: in 	std_logic_vector(3 downto 0);				--! Entradas de la se&ntilde;al de full de las colas de resultados. 
		resf_event				: out	std_logic;									--! Salida decodificada que indica que la cola de resultados de la operaci&oacute;n que est&aacute; en curso.
		resultoutput			: out	vectorblock08 	--! 8 salidas de resultados, pues lo m&aacute;ximo que podr&aacute; calcularse por cada clock son 2 vectores.
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
	function ap_slvf2string(sl:std_logic_vector) return string;
	function ap_slv2hex (s:std_logic_vector) return string;
	--! Funci&oacute;n que devuelve una cadena con el estado de macState.
	function ap_macState2string(s:macState) return string;
	
	--! Funci&oacute;n que devuelve la cadena de caracteres de 8 datos en punto flotante IEEE 754.
	function ap_vblk082string(v8:vectorblock08) return string;
	
	--! Funci&oacute;n que devuelve la cadena de caracteres de 12 datos en punto flotante IEEE 754.
	function ap_vblk122string(v12:vectorblock12) return string;
	
	--! Funci&oacute;n que convierte un array de 2 std_logic_vectors que contienen un par de direcciones en string
	function ap_vnadd022string(va2:vectorblockadd02) return string;
	
	--! Funci&oacute;n que devuelve una cadena de caracteres con el estado de la maquina de estados que controla las interrupciones
	function ap_iCtrlState2string(i:iCtrlState) return string;	
	
	--! Funci&oacute;n que devuelve una cadena con los componentes de un vector R3 en punto flotante IEEE754	
	function ap_v3f2string(v:v3f) return string;
	
	--! Funci&oacute;n que formatea una instrucci&oacute;n
	function ap_format_instruction(i:string;ac_o,bd_o,ac_f,bd_f:std_logic_vector;comb:std_logic) return std_logic_vector;
	
	--! Funci&oacute;n que devuelve una cadena de caracteres de un solo caracter con el valor de un bit std_logic
	function ap_sl2string(s:std_logic) return string;
	 
end package;


package body arithpack is

	function ap_sl2string(s:std_logic) return string is
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
		
		return tmp;
	end function;

	function ap_format_instruction(i:string;ac_o,bd_o,ac_f,bd_f:std_logic_vector;comb:std_logic) return std_logic_vector is
		
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
				ins(04 downto 00) := x"18";
			when "nrm" => 
				ins(31 downto 29) := "101";
				ins(04 downto 00) := x"1d";
			when "add" => 
				ins(31 downto 29) := "001";
				ins(04 downto 00) := x"0a";
			when "sub" => 
				ins(31 downto 29) := "011";
				ins(04 downto 00) := x"0a";
			when "dot" => 
				ins(31 downto 29) := "000";
				ins(04 downto 00) := x"17";
			when "crs" => 
				ins(31 downto 29) := "010";
				ins(04 downto 00) := x"0e";
			when others => 
				ins(31 downto 29) := "111";
				ins(04 downto 00) := x"05";
		end case;
		ins(28 downto 24) := aco;
		ins(23 downto 19) := acf;
		ins(18 downto 14) := bdo;
		ins(13 downto 09) := bdf;
		ins(08) := comb;
		ins(07 downto 05) := "000";	
		return ins;
		
	
	end function;
	
	

	function ap_v3f2string(v:v3f) return string is
		variable tmp:string (1 to 1024);
	begin
		tmp:="[X]"&ap_slvf2string(v(0))&"[Y]"&ap_slvf2string(v(1))&"[Z]"&ap_slvf2string(v(2));
		return tmp;
	end function;

	function ap_iCtrlState2string(i:iCtrlState) return string is
	
		variable tmp:string (1 to 9);
	
	begin
	
		case i is 
			when WAITING_FOR_AN_EVENT =>
				tmp:="WAIT_EVNT";
			when FIRING_INTERRUPTIONS => 
				tmp:="FIRE_INTx";
			when SUSPEND => 
				tmp:="SUSPENDED";
			when others => 
				tmp:="ILGL__VAL";
		end case;
		
		return tmp;
		
	end function;
	
	function ap_vnadd022string(va2:vectorblockadd02) return string is
		variable tmp:string (1 to 1024);
	begin
		tmp:="[01]"&ap_slv2hex(va2(1))&" [00]"&ap_slv2hex(va2(0));
		return tmp;
	end function;
	
	function ap_vblk122string(v12:vectorblock12) return string is
		variable tmp:string (1 to 1024);
	begin
	
		tmp:="["&integer'image(11)&"]";
		for i in 11 downto 0 loop
			tmp:=tmp&ap_slvf2string(v12(i));
			if i>0 then
				tmp:=tmp&"["&integer'image(i)&"]";
			end if;
		end loop;
		return tmp;
			
	
	end function;
	
	function ap_vblk082string(v8:vectorblock08) return string is
		variable tmp:string (1 to 1024);
	begin
	
		tmp:="["&integer'image(7)&"]";
		for i in 7 downto 0 loop
			tmp:=tmp&ap_slvf2string(v8(i));
			if i>0 then
				tmp:=tmp&"["&integer'image(i)&"]";
			end if;
		end loop;
		return tmp;
			
	
	end function;
	
	
	function ap_macState2string(s:macState) return string is
		variable tmp:string (1 to 6);
	begin
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
		return tmp;
	end function;
	
	constant hexchars : string (1 to 16) := "0123456789ABCDEF";
	function ap_slv2hex (s:std_logic_vector) return string is 
		variable x64 : std_logic_vector(63 downto 0):=x"0000000000000000";
		variable str : string (1 to 16);
	begin
		x64(s'high downto s'low):=s;
		for i in 15 downto 0 loop
			str(i+1):=hexchars(1+ieee.std_logic_unsigned.conv_integer(x64(i*4+3 downto i*4)));
		end loop;
		return str;	
	end function;

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
	
	function ap_slvf2string(sl:std_logic_vector) return string is 
		alias f: std_logic_vector(31 downto 0) is sl;
		variable r: real;
		
	begin 
		
		r:=ap_slv2fp(f);
		return real'image(r);
		
	end function;   
	
	
	

end package body;