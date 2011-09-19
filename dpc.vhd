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
		paraminput				: in	std_logic_vector ((12*width)-1 downto 0);	--! Vectores A,B,C,D
		prd32blko			 	: in	std_logic_vector ((06*width)-1 downto 0);	--! Salidas de los 6 multiplicadores.
		add32blko 				: in	std_logic_vector ((04*width)-1 downto 0);	--! Salidas de los 4 sumadores.
		sqr32blko,inv32blko		: in	std_logic_vector (width-1 downto 0);		--! Salidas de las 2 raices cuadradas y los 2 inversores.
		fifo32x26_q				: in	std_logic_vector (03*width-1 downto 0);		--! Salida de la cola intermedia.
		fifo32x09_q				: in	std_logic_vector (02*width-1 downto 0); 	--! Salida de las colas de producto punto. 
		unary,crossprod,addsub	: in	std_logic;									--! Bit con el identificador del bloque AB vs CD e identificador del sub bloque (A/B) o (C/D). 
		scalar					: in	std_logic;
		fifo32x26_d				: out	std_logic_vector (03*width-1 downto 0);		--! Entrada a la cola intermedia para la normalizaci&oacute;n.
		fifo32x09_d				: out	std_logic_vector (02*width-1 downto 0);		--! Entrada a las colas intermedias del producto punto.  	
		prd32blki				: out	std_logic_vector ((12*width)-1 downto 0);	--! Entrada de los 12 factores en el bloque de multiplicaci&oacute;n respectivamente.
		add32blki				: out	std_logic_vector ((08*width)-1 downto 0);	--! Entrada de los 8 sumandos del bloque de 4 sumadores.  
		
		resultoutput			: out	std_logic_vector ((08*width)-1 downto 0) 	--! 6 salidas de resultados, pues lo m&aacute;ximo que podr&aacute; calcularse por cada clock son 2 vectores. 
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
	 
