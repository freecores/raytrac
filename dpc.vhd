--! @file dpc.vhd
--! @brief Decodificador de operaci&eacute;n. Sistema de decodificación de los \kdatapaths, cuyo objetivo es a partir del par&acute;ametro de entrada DCS.\nSon 4 las posibles configuraciones de \kdatapaths que existen. Los valores de los bits DC son los que determinan y decodifican la interconexi&oacute;n entre los componentes aritm&eacute;ticos. El componente S determina el signo de la operaci&oacute;n cuando es una suma la que operaci&oacute;n se es&eacutea; ejecutando en el momento.  
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

use work.arithpack.all;


entity dpc is 
	
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
end entity;

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
	

	
	
	
	signal sparaminput					: vectorblock06;
	--!TBXSTART:FACTORS_N_ADDENDS
	signal sfactor						: vectorblock12;
	signal ssumando						: vectorblock06;
	signal sdpfifo_q					: xfloat32;
	--!TBXEND
	
	
	--!TBXSTART:ARITHMETIC_RESULTS
	signal sresult 						: vectorblock04;
	signal sprd32blk					: vectorblock06;
	signal sadd32blk					: vectorblock03;
	signal ssqr32blk,sinv32blk			: xfloat32;
	signal q1xyz_32x19_q,q1xyz_32x19_d		: vectorblock03;
	--!TBXEND
	
	
	--!TBXSTART:SYNC_CHAIN
	signal ssync_chain					: std_logic_vector(25 downto 1);
	signal sres							: std_logic_vector(3 downto 0);
	--!TBXEND
	
	
	
	
	
