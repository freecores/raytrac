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
	
	--!Constantes usadas por los RTLs
	constant qz : integer := 00;constant qy : integer := 01;constant qx : integer := 02;constant sc : integer := 03;
	constant az : integer := 00;constant ay : integer := 01;constant ax : integer := 02;constant bz : integer := 03;constant by : integer := 04;constant bx : integer := 05;
	constant f0	: integer := 00;constant f1 : integer := 01;constant f2 : integer := 02;constant f3 : integer := 03;constant f4 : integer := 04;constant f5 : integer := 05;
	constant f6	: integer := 06;constant f7 : integer := 07;constant f8 : integer := 08;constant f9 : integer := 09;constant f10: integer := 10;constant f11: integer := 11;
	constant s0	: integer := 00;constant s1 : integer := 01;constant s2 : integer := 02;constant s3 : integer := 03;constant s4 : integer := 04;constant s5 : integer := 05;
	constant a0	: integer := 00;constant a1 : integer := 01;constant a2 : integer := 02; 
	constant p0	: integer := 00;constant p1 : integer := 01;constant p2 : integer := 02;constant p3 : integer := 03;constant p4 : integer := 04;constant p5 : integer := 05;
	
	constant index_control_register : integer := 00;
	constant index_start_address_r	: integer := 01;
	constant index_end_address_r	: integer := 02;
	constant index_start_address_w	: integer := 03;
	constant index_end_address_w	: integer := 04;
	constant index_scratch_register	: integer := 05;
	
	--! M&aacute;quina de estados.
	
	
	--! Control de tama&ntilde;os de memoria.
	constant widthadmemblock : integer := 9;
	
	subtype	xfloat32 is std_logic_vector(31 downto 0);
	type	v3f	is array(02 downto 0) of xfloat32;
	
	--! Constantes para definir bloques de valores de 32 bits single float
	type	vectorblock12 is array (11 downto 0) of xfloat32;
	type	vectorblock08 is array (07 downto 0) of xfloat32;
	type	vectorblock06 is array (05 downto 0) of xfloat32;
	type	vectorblock04 is array (03 downto 0) of xfloat32;
	type	vectorblock03 is array (02 downto 0) of xfloat32;
	type	vectorblock02 is array (01 downto 0) of xfloat32;
	
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
		--! Interface Avalon Master
		address_master	: out	std_logic_vector(31 downto 0);
		begintransfer	: out	std_logic;
		read_master		: out	std_logic;
		readdata_master	: in	std_logic_vector (31 downto 0);
		write_master	: out	std_logic;
		writedata_master: out	std_logic_vector (31 downto 0);
		waitrequest		: in	std_logic_vector;
		readdatavalid_m	: in	std_logic_vector;
		--! Interface Avalon Slave
		address_slave	: in	std_logic_vector(3 downto 0);
		read_slave		: in	std_logic;
		readdata_slave	: in	std_logic_vector(31 downto 0);
		write_slave		: in	std_logic;
		writedata_slave	: in	std_logic_vector(31 downto 0);
		readdatavalid_s	: out	std_logic;
		--! Interface Interrupt Sender
		irq	: out std_logic
	);
	end component;
	
	component raytrac_control
	port (
		
		--! Se&ntilde;ales normales de secuencia.
		clk:			in std_logic;
		rst:			in std_logic;
		
		--! Interface Avalon Master
		begintransfer	: out	std_logic;
		address_master	: out	std_logic_vector(31 downto 0);
		read_master		: out	std_logic;
		write_master	: out	std_logic;
		waitrequest		: in	std_logic;
		readdatavalid_m	: in	std_logic;
				
		--! Interface Avalon Slave
		address_slave	: in	std_logic_vector(3 downto 0);
		read_slave		: in	std_logic;
		readdata_slave	: out	std_logic_vector(31 downto 0);
		write_slave		: in	std_logic;
		writedata_slave	: in	std_logic_vector(31 downto 0);
		readdatavalid_s	: out	std_logic;

		--! Interface Interrupt Sender
		irq	: out std_logic;
		
		--! Se&ntilde;ales de Control (Memblock)
		go			: out std_logic;
		comb		: out std_logic;
		load		: out std_logic;
		load_chain	: out std_logic_vector(1 downto 0);
		qparams_e	: in std_logic;
		qresult_e	: in std_logic_vector(3 downto 0);
		
		--! Se&ntilde;les de Control de Datapath (DPC)
		qparams_q	: in  xfloat32;
		d			: out std_logic;
		c			: out std_logic;
		s			: out std_logic;
		qresult_sel	: out std_logic_vector(1 downto 0)
	);
	end component;
	
	--! Bloque de memorias
	component memblock
	port (
		
		--!Entradas de Control
		clk 		: in std_logic;
		rst 		: in std_logic;
		go			: in std_logic;
		comb		: in std_logic;
		load		: in std_logic;
		load_chain	: in std_logic_vector(1 downto 0);
		 
		
		--! Cola de par&aacute;metros 
		readdatavalid	: in std_logic;
		readdata_master	: in xfloat32;
		qparams_r		: in std_logic;
		qparams_e		: out std_logic;
		
		--! Cola de resultados		
		qresult_d	: in vectorblock04;
		qresult_q	: out vectorblock04;
				
		--! Registro de par&aacute;metros
		paraminput	: out vectorblock06;
		
		--! Cadena de sincronización
		sync_chain_0	: out std_logic;
		
		--! se&ntilde;ales de colas vacias
		qresult_e	: out std_logic_vector(3 downto 0);
		
	
		
		--! Colas de resultados
		qresult_w		: in std_logic_vector(3 downto 0);
		qresult_rdec	: in std_logic_vector(3 downto 0)			
		
	);	
	end component;
	--! Bloque decodificacion DataPath Control.
	component dpc
	port (
		clk						: in	std_logic;
		rst						: in	std_logic;
		
		paraminput				: in	vectorblock06;	--! Vectores A,B
		
		prd32blko			 	: in	vectorblock06;	--! Salidas de los 6 multiplicadores.
		add32blko 				: in	vectorblock03;	--! Salidas de los 3 sumadores.
		inv32blko				: in	xfloat32;		--! Salidas de la raiz cuadradas y el inversor.
		sqr32blko				: in	xfloat32;		--! Salidas de la raiz cuadradas y el inversor.
		
		
		d,c,s					: in	std_logic;		--! Bit con el identificador del bloque AB vs CD e identificador del sub bloque (A/B) o (C/D). 
		
		sync_chain_0			: in	std_logic;		--! Se&ntilde;al de dato valido que se va por toda la cadena de sincronizacion.
		
		qresult_q				: in	vectorblock04;	--! Salida de las colas de resultados
		qresult_sel				: in 	std_logic_vector (1 downto 0); --! Direccion con el resultado de la
		qresult_rdec			: out	std_logic_vector (3 downto 0); --!Se&ntilde;ales de escritura decodificadas
		qresult_w				: out	std_logic_vector (3 downto 0);				--! Salidas de escritura y lectura en las colas de resultados.
		qresult_d				: out	vectorblock04; --! 4 salidas de resultados, pues lo m&aacute;ximo que podr&aacute; calcularse por cada clock son 2 vectores. 
		
		dataread				: in	std_logic;

		
		prd32blki				: out	vectorblock12;	--! Entrada de los 12 factores en el bloque de multiplicaci&oacute;n respectivamente.
		add32blki				: out	vectorblock06;	--! Entrada de los 6 sumandos del bloque de 3 sumadores.  
		
		dataout					: out 	xfloat32
	
	);
	end component;
	--! Bloque Aritmetico de Sumadores y Multiplicadores (madd)
	component arithblock
	port (
		
		clk	: in std_logic;
		rst : in std_logic;
	
		sign 		: in std_logic;
	
		prd32blki	: in vectorblock12;
		add32blki	: in vectorblock06;
		
		add32blko	: out vectorblock03;
		prd32blko	: out vectorblock06;
		
		sq32o		: out xfloat32;
		inv32o		: out xfloat32
			
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
	--! Contadores para la m&aacute;quina de estados.
	
	component customCounter
	port (
		clk				: in std_logic;
		rst				: in std_logic;
		stateTrans			: in std_logic;
		waitrequest_n	: in std_logic;
		endaddress		: in std_logic_vector (31 downto 2); --! Los 5 bits de arriba.
		startaddress	: in std_logic_vector(31 downto 0);
		endaddressfetch	: out std_logic;
		address_master 	: out std_logic_vector (31 downto 0)	
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
--	component scfifo
--	generic (
--		add_ram_output_register	:string;
--		allow_rwcycle_when_full	:string;
--		intended_device_family	:string;
--		lpm_hint				:string;
--		lpm_numwords			:natural;
--		lpm_showahead			:string;
--		lpm_type				:string;
--		lpm_width				:natural;
--		overflow_checking		:string;
--		underflow_checking		:string;
--		use_eab					:string	
--	);
--	port(
--		rdreq		: in std_logic;
--		aclr		: in std_logic;
--		empty		: out std_logic;
--		clock		: in std_logic;
--		q			: out std_logic_vector(lpm_width-1 downto 0);
--		wrreq		: in std_logic;
--		data		: in std_logic_vector(lpm_width-1 downto 0);
--		almost_full : out std_logic;
--		full		: out std_logic
--	);
--	end component;
	
	
	
	
	
	
	
	
	
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