begin
	
	
	
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
	stuff06: 
	for i in 05 downto 0 generate
		sprd32blk(i)  <= prd32blko(i*width+width-1 downto i*width);
	end generate stuff06;
	stuff04: 
	for i in 03 downto 0 generate
		sadd32blk(i)  <= add32blko(i*width+width-1 downto i*width);
	end generate stuff04;
	stuff03:
	for i in 02 downto 0 generate
		snormfifo_q(i) <= fifo32x26_q(i*width+width-1 downto i*width);
		fifo32x26_d(i*width+width-1 downto i*width) <= snormfifo_d(i);
	end generate stuff03;	
	
	stuff02:
	for i in 01 downto 0 generate	
		sdpfifo_q(i)  <= fifo32x09_q(i*width+width-1 downto i*width);
	end generate stuff02;
	fifo32x09_d <= sprd32blk(p3)&sprd32blk(p2);
	
	
	
	sinv32blk <= inv32blko;
	ssqr32blk <= sqr32blko;
	
	--! Salidas de los distintos resultados;
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
	
	--! Signo de los 3 primeros sumadores
	
	
	
	
	mul:process(unary,addsub,crossprod,scalar,sparaminput,sinv32blk,sprd32blk,sadd32blk,sdpfifo_q,snormfifo_q)
	begin
		
		
		if unary='1' then 
			--! Magnitud y normalizacion
			sfactor(f0) <= sparaminput(ax);
			sfactor(f1) <= sparaminput(ax);
			sfactor(f2) <= sparaminput(ay);			
			sfactor(f3) <= sparaminput(ay);
			sfactor(f4) <= sparaminput(az);
			sfactor(f5) <= sparaminput(az);
			sfactor(f6) <= snormfifo_q(ax);
			sfactor(f7) <= sinv32blk;
			sfactor(f8) <= snormfifo_q(ay);
			sfactor(f9) <= sinv32blk;
			sfactor(f10) <= snormfifo_q(az);
			sfactor(f11) <= sinv32blk;
		elsif crossprod='1' then 
			--! Solo productos punto
			sfactor(f0) <= sparaminput(ay);
			sfactor(f1) <= sparaminput(bz);
			sfactor(f2) <= sparaminput(az);
			sfactor(f3) <= sparaminput(by);
			sfactor(f4) <= sparaminput(az);
			sfactor(f5) <= sparaminput(bx);
			sfactor(f6) <= sparaminput(ax);
			sfactor(f7) <= sparaminput(bz);
			sfactor(f8) <= sparaminput(ax);
			sfactor(f9) <= sparaminput(by);
			sfactor(f10) <= sparaminput(ay);
			sfactor(f11) <= sparaminput(bx);
		elsif scalar='0' then --! Producto punto 
			sfactor(f0) <= 	sparaminput(ax) ;
			sfactor(f1) <= 	sparaminput(bx) ;
			sfactor(f2) <= 	sparaminput(ay) ;	
			sfactor(f3) <= 	sparaminput(by) ;
			sfactor(f4) <= 	sparaminput(az) ;
			sfactor(f5) <= 	sparaminput(bz) ;
			sfactor(f6) <= 	sparaminput(cx) ;
			sfactor(f7) <= 	sparaminput(dx) ;
			sfactor(f8) <= 	sparaminput(cy) ;
			sfactor(f9) <= 	sparaminput(dy) ;
			sfactor(f10) <= sparaminput(cz) ;
			sfactor(f11) <= sparaminput(dz) ;
		else
			sfactor(f0) <= 	sparaminput(ax) ;
			sfactor(f1) <= 	sparaminput(bx) ;
			sfactor(f2) <= 	sparaminput(ay) ;	
			sfactor(f3) <= 	sparaminput(by) ;
			sfactor(f4) <= 	sparaminput(az) ;
			sfactor(f5) <= 	sparaminput(bz) ;
			sfactor(f6) <= 	sparaminput(cx) ;
			sfactor(f7) <= 	sparaminput(dx) ;
			sfactor(f8) <= 	sparaminput(cy) ;
			sfactor(f9) <= 	sparaminput(dx) ;
			sfactor(f10) <= sparaminput(cz) ;
			sfactor(f11) <= sparaminput(dx) ;
			
		end if;
		
		ssumando(s6) <= sadd32blk(a2);
		ssumando(s7) <= sdpfifo_q(dpfifocd);
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
	
	
	
	
--	interconnection:process(instr3,hblockslab,abblockslab,cdblockslab,sparaminput,sprd32blk,sadd32blk,sdpfifo_q)
--	begin
--		--! La cola para la normalizacion de los vectores.
--		snormfifo_d(qx) <= (hblockslab and ((cdblockslab and sparaminput(dx))or(not(cdblockslab) and sparaminput(cx)))) or (not(hblockslab) and ((abblockslab and sparaminput(bx))or(not(abblockslab) and sparaminput(ax))));
--		snormfifo_d(qy) <= (hblockslab and ((cdblockslab and sparaminput(dy))or(not(cdblockslab) and sparaminput(cy)))) or (not(hblockslab) and ((abblockslab and sparaminput(by))or(not(abblockslab) and sparaminput(ay))));
--		snormfifo_d(qz) <= (hblockslab and ((cdblockslab and sparaminput(dz))or(not(cdblockslab) and sparaminput(cz)))) or (not(hblockslab) and ((abblockslab and sparaminput(bz))or(not(abblockslab) and sparaminput(az))));
--	
--		--! Combinatorio para decidir que operaciones realizan los sumadores / restadores.
--		add32blks <= (instr3(0) xor (instr3(1) xor instr3(0)))&(instr3(0) xor (instr3(1) xor instr3(0))) ;
--		
--		--! Por defecto conectar los sumandos en producto punto/cruz
--		ssumando(s0) <= sprd32blk(p0);ssumando(s1) <= sprd32blk(p1);
--		ssumando(s6) <= sadd32blk(a0);ssumando(s7) <= sdpfifo_q(dpfifoab);
--		ssumando(s10) <= sdpfifo_q(dpfifocd);ssumando(s11) <= sadd32blk(a2);
--		ssumando(s4) <= sprd32blk(p4);ssumando(s5) <= sprd32blk(p5);
--		ssumando(s2) <= sprd32blk(p2);ssumando(s3) <= sprd32blk(p3);
--		
--		--! El segundo sumador del segundo bloque siempre sera suma o resta independiente de la operacion
--		ssumando(s8) <= sparaminput(cy);ssumando(s9) <= sparaminput(dy);	
--
--		--! Por defecto conectar los factores en producto punto
--		sfactor(f0) <= sparaminput(ax);sfactor(f1) <= sparaminput(bx);
--		sfactor(f2) <= sparaminput(ay);sfactor(f3) <= sparaminput(by);
--		sfactor(f4) <= sparaminput(az);sfactor(f5) <= sparaminput(bz);
--		sfactor(f6) <= sparaminput(bx);sfactor(f7) <= sparaminput(dx);
--		sfactor(f8) <= sparaminput(by);sfactor(f9) <= sparaminput(dy);
--		sfactor(f10) <= sparaminput(bz);sfactor(f11) <= sparaminput(dz);
--		
--		--!Los resultados por defecto se acomodan al producto punto y parcialmente a los productos simple y escalar.
--		sresult(ax) <= sadd32blk(aa);
--		sresult(ay) <= sprd32blk(p1);
--		sresult(az) <= sprd32blk(p2);
--		sresult(bx) <= sadd32blk(ac);
--		sresult(by) <= sprd32blk(p4);
--		sresult(bz) <= sprd32blk(p5);
--		
--		if (instr3(2 downto 1)="11" or instr3="100") then
--			sresult(ax) <= sprd32blk(p0);
--			sresult(bx) <= sprd32blk(p3);
--		elsif instr3(0)='1' then
--			sresult(ax) <= sprd32blk(a0);
--			sresult(ay) <= sprd32blk(a1);
--			sresult(az) <= sprd32blk(a2);
--			sresult(bx) <= sadd32blk(aa);
--			sresult(by) <= sprd32blk(ab);
--			sresult(bz) <= sadd32blk(ac);
--		elsif instr3(1)='1' then
--			sresult(ax) <= ssqr32blk(sqrt320);
--			sresult(bx) <= ssqr32blk(sqrt321);
--		end if;
--			
--
--		if instr3(0)='1' then	--! Producto Cruz, suma, resta, multiplicacion simple
--
--			if (instr3(2) or instr3(1))='1' then --! Suma, Resta, Multiplicacion simple
--				
--				--! Conectar las entradas de los sumadores en suma o resta de vectores 
--				ssumando(s0) <= sparaminput(ax);ssumando(s1) <= sparaminput(bx);
--				ssumando(s2) <= sparaminput(ay);ssumando(s3) <= sparaminput(by);
--				ssumando(s4) <= sparaminput(az);ssumando(s5) <= sparaminput(bz);
--				ssumando(s6) <= sparaminput(cx);ssumando(s7) <= sparaminput(dx);				
--				ssumando(s10) <= sparaminput(cz);ssumando(s11) <= sparaminput(dz);
--			
--			else --! Producto Cruz!
--				
--				if hblock='1' then	--! Producto crux CxD 
--					--!Multiplicadores: 
--					sfactor(f0) <= sparaminput(cy);sfactor(f1) <= sparaminput(dz);sfactor(f2) <= sparaminput(cz);sfactor(f3) <= sparaminput(dy);
--					sfactor(f4) <= sparaminput(cx);sfactor(f5) <= sparaminput(dz);sfactor(f6) <= sparaminput(cz);sfactor(f7) <= sparaminput(dx);
--					sfactor(f8) <= sparaminput(cx);sfactor(f9) <= sparaminput(dy);sfactor(f10) <= sparaminput(cy);sfactor(f11) <= sparaminput(dx);
--				else 				--! Producto crux AxD
--					--!Multiplicadores: 					
--					sfactor(f0) <= sparaminput(ay);sfactor(f1) <= sparaminput(bz);sfactor(f2) <= sparaminput(az);sfactor(f3) <= sparaminput(by);
--					sfactor(f4) <= sparaminput(ax);sfactor(f5) <= sparaminput(bz);sfactor(f6) <= sparaminput(az);sfactor(f7) <= sparaminput(bx);
--					sfactor(f8) <= sparaminput(ax);sfactor(f9) <= sparaminput(by);sfactor(f10) <= sparaminput(ay);sfactor(f11) <= sparaminput(bx);
--				end if;
--
--			end if;
--
--		else					--! Producto Punto, magnitud, producto escalar y normalizacion  
--			if instr3(2)='1' then 		--!Producto Escalar (INSTR3(1)=0) o Normalizacion (INSTR3(1)=1) 
--				
--				sfactor(f0) <= (not instr31slab and sparaminput(ax)) or (instr31slab and ((not(hblockslab) and ((not(abblockslab) and sparaminput(ax)) or(abblockslab and sparaminput(bx))))or( hblockslab and snormfifo_q(qx)) ) );
--				sfactor(f1) <= (not instr31slab and sparaminput(bx)) or (instr31slab and ((not(hblockslab) and ((not(abblockslab) and sparaminput(ax)) or(abblockslab and sparaminput(bx))))or( hblockslab and sinv32blk(invr321)) ) );
--				sfactor(f2) <= (not instr31slab and sparaminput(ay)) or (instr31slab and ((not(hblockslab) and ((not(abblockslab) and sparaminput(ay)) or(abblockslab and sparaminput(by))))or( hblockslab and snormfifo_q(qy)) ) );
--				sfactor(f3) <= (not instr31slab and sparaminput(bx)) or (instr31slab and ((not(hblockslab) and ((not(abblockslab) and sparaminput(ay)) or(abblockslab and sparaminput(by))))or( hblockslab and sinv32blk(invr321)) ) );
--				sfactor(f4) <= (not instr31slab and sparaminput(az)) or (instr31slab and ((not(hblockslab) and ((not(abblockslab) and sparaminput(az)) or(abblockslab and sparaminput(bz))))or( hblockslab and snormfifo_q(qz)) ) );
--				sfactor(f5) <= (not instr31slab and sparaminput(bx)) or (instr31slab and ((not(hblockslab) and ((not(abblockslab) and sparaminput(az)) or(abblockslab and sparaminput(bz))))or( hblockslab and sinv32blk(invr321)) ) );
--				sfactor(f6) <= (not instr31slab and sparaminput(cx)) or (instr31slab and ((hblockslab and ((not(cdblockslab) and sparaminput(cx)) or(cdblockslab and sparaminput(dx))))or( not(hblockslab) and snormfifo_q(qx)) ) );
--				sfactor(f7) <= (not instr31slab and sparaminput(dx)) or (instr31slab and ((hblockslab and ((not(cdblockslab) and sparaminput(cx)) or(cdblockslab and sparaminput(dx))))or( not(hblockslab) and sinv32blk(invr320)) ) );
--				sfactor(f8) <= (not instr31slab and sparaminput(cy)) or (instr31slab and ((hblockslab and ((not(cdblockslab) and sparaminput(cy)) or(cdblockslab and sparaminput(dy))))or( not(hblockslab) and snormfifo_q(qy)) ) );
--				sfactor(f9) <= (not instr31slab and sparaminput(dx)) or (instr31slab and ((hblockslab and ((not(cdblockslab) and sparaminput(cy)) or(cdblockslab and sparaminput(dy))))or( not(hblockslab) and sinv32blk(invr320)) ) );
--				sfactor(f10) <= (not instr31slab and sparaminput(cz)) or (instr31slab and ((hblockslab and ((not(cdblockslab) and sparaminput(cz)) or(cdblockslab and sparaminput(dz))))or( not(hblockslab) and snormfifo_q(qz)) ) );
--				sfactor(f11) <= (not instr31slab and sparaminput(dx)) or (instr31slab and ((hblockslab and ((not(cdblockslab) and sparaminput(cz)) or(cdblockslab and sparaminput(dz))))or( not(hblockslab) and sinv32blk(invr320)) ) );
--			elsif instr3(1)='1' then	--!Magnitud. El producto punto no se computa porque los factores estan por defecto configurados en producto punto.				
--				sfactor(f0) <= (not(abblockslab) and sparaminput(ax))or(abblockslab and sparaminput(bx));
--				sfactor(f1) <= (not(abblockslab) and sparaminput(ax))or(abblockslab and sparaminput(bx));
--				sfactor(f2) <= (not(abblockslab) and sparaminput(ay))or(abblockslab and sparaminput(by));
--				sfactor(f3) <= (not(abblockslab) and sparaminput(ay))or(abblockslab and sparaminput(by));
--				sfactor(f4) <= (not(abblockslab) and sparaminput(az))or(abblockslab and sparaminput(bz));
--				sfactor(f5) <= (not(abblockslab) and sparaminput(az))or(abblockslab and sparaminput(bz));
--				sfactor(f6) <= (not(cdblockslab) and sparaminput(cx))or(cdblockslab and sparaminput(dx));
--				sfactor(f7) <= (not(cdblockslab) and sparaminput(cx))or(cdblockslab and sparaminput(dx));
--				sfactor(f8) <= (not(cdblockslab) and sparaminput(cy))or(cdblockslab and sparaminput(dy));
--				sfactor(f9) <= (not(cdblockslab) and sparaminput(cy))or(cdblockslab and sparaminput(dy));
--				sfactor(f10) <= (not(cdblockslab) and sparaminput(cz))or(cdblockslab and sparaminput(dz));
--				sfactor(f11) <= (not(cdblockslab) and sparaminput(cz))or(cdblockslab and sparaminput(dz));
--					
--			end if;
--		end if;
--				
--	end process;
--	
	
end dpc_arch;
