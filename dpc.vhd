--! @file dpc.vhd
--! @brief Decodificador de operacion. 
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------------------
-- RAYTRAC
-- Author Julian Andres Guarin
-- dpc.vhd
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

entity dpc is 
	generic (
		width : integer := 32
		--!external_readable_widthad	: integer := integer(ceil(log(real(external_readable_blocks),2.0))))			
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
		sync_chain_d			: in	std_logic;									--! Señal de dato valido que se va por toda la cadena de sincronizacion.
		sqr32blki,inv32blki		: out	std_logic_vector (width-1 downto 0);		--! Salidas de las 2 raices cuadradas y los 2 inversores.
		fifo32x26_d				: out	std_logic_vector (03*width-1 downto 0);		--! Entrada a la cola intermedia para la normalizaci&oacute;n.
		fifo32x09_d				: out	std_logic_vector (02*width-1 downto 0);		--! Entrada a las colas intermedias del producto punto.  	
		prd32blki				: out	std_logic_vector ((12*width)-1 downto 0);	--! Entrada de los 12 factores en el bloque de multiplicaci&oacute;n respectivamente.
		add32blki				: out	std_logic_vector ((08*width)-1 downto 0);	--! Entrada de los 8 sumandos del bloque de 4 sumadores.  
		res567w,res13w,res2w	: out	std_logic;									--! Salidas de escritura y lectura en las colas de resultados.
		res0w,res4w,fifo32x09_w	: out	std_logic;
		fifo32x23_w,fifo32x09_r	: out	std_logic;
		fifo32x23_r				: out	std_logic;
		res567f,res13f			: in 	std_logic;									--! Entradas de la se&ntilde;al de full de las colas de resultados. 
		res2f,res0f				: in	std_logic;
		resf					: out	std_logic;									--! Salida decodificada que indica que la cola de resultados de la operaci&oacute;n est&aacute; en curso.
		resultoutput			: out	std_logic_vector ((08*width)-1 downto 0) 	--! 8 salidas de resultados, pues lo m&aacute;ximo que podr&aacute; calcularse por cada clock son 2 vectores. 
	);
end dpc;

architecture dpc_arch of dpc is 
	
	constant qz : integer := 00;constant qy : integer := 01;constant qx : integer := 02;
	constant az : integer := 00;constant ay : integer := 01;constant ax : integer := 02;constant bz : integer := 03;constant by : integer := 04;constant bx : integer := 05;
	constant cz : integer := 06;constant cy : integer := 07;constant cx : integer := 08;constant dz : integer := 09;constant dy : integer := 10;constant dx : integer := 11;
	constant f0	: integer := 00;constant f1 : integer := 01;constant f2 : integer := 02;constant f3 : integer := 03;constant f4 : integer := 04;constant f5 : integer := 05;
	constant f6	: integer := 06;constant f7 : integer := 07;constant f8 : integer := 08;constant f9 : integer := 09;constant f10: integer := 10;constant f11: integer := 11;
	constant s0	: integer := 00;constant s1 : integer := 01;constant s2 : integer := 02;constant s3 : integer := 03;constant s4 : integer := 04;constant s5 : integer := 05;
	constant s6	: integer := 06;constant s7 : integer := 07;
	constant a0	: integer := 00;constant a1 : integer := 01;constant a2 : integer := 02;constant aa : integer := 03; 
	constant p0	: integer := 00;constant p1 : integer := 01;constant p2 : integer := 02;constant p3 : integer := 03;constant p4 : integer := 04;constant p5 : integer := 05;
	
	constant dpfifoab : integer := 00;
	constant dpfifocd : integer := 01;
	

	type	vectorblock12 is array (11 downto 0) of std_logic_vector(width-1 downto 0);
	type	vectorblock08 is array (07 downto 0) of std_logic_vector(width-1 downto 0);
	type	vectorblock06 is array (05 downto 0) of std_logic_vector(width-1 downto 0);
	type	vectorblock04 is array (03 downto 0) of std_logic_vector(width-1 downto 0);
	type	vectorblock03 is array (02 downto 0) of std_logic_vector(width-1 downto 0);
	type	vectorblock02 is array (01 downto 0) of std_logic_vector(width-1 downto 0);
	
	
	
	signal sparaminput,sfactor			: vectorblock12;
	signal ssumando,sresult 			: vectorblock08;
	signal sprd32blk					: vectorblock06;
	signal sadd32blk					: vectorblock04;
	signal snormfifo_q,snormfifo_d		: vectorblock03;
	signal sdpfifo_q					: vectorblock02;
	signal ssqr32blk,sinv32blk			: std_logic_vector(width-1 downto 0);
	signal ssync_chain					: std_logic_vector(28 downto 0);
	signal ssync_chain_d				: std_logic;
	
	
	constant rstMasterValue : std_logic := '0';
	
