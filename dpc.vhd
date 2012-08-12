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
use ieee.std_logic_unsigned.all;
use work.arithpack.all;

library altera_mf;
use altera_mf.altera_mf_components.all;


entity dpc is 
	
	port (
		clk						: in	std_logic;
		rst						: in	std_logic;
		
		paraminput				: in	vectorblock06;	--! Vectores A,B
		
		prd32blko			 	: in	vectorblock06;	--! Salidas de los 6 multiplicadores.
		add32blko 				: in	vectorblock03;	--! Salidas de los 3 sumadores.
		inv32blko				: in	xfloat32;		--! Salidas de la raiz cuadradas y el inversor.
		sqr32blko				: in	xfloat32;		--! Salidas de la raiz cuadradas y el inversor.
		
		
		d,c,s					: in	std_logic;		--! Bit con el identificador del bloque AB vs CD e identificador del sub bloque (A/B) o (C/D). 
		
		sync_chain_1			: in	std_logic;		--! Se&ntilde;al de dato valido que se va por toda la cadena de sincronizacion.
		sync_chain_pendant		: out	std_logic;		--! Se&ntilde;al para indicar si hay datos en el pipeline aritm&eacute;tico.	
		
		qresult_w				: out	std_logic;	--! Salidas de escritura y lectura en las colas de resultados.
		qresult_d				: out	vectorblock04; --! 4 salidas de resultados, pues lo m&aacute;ximo que podr&aacute; calcularse por cada clock son 2 vectores. 

		prd32blki				: out	vectorblock12;	--! Entrada de los 12 factores en el bloque de multiplicaci&oacute;n respectivamente.
		add32blki				: out	vectorblock06	--! Entrada de los 6 sumandos del bloque de 3 sumadores.  


	);
end entity;

architecture dpc_arch of dpc is 
	
	--!TBXSTART:FACTORS_N_ADDENDS
	signal sfactor		: vectorblock12;
	signal ssumando		: vectorblock06;
	signal sdpfifo_q	: xfloat32;
	--!TBXEND
	
	
	--!TBXSTART:ARITHMETIC_RESULTS
	signal sresult 		: vectorblock04;
	signal sprd32blk	: vectorblock06;
	signal sadd32blk	: vectorblock03;
	signal ssqr32blk	: xfloat32;
	signal sinv32blk	: xfloat32;
	signal sqxyz_q		: vectorblock03;
	signal sqxyz_e		: std_logic;
	--!TBXEND
	
	
	--!TBXSTART:SYNC_CHAIN
	signal ssync_chain	: std_logic_vector(25 downto 2);
	--!TBXEND

	signal qxyzd		: std_logic_vector(95 downto 0);
	signal qxyzq		: std_logic_vector(95 downto 0);
	signal sq1_d		: std_logic_vector(31 downto 0);
	signal sq1_q		: std_logic_vector(31 downto 0);
	signal sq1_w		: std_logic;
	signal sq1_e		: std_logic;
	
