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
	--constant qz : integer := 00;constant qy : integer := 01;constant qx : integer := 02;constant qsc: integer := 03;
	--constant az : integer := 00;constant ay : integer := 01;constant ax : integer := 02;constant bz : integer := 03;constant by : integer := 04;constant bx : integer := 05;
	--constant f0	: integer := 00;constant f1 : integer := 01;constant f2 : integer := 02;constant f3 : integer := 03;constant f4 : integer := 04;constant f5 : integer := 05;
	--constant f6	: integer := 06;constant f7 : integer := 07;constant f8 : integer := 08;constant f9 : integer := 09;constant f10: integer := 10;constant f11: integer := 11;
	--constant s0	: integer := 00;constant s1 : integer := 01;constant s2 : integer := 02;constant s3 : integer := 03;constant s4 : integer := 04;constant s5 : integer := 05;
	--constant a0	: integer := 00;constant a1 : integer := 01;constant a2 : integer := 02; 
	--constant p0	: integer := 00;constant p1 : integer := 01;constant p2 : integer := 02;constant p3 : integer := 03;constant p4 : integer := 04;constant p5 : integer := 05;
	
	
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