begin
	
	--! Cadena de sincronizaci&oacute;n: 29 posiciones.
	ssync_chain_d <= sync_chain_d;
	sync_chain_proc:
	process(clk,rst)
	begin
		if rst=rstMasterValue then
			ssync_chain <= (others => '0');
		elsif clk'event and clk='1' then 
			ssync_chain(0) <= ssync_chain_d;
			for i in 28 downto 1 loop
				ssync_chain(i) <= ssync_chain(i-1);
			end loop;
		end if;
	end process sync_chain_proc;
	
	--! Escritura en las colas de resultados y escritura/lectura en las colas intermedias mediante cadena de resultados.
	fifo32x09_w <= ssync_chain(5);
	fifo32x23_w <= ssync_chain(1);
	fifo32x09_r <= ssync_chain(13);
	fifo32x23_r <= ssync_chain(24);	
	res0w <= ssync_chain(23);
	res4w <= ssync_chain(21);
	sync_chain_comb:
	process (ssync_chain,addsub,crossprod,unary)
	begin
		if unary='1' then
			res567w <= ssync_chain(28);
		else
			res567w <= ssync_chain(4);
		end if;
	
		if addsub='1' then 
			res13w <= ssync_chain(9);
		 	res2w <= ssync_chain(9);
		else
			res13w <= ssync_chain(13);
			if crossprod='1' then
				res2w <= ssync_chain(13);
			else
				res2w <= ssync_chain(22);
			end if;
		end if;
	end process sync_chain_comb;
	
	
	--! El siguiente c&oacute;digo sirve para conectar arreglos a se&ntilde;ales std_logic_1164, simplemente son abstracciones a nivel de c&oacute;digo y no representar&aacute; cambios en la s&iacute;ntesis.
	stuff12: 
	for i in 11 downto 0 generate
		sparaminput(i) <= paraminput(i*width+width-1 downto i*width);
		prd32blki(i*width+width-1 downto i*width) <= sfactor(i);
	end generate stuff12;
	stuff08:
	for i in 07 downto 0 generate
		add32blki(i*width+width-1 downto i*width) <= ssumando(i);
		resultoutput(i*width+width-1 downto i*width) <= sresult(i);
	end generate stuff08;
	stuff04: 
	for i in 03 downto 1 generate
		sadd32blk(i)  <= add32blko(i*width+width-1 downto i*width);
	end generate stuff04;
	
	
	stuff03:
	for i in 02 downto 0 generate
		snormfifo_q(i) <= fifo32x23_q(i*width+width-1 downto i*width);
		fifo32x26_d(i*width+width-1 downto i*width) <= snormfifo_d(i);
	end generate stuff03;	
	
	stuff02:
	for i in 01 downto 0 generate	
		sdpfifo_q(i)  <= fifo32x09_q(i*width+width-1 downto i*width);
	end generate stuff02;
	
	--! El siguiente c&oacute;digo sirve para conectar arreglos a se&ntilde;ales std_logic_1164, son abstracciones de c&oacute;digo tambi&eacute;n, sin embargo se realizan a trav&eacute;s de registros. 
	register_products_outputs:
	process (clk)
	begin
		if clk'event and clk='1' then
			for i in 05 downto 0 loop 
				sprd32blk(i)  <= prd32blko(i*width+width-1 downto i*width);
			end loop;
		end if;
	end process;
	--! Los productos del multiplicador 2 y 3, ya registrados dentro de dpc van a la cola intermedia del producto punto (fifo32x09_d)
	fifo32x09_d <= sprd32blk(p3)&sprd32blk(p2);
	register_adder0_and_inversor_output:
	process (clk)
	begin
		if clk'event and clk='1' then
			sadd32blk(a0)  <= add32blko(a0*width+width-1 downto a0*width);
			sinv32blk <= inv32blko;
		end if;
	end process;
	
	
	
	
	--! Raiz Cuadrada.
	ssqr32blk <= sqr32blko;
	
	--! Colas de salida de los distintos resultados;
	sresult(0) <= ssqr32blk;
	sresult(1) <= sadd32blk(a0);
	sresult(2) <= sadd32blk(a1);
	sresult(3) <= sadd32blk(a2);
	sresult(4) <= sadd32blk(aa);
	sresult(5) <= sprd32blk(p3);
	sresult(6) <= sprd32blk(p4);
	sresult(7) <= sprd32blk(p5);
	
	--! Cola de normalizacion
	snormfifo_d(qx) <= sparaminput(ax);
	snormfifo_d(qy) <= sparaminput(ay);
	snormfifo_d(qz) <= sparaminput(az);
	
	
	
	--! La entrada al inversor SIEMPRE viene con la salida de la raiz cuadrada
	inv32blki <= sqr32blko;
	--! La entrada de la ra�z cuadrada SIEMPRE viene con la salida del sumador 1.
	sqr32blki <= sadd32blk(a1);
	
	
	
	--! Conectar las entradas del sumador a, a la salida 
	ssumando(s6) <= sadd32blk(a2);
	ssumando(s7) <= sdpfifo_q(dpfifocd);
	
	--!El siguiente proceso conecta la se&ntilde;al de cola "casi llena", de la cola que corresponde al resultado de la operaci&oacute;n indicada por los bit UCA (Unary, Crossprod, Addsub).
	fullQ:process(res0f,res13f,res2f,res567f,unary,crossprod,addsub)
	begin 
		if unary='0' then
			if crossprod='1' or addsub='1' then 
				resf <= res13f;
			else
				resf <= res2f;
			end if;
		elsif crossprod='1' or addsub='1' then
			resf <= res567f;
		else
			resf <= res0f;
		end if;
	end process;
			
	--! Decodificaci&oacute;n del Datapath.
	mul:process(unary,addsub,crossprod,sparaminput,sinv32blk,sprd32blk,sadd32blk,sdpfifo_q,snormfifo_q)
	begin
		
		sfactor(f4) <= sparaminput(az);
		if unary='1' then 
			--! Magnitud y normalizacion
			sfactor(f0) <= sparaminput(ax);
			sfactor(f1) <= sparaminput(ax);
			sfactor(f2) <= sparaminput(ay);			
			sfactor(f3) <= sparaminput(ay);
			
			sfactor(f5) <= sparaminput(az);
			if crossprod='1' and addsub='1' then
				sfactor(f6) <= sparaminput(cx);
				sfactor(f7) <= sparaminput(dx);
				sfactor(f8) <= sparaminput(cy);
				sfactor(f9) <= sparaminput(dx);
				sfactor(f10) <= sparaminput(cz);
				sfactor(f11) <= sparaminput(dx);
			else	
				sfactor(f6) <= snormfifo_q(ax);
				sfactor(f7) <= sinv32blk;
				sfactor(f8) <= snormfifo_q(ay);
				sfactor(f9) <= sinv32blk;
				sfactor(f10) <= snormfifo_q(az);
				sfactor(f11) <= sinv32blk;
			end if;
			
			
		elsif addsub='0' then 
			--! Solo productos punto o cruz
			if crossprod='1' then
			
				sfactor(f0) <= sparaminput(ay);
				sfactor(f1) <= sparaminput(bz);
				sfactor(f2) <= sparaminput(az);
				sfactor(f3) <= sparaminput(by);
				
				sfactor(f5) <= sparaminput(bx);
				sfactor(f6) <= sparaminput(ax);
				sfactor(f7) <= sparaminput(bz);
				sfactor(f8) <= sparaminput(ax);
				sfactor(f9) <= sparaminput(by);
				sfactor(f10) <= sparaminput(ay);
				sfactor(f11) <= sparaminput(bx);
			
			else			
				
				sfactor(f0) <= 	sparaminput(ax) ;
				sfactor(f1) <= 	sparaminput(bx) ;
				sfactor(f2) <= 	sparaminput(ay) ;	
				sfactor(f3) <= 	sparaminput(by) ;
				sfactor(f5) <= 	sparaminput(bz) ;
				sfactor(f6) <= 	sparaminput(cx) ;
				sfactor(f7) <= 	sparaminput(dx) ;
				sfactor(f8) <= 	sparaminput(cy) ;
				sfactor(f9) <= 	sparaminput(dy) ;
				sfactor(f10) <= sparaminput(cz) ;
				sfactor(f11) <= sparaminput(dz) ;
			end if;
		
		else
			sfactor(f0) <= 	sparaminput(ax) ;
			sfactor(f1) <= 	sparaminput(bx) ;
			sfactor(f2) <= 	sparaminput(ay) ;	
			sfactor(f3) <= 	sparaminput(by) ;
			sfactor(f5) <= 	sparaminput(bz) ;
			sfactor(f6) <= 	sparaminput(cx) ;
			sfactor(f7) <= 	sparaminput(dx) ;
			sfactor(f8) <= 	sparaminput(cy) ;
			sfactor(f9) <= 	sparaminput(dx) ;
			sfactor(f10) <= sparaminput(cz) ;
			sfactor(f11) <= sparaminput(dx) ;
		end if;
		
		
		if addsub='1' then
			ssumando(s0) <= sparaminput(ax);
			ssumando(s1) <= sparaminput(bx);
			ssumando(s2) <= sparaminput(ay);
			ssumando(s3) <= sparaminput(by);
			ssumando(s4) <= sparaminput(az);
			ssumando(s5) <= sparaminput(bz);
		else
			ssumando(s0) <= sprd32blk(p0);
			ssumando(s1) <= sprd32blk(p1);
			if crossprod='0' then
				ssumando(s2) <= sadd32blk(a0);
				ssumando(s3) <= sdpfifo_q(dpfifoab);
			else
				ssumando(s2) <= sprd32blk(p2);
				ssumando(s3) <= sprd32blk(p3);
			end if;				
			ssumando(s4) <= sprd32blk(p4);
			ssumando(s5) <= sprd32blk(p5);
		end if;					
	end process;
	
	
	
end dpc_arch;