begin
	
	--! Cadena de sincronizaci&oacute;n: 29 posiciones.
	sync_chain_proc:
	process(clk,rst,sync_chain_0)
	begin
		if rst=rstMasterValue then
			ssync_chain(25 downto 1) <= (others => '0');
		elsif clk'event and clk='1' then 
			for i in 25 downto 2 loop
				ssync_chain(i) <= ssync_chain(i-1);
			end loop;
			ssync_chain(1) <= sync_chain_0;
		end if;
	end process sync_chain_proc;
	
	--! Escritura en las colas de resultados y escritura/lectura en las colas intermedias mediante cadena de resultados.
	q0_32x03_w <= ssync_chain(5);
	q1xyz_32x20_w <= ssync_chain(1);
	q0_32x03_r <= ssync_chain(12);
	q1xyz_32x20_r <= ssync_chain(21);
		
	--! Salida de se&ntilde;ales de datos que se van a escribir en la cola de resultados.	
	resw	<= sres;
	
	--! El siguiente c&oacute;digo sirve para conectar arreglos a se&ntilde;ales std_logic_1164, simplemente son abstracciones a nivel de c&oacute;digo y no representar&aacute; cambios en la s&iacute;ntesis.
	sparaminput	<= paraminput;
	prd32blki	<= sfactor;
	add32blki	<= ssumando;
	resultoutput<= sresult;
	
	
	stuff03:
	for i in 02 downto 0 generate
		q1xyz_32x19_q(i) <= fifo32x19_q(i*floatwidth+floatwidth-1 downto i*floatwidth);
		fifo32x19_d(i*floatwidth+floatwidth-1 downto i*floatwidth) <= q1xyz_32x19_d(i);
	end generate stuff03;	
	
	sdpfifo_q <= fifo32x09_q;
	
	--! El siguiente c&oacute;digo sirve para conectar arreglos a se&ntilde;ales std_logic_1164, son abstracciones de c&oacute;digo tambi&eacute;n, sin embargo se realizan a trav&eacute;s de registros. 
	register_products_outputs:
	process (clk)
	begin
		if clk'event and clk='1' then
			sprd32blk  <= prd32blko;
			sadd32blk <= add32blko;
			sinv32blk <= inv32blko;
		end if;
	end process;
	--! Los productos del multiplicador 2 y 3, ya registrados dentro de dpc van a la cola intermedia del producto punto (q0_32x03_d)
	--! Los unicos resultados de sumandos que de nuevo entran al DataPathControl (observar la pesta&ntilde;a del documento de excel) 
	q0_32x03_d <= sprd32blk(p2);
	
	--! Raiz Cuadrada.
	ssqr32blk <= sqr32blko;
	
	
	--! Cola de normalizacion
	q1xyz_32x19_d(qx) <= sparaminput(ax);
	q1xyz_32x19_d(qy) <= sparaminput(ay);
	q1xyz_32x19_d(qz) <= sparaminput(az);
	
	--! La entrada al inversor SIEMPRE viene con la salida de la raiz cuadrada
	inv32blki <= ssqr32blk;
	
	--! La entrada de la ra&iacute;z cuadrada SIEMPRE viene con la salida del sumador 1.
	sqr32blki <= add32blko(a1);
	
	--! Decodificaci&oacute;n del Datapath.
	datapathproc:process(s,d,c,sparaminput,sinv32blk,sprd32blk,sadd32blk,sdpfifo_q,q1xyz_32x19_q,ssync_chain,sqr32blko)
	begin
		
		if d='1' then
			--P0 P1 y P2
			sfactor(f0) <= sparaminput(ax);
			sfactor(f2) <= sparaminput(ay);
			sfactor(f4) <= sparaminput(az);
			
			if c='0' then
				sfactor(f1) <= sparaminput(bx) ;
				sfactor(f3) <= sparaminput(by) ;
				sfactor(f5) <= sparaminput(bz) ;
		
			else
				sfactor(f1) <= sparaminput(ax);
				sfactor(f3) <= sparaminput(ay);
				sfactor(f5) <= sparaminput(az);
							
			end if;
					
			--P3 P4 y P5
			if s='0' then
				sfactor(f6) <= sinv32blk;
				sfactor(f7) <= q1xyz_32x19_q(ax);
			
				sfactor(f8) <= sinv32blk;
				sfactor(f9) <= q1xyz_32x19_q(ay);

				sfactor(f10) <= sinv32blk;			
				sfactor(f11) <= q1xyz_32x19_q(az);
			
			else
				sfactor(f6) <= sparaminput(ax);
				sfactor(f7) <= sparaminput(bx);
			
				sfactor(f8) <= sparaminput(ay);
				sfactor(f9) <= sparaminput(bx);

				sfactor(f10) <= sparaminput(az);			
				sfactor(f11) <= sparaminput(bx);
			
			end if;
			-- S0
			ssumando(s0) <= sprd32blk(p0);
			ssumando(s1) <= sprd32blk(p1);
			
			--S1
			ssumando(s2) <= sadd32blk(a0);
			ssumando(s3) <= sdpfifo_q;
			
			--RES0,1,2
			if c='0' then 
				sresult(0) <= sadd32blk(a1);
			else
				sresult(0) <= sprd32blk(p3);
			
			end if;
			sresult(1) <= sprd32blk(p4);
			sresult(2) <= sprd32blk(p5);
			
			if c='1' and s='1' then
				sres(2 downto 0) <= ssync_chain(5)&ssync_chain(5)&ssync_chain(5);
			elsif c='1' then
				sres(2 downto 0) <= ssync_chain(25)&ssync_chain(25)&ssync_chain(25);
			else
				sres(2 downto 0) <= ssync_chain(19)&ssync_chain(19)&ssync_chain(19);
			end if;			
					 
			
			
			
		else  

			--P0 P1 y P2
			sfactor(f0) <= sparaminput(ay);
			sfactor(f1) <= sparaminput(bz);

			sfactor(f2) <= sparaminput(az);
			sfactor(f3) <= sparaminput(by);
			
			sfactor(f4) <= sparaminput(az);
			sfactor(f5) <= sparaminput(bx);

			--P3 P4 y P5
			sfactor(f6) <= sparaminput(ax);
			sfactor(f7) <= sparaminput(bz);
			
			sfactor(f8) <= sparaminput(ax);
			sfactor(f9) <= sparaminput(by);
			
			sfactor(f10) <= sparaminput(ay);
			sfactor(f11) <= sparaminput(bx);
			
			-- S0
			if c='0' then 
			
				ssumando(s0) <= sparaminput(ax);
				ssumando(s1) <= sparaminput(bx);
			
			--S1
				ssumando(s2) <= sparaminput(ay);
				ssumando(s3) <= sparaminput(by);
			else
				ssumando(s0) <= sprd32blk(p0);
				ssumando(s1) <= sprd32blk(p1);
			
			--S1
				ssumando(s2) <= sprd32blk(p2);
				ssumando(s3) <= sprd32blk(p3);
			
			end if;
			--RES0,1,2 
			sresult(0) <= sadd32blk(a0);
			sresult(1) <= sadd32blk(a1);
			sresult(2) <= sadd32blk(a2);

			if c='1' then
				sres(2 downto 0) <= ssync_chain(12)&ssync_chain(12)&ssync_chain(12);
			else
				sres(2 downto 0) <= ssync_chain(8)&ssync_chain(8)&ssync_chain(8);
			end if;			
		
		end if;
		
		--S2
		if c='0' then 
			ssumando(s4) <= sparaminput(az);
			ssumando(s5) <= sparaminput(bz);
		else
			ssumando(s4) <= sprd32blk(p4);
			ssumando(s5) <= sprd32blk(p5);
		end if;		
		
		--RES3
		sresult(3) <= sqr32blko;
		
		sres(3) <= ssync_chain(19);
		
	end process;
	
	
	
	
end architecture;
