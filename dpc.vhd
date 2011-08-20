--! @file dpc.vhd
--! @brief Decodificador de operacion. 
--! @author Juli�n Andr�s Guar�n Reyes.
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
	);
	port (
		paraminput			: in	std_logic_vector ((12*width)-1 downto 0);		--! Vectores A,B,C,D
		prd32blko,add32blko : in	std_logic_vector ((06*width)-1 downto 0);	--! Salidas de los 6 multiplicadores y los 6 sumadores.
		sqr32blko,inv32blko	: in	std_logic_vector ((02*width)-1 downto 0);	--! Salidas de las 2 raices cuadradas y los 2 inversores.
		fifo32x26_q				: in	std_logic_vector (   03*width-1 downto 0);	--! Salida de la cola intermedia.
		fifo32x09_q				: in	std_logic_vector( 02*width-1 downto 0); 	--! Salida de las colas de producto punto. 
		instr3				: in	std_logic_vector (			 2 downto 0);					--! Opcode con la instrucci&oacute;n.
		hblock				: in	std_logic;																	--! Bit con el identificador del bloque. 
		fifo32x26_d				: out	std_logic_vector (03*width-1 downto 0);	--! Entrada a la cola intermedia para la normalizaci&oacute;n.
		fifo32x09_d				: out	std_logic_vector	(02*width-1 downto 0); --! Entrada a las colas intermedias del producto punto.  	
		prd32blki,add32blki : out	std_logic_vector ((12*width)-1 downto 0);	--! Entrada de los 12 sumandos y de los 12 factores en los 2 bloques de suma y el bloque de multiplicaci&oacute;n respectivamente.
		add32blks			: out	std_logic_vector (			 1 downto 0);			--! Signos de operaci&oacute;n que entran en los 2 bloques de suma.
		resultoutput		: out	std_logic_vector ((06*width)-1 downto 0) 		--! 6 salidas de resultados, pues lo m&aacute;ximo que podr&aacute; calcularse por cada clock son 2 vectores. 
	);
end dpc;

architecture dpc_arch of dpc is 

	constant az : integer := 00;constant ay : integer := 01;constant ax : integer := 02;constant bz : integer := 03;constant by : integer := 04;constant bx : integer := 05;
	constant cz : integer := 06;constant cy : integer := 07;constant cx : integer := 08;constant dz : integer := 09;constant dy : integer := 10;constant dx : integer := 11;
	constant f0	: integer := 00;constant f1 : integer := 01;constant f2 : integer := 02;constant f3 : integer := 03;constant f4 : integer := 04;constant f5 : integer := 05;
	constant f6	: integer := 06;constant f7 : integer := 07;constant f8 : integer := 08;constant f9 : integer := 09;constant f10: integer := 10;constant f11: integer := 11;
	constant s0	: integer := 00;constant s1 : integer := 01;constant s2 : integer := 02;constant s3 : integer := 03;constant s4 : integer := 04;constant s5 : integer := 05;
	constant s6	: integer := 06;constant s7 : integer := 07;constant s8 : integer := 08;constant s9 : integer := 09;constant s10: integer := 10;constant s11: integer := 11;
	constant a0	: integer := 00;constant a1 : integer := 01;constant a2 : integer := 02;constant aa : integer := 03;constant ab : integer := 04;constant ac : integer := 05;
	constant p0	: integer := 00;constant p1 : integer := 01;constant p2 : integer := 02;constant p3 : integer := 03;constant p4 : integer := 04;constant p5 : integer := 05;
	constant sqrt320 : integer := 00;
	constant sqrt321 : integer := 01;
	constant invr320 : integer := 00;
	constant invr321 : integer := 01;
	constant dpfifoab : integer := 00;
	constant dpfifocd : integer := 01;
	

	type	vectorblock12 is array (11 downto 0) of std_logic_vector(width-1 downto 0);
	type	vectorblock06 is array (05 downto 0) of std_logic_vector(width-1 downto 0);
	type	vectorblock03 is array (02 downto 0) of std_logic_vector(width-1 downto 0);
	type	vectorblock02 is array (01 downto 0) of std_logic_vector(width-1 downto 0);
	
	signal	sparaminput,sfactor,ssumando	: vectorblock12;
	signal	sprd32blk,sadd32blk,sresult 	: vectorblock06;
	signal snormfifo_q,snormfifo_d	: vectorblock03;
	signal	ssqr32blk,sinv32blk,sdpfifo_q : vectorblock02;
	
	 	 
	 