begin

		
	
	--! Cadena de sincronizaci&oacute;n: 29 posiciones.
	sync_chain_pendant <= sync_chain_1 or sq1_e or sqxyz_e;
	sync_chain_proc:
	process(clk,rst,sync_chain_1)
	begin
		if rst=rstMasterValue then

			ssync_chain(25 downto 2) <= (others => '0');
			
		elsif clk'event and clk='1' then


			for i in 25 downto 3 loop
				ssync_chain(i) <= ssync_chain(i-1);
			end loop;
			ssync_chain(2) <= sync_chain_1;

		end if;
			
	
	end process sync_chain_proc;
	
		
	
	--! El siguiente c&oacute;digo sirve para conectar arreglos a se&ntilde;ales std_logic_1164, simplemente son abstracciones a nivel de c&oacute;digo y no representar&aacute; cambios en la s&iacute;ntesis.
	prd32blki <= sfactor;
	add32blki <= ssumando;
	qresult_d <= sresult;
	
	
	
	
	--! El siguiente c&oacute;digo sirve para conectar arreglos a se&ntilde;ales std_logic_1164, son abstracciones de c&oacute;digo tambi&eacute;n, sin embargo se realizan a trav&eacute;s de registros. 
	register_products_outputs:
	process (clk)
	begin
		if clk'event and clk='1' then
			sprd32blk  <= prd32blko;
			sadd32blk <= add32blko;
			sinv32blk <= inv32blko;
			--! Raiz Cuadrada.
			ssqr32blk <= sqr32blko;
		end if;
	end process;
	
	--! Decodificaci&oacute;n del Datapath.
	datapathproc:process(s,d,c,paraminput,sinv32blk,sprd32blk,sadd32blk,sdpfifo_q,sqxyz_q,ssync_chain,ssqr32blk,sq1_q)
	begin
		--Summador 0: DORC!
		if (d or c)='1' then
			ssumando(s0) <= sprd32blk(p0);
			ssumando(s1) <= sprd32blk(p1);
		else
			ssumando(s0) <= paraminput(ax);
			ssumando(s1) <= paraminput(bx);
		end if;
		--Sumador 1:
		if d='1' then
			ssumando(s2) <= sadd32blk(a0);
			ssumando(s3) <= sdpfifo_q;		
		elsif c='0' then
			ssumando(s2) <= paraminput(ay);
			ssumando(s3) <= paraminput(by);
		else
			ssumando(s2) <= sprd32blk(p2);
			ssumando(s3) <= sprd32blk(p3);
		end if;			
		--S2
		if c='0' then 
			ssumando(s4) <= paraminput(az);
			ssumando(s5) <= paraminput(bz);
		else
			ssumando(s4) <= sprd32blk(p4);
			ssumando(s5) <= sprd32blk(p5);
		end if;		
		--P0,P1,P2
		sfactor(f4) <= paraminput(az);
		if (not(d) and c)='1' then
			sfactor(f0) <= paraminput(ay);
			sfactor(f1) <= paraminput(bz);
			sfactor(f2) <= paraminput(az);
			sfactor(f3) <= paraminput(by);
			sfactor(f5) <= paraminput(bx);
		else
			sfactor(f0) <= paraminput(ax);
			sfactor(f2) <= paraminput(ay);
			sfactor(f1) <= paraminput(bx) ;
			sfactor(f3) <= paraminput(by) ;
			sfactor(f5) <= paraminput(bz) ;
		end if;		
		--P3 P4 P5
		if (c and s)='1' then
			sfactor(f6) <= paraminput(ax);
			sfactor(f9) <= paraminput(by);
		else
			sfactor(f6) <= sinv32blk;
			sfactor(f9) <= sqxyz_q(qy);
		end if;
		if d='1' then
			if s='0' then
				sfactor(f7) <= sqxyz_q(qx);
				sfactor(f8) <= sinv32blk;
				sfactor(f10) <= sinv32blk;			
				sfactor(f11) <= sqxyz_q(qz);
			else
				sfactor(f7) <= paraminput(bx);
				sfactor(f8) <= paraminput(ay);
				sfactor(f10) <= paraminput(az);
				sfactor(f11) <= paraminput(bz);
			end if;
		else  
			sfactor(f7) <= paraminput(bz);
			sfactor(f8) <= paraminput(ax);
			sfactor(f10) <= paraminput(ay);
			sfactor(f11) <= paraminput(bx);
		end if;		
		--res0,1,2			
		if d='1' then
			sresult(qx) <= sprd32blk(p3);
			sresult(qy) <= sprd32blk(p4);
			sresult(qz) <= sprd32blk(p5);
		else
			sresult(qx) <= sadd32blk(a0);
			sresult(qy) <= sadd32blk(a1);
			sresult(qz) <= sadd32blk(a2);
		end if;				
		--res3
		
		sresult(sc) <= sq1_q;
		if c='1' then
			sq1_d <= ssqr32blk;
			sq1_w <= ssync_chain(20);
		else
			sq1_w <= ssync_chain(19);
			sq1_d <= sadd32blk(a1);
		end if;
		
		if d='1' then
			if s='1'then
				qresult_w <= ssync_chain(5);
			else
				qresult_w<= ssync_chain(25);
			end if;			
		else  
			if c='1' and s='1' then
				qresult_w <= ssync_chain(12);
			elsif c='0' then 
				qresult_w <= ssync_chain(8);
			else
				qresult_w <= '0';
			end if;			
		end if;
	end process;
	
	--! Colas internas de producto punto, ubicada en el pipe line aritm&eacute;co. Paralelo a los sumadores a0 y a2.  
	q0 : scfifo --! Debe ir registrada la salida.
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 3,
		lpm_numwords			=> 6,
		lpm_showahead			=> "ON",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "OFF"
	)
	port	map (
		sclr		=> '0',
		clock		=> clk,
		empty		=> sq1_e,
		rdreq		=> ssync_chain(12),
		wrreq		=> ssync_chain(5),
		data		=> sprd32blk(p2),
		q			=> sdpfifo_q
	);
	--! Colas internas de producto punto, ubicada en el pipe line aritm&eacute;co. Paralelo a los sumadores a0 y a2.  
	q1 : scfifo --! Debe ir registrada la salida.
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 3,
		lpm_numwords			=> 5,
		lpm_showahead			=> "ON",
		lpm_type				=> "SCIFIFO",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "OFF"
	)
	port map (
		rdreq		=> ssync_chain(25),
		sclr		=> '0',
		clock		=> clk,
		q			=> sq1_q,
		wrreq		=> sq1_w,
		data		=> sq1_d
	);
	
	--! Cola interna de normalizaci&oacute;n de vectores, ubicada entre el pipeline aritm&eacute;tico
	qxyzd(ax*32+31 downto ax*32) <= paraminput(ax);
	qxyzd(ay*32+31 downto ay*32) <= paraminput(ay);
	qxyzd(az*32+31 downto az*32) <= paraminput(az);
	sqxyz_q(ax) <= qxyzq(ax*32+31 downto ax*32);
	sqxyz_q(ay) <= qxyzq(ay*32+31 downto ay*32);
	sqxyz_q(az) <= qxyzq(az*32+31 downto az*32);
	
	qxqyqz : scfifo
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 5,
		lpm_numwords			=> 32,
		lpm_showahead			=> "ON",
		lpm_width				=> 96,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		aclr		=> '0',
		clock		=> clk,
		empty		=> sqxyz_e,
		rdreq		=> ssync_chain(21),
		wrreq		=> sync_chain_1,
		data		=> qxyzd,
		q			=> qxyzq
	);

	
	
	
end architecture;