begin
	
	--! Connect stuff ....
	stuff12: 
	for i in 11 downto 0 generate
		sparaminput(i) <= paraminput(i*width+width-1 downto i*width);
		prd32blki(i*width+width-1 downto i*width) <= sfactor(i);
		add32blki(i*width+width-1 downto i*width) <= ssumando(i);
	end generate stuff12;
	stuff06: 
	for i in 05 downto 0 generate
		sprd32blk(i)  <= prd32blko(i*width+width-1 downto i*width);
		sadd32blk(i)  <= add32blko(i*width+width-1 downto i*width);
		resultoutput(i*width+width-1 downto i*width) <= sresult(i);
	end generate stuff06;
	stuff03:
	for i in 02 downto 0 generate
		snormfifo_q(i) <= fifo32x26_q(i*width+width-1 downto i*width);
		fifo32x26_d(i*width+width-1 downto i*width) <= snormfifo_d(i);
	end generate stuff03;	
	
	stuff02:
	for i in 01 downto 0 generate
		ssqr32blk(i)  <= sqr32blko(i*width+width-1 downto i*width);
		sinv32blk(i)  <= inv32blko(i*width+width-1 downto i*width);
	end generate stuff02;
	fifo32x09_d <= sprd32blk(p3)&sprd32blk(p2);
 		
	
	interconnection_factors:process(instr3,hblock)
	begin
		
		--! Por defecto conectar el producto punto
		--! Multiplicadores
		sfactor(f0) <= sparaminput(ax);sfactor(f1) <= sparaminput(bx);sfactor(f2) <= sparaminput(ay);sfactor(f3) <= sparaminput(by);			
		sfactor(f4) <= sparaminput(az);sfactor(f5) <= sparaminput(bz);sfactor(f6) <= sparaminput(cx);sfactor(f7) <= sparaminput(dx);
		sfactor(f8) <= sparaminput(cy);sfactor(f9) <= sparaminput(dy);sfactor(f10) <= sparaminput(cz);sfactor(f11) <= sparaminput(dz);
		--! Sumadores
		ssumando(s0) <= sprd32blk(p0);ssumando(s1) <= sprd32blk(p1);ssumando(s6) <= sadd32blk(a0);ssumando(s7) <= sdpfifo_q(dpfifoab);
		ssumando(s10) <= sdpfifo_q(dpfifocd);ssumando(s11) <=  sadd32blk(a2);ssumando(s4) <= sprd32blk(p4);ssumando(s5) <= sprd32blk(p5);
		ssumando(s2) <= (others => '0');ssumando(s3) <= (others => '0');ssumando(s8) <= (others => '0');ssumando(s9) <= (others => '0');			
		--!Signos
		add32blks <= "00";
		--!Resultados
		sresult(ax) <= sadd32blk(aa);
		sresult(bx) <= sadd32blk(ac);
		
		--!Factores de los multiplicadores. 
		case (instr3&hblock) is
			when "0011"  => 
				--!Multiplicadores: 
				sfactor(f0) <= sparaminput(cy);sfactor(f1) <= sparaminput(dz);sfactor(f2) <= sparaminput(cz);	sfactor(f3) <= sparaminput(dy);
				sfactor(f4) <= sparaminput(cx);sfactor(f5) <= sparaminput(dz);sfactor(f6) <= sparaminput(cz);sfactor(f7) <= sparaminput(dx);
				sfactor(f8) <= sparaminput(cx);sfactor(f9) <= sparaminput(dy);sfactor(f10) <= sparaminput(cy);sfactor(f11) <= sparaminput(dx);
			when "0010" => 				
				sfactor(f0) <= sparaminput(ay);sfactor(f1) <= sparaminput(bz);sfactor(f2) <= sparaminput(az);sfactor(f3) <= sparaminput(by);
				sfactor(f4) <= sparaminput(ax);sfactor(f5) <= sparaminput(bz);sfactor(f6) <= sparaminput(az);sfactor(f7) <= sparaminput(bx);
				sfactor(f8) <= sparaminput(ax);sfactor(f9) <= sparaminput(by);sfactor(f10) <= sparaminput(ay);sfactor(f11) <= sparaminput(bx);
			when others => 
		end case;			
		case (instr3) is
			when ""	
				--! Sumadores
				ssumando(s0) <= sprd32blk(p0);ssumando(s1) <= sprd32blk(p1);ssumando(s2) <= sprd32blk(p2);ssumando(s3) <= sprd32blk(p3);
				ssumando(s10) <= sdpfifo_q(dpfifocd);ssumando(s11) <=  sadd32blk(a2);ssumando(s4) <= sprd32blk(p4);ssumando(s5) <= sprd32blk(p5);
				--!Signos
				add32blks <= "10";
				--!Resultados
				sresult(ax) <= sadd32blk(a0);
				sresult(ay) <= sadd32blk(a1);
				sresult(az) <= sadd32blk(a2);
			
			when "suma"  => 
			
			 
				
							
				
				
				
										 	
			  
		end case;
		
	end process;
	
	
end dpc_arch;
