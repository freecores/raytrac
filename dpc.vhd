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
end entity;

architecture dpc_arch of dpc is 
	
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
	signal q1xyz_32x19_q,q1xyz_32x19_d	: vectorblock03;
		
	--!TBXEND
	
	
	--!TBXSTART:SYNC_CHAIN
	signal ssync_chain					: std_logic_vector(25 downto 1);
	signal sres							: std_logic_vector(3 downto 0);
	--!TBXEND
	
	signal q1xyzd						: std_logic_vector(95 downto 0);
	signal q1xyzq						: std_logic_vector(95 downto 0);
	
	
	
begin


	--! Dataout, se encuentra en el "dominio" de la interface Avalon.	
	--! Procedimiento de decodificaci&oacute;n de se&ntilde;al de lectura.
	read_dataout:
	process(clk,rst,qresult_q,dataread,qresult_sel)
	begin 
		if rst=rstMasterValue then
			dataout <= (others => '0');
		elsif clk'event and clk='1' and dataread='1' then
			case qresult_sel(1 downto 0) is
				when "00" => 
					dataout <= qresult_q(0);					
				when "01" => 
					dataout <= qresult_q(1);					
				when "10" => 
					dataout <= qresult_q(2);					
				when others => 
					dataout <= qresult_q(3);					
			end case;
		end if; 				 
	end process;
	decode_wra:
	process(dataread,qresult_sel)
	begin 
		if dataread='1' then
			case qresult_sel(1 downto 0) is
				when "00" =>
					qresult_rdec <= "0001";
				when "01" => 
					qresult_rdec <= "0010";
				when "10" => 
					qresult_rdec <= "0100";
				when others => 
					qresult_rdec <= "1000";
			end case;
		else
			qresult_rdec <= (others => '0');
		end if; 				 
	end process;
		
	
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
	q1xyz_32x19_w	<= ssync_chain(1);
		
	--! Salida de se&ntilde;ales de datos que se van a escribir en la cola de resultados.	
	qresult_w	<= sres;
	
	--! El siguiente c&oacute;digo sirve para conectar arreglos a se&ntilde;ales std_logic_1164, simplemente son abstracciones a nivel de c&oacute;digo y no representar&aacute; cambios en la s&iacute;ntesis.
	sparaminput	<= paraminput;
	prd32blki	<= sfactor;
	add32blki	<= ssumando;
	qresult_d	<= sresult;
	
	
	
	
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
	
	
	
	--! Cola de normalizacion
	q1xyz_32x19_d(qx) <= sparaminput(ax);
	q1xyz_32x19_d(qy) <= sparaminput(ay);
	q1xyz_32x19_d(qz) <= sparaminput(az);
	
	
	--! La entrada de la ra&iacute;z cuadrada SIEMPRE viene con la salida del sumador 1.
	sqr32blki <= add32blko(a1);
	
	--! Decodificaci&oacute;n del Datapath.
	datapathproc:process(s,d,c,sparaminput,sinv32blk,sprd32blk,sadd32blk,sdpfifo_q,q1xyz_32x19_q,ssync_chain,ssqr32blk)
	begin
		--Summador 0: DORC!
		if (d or c)='1' then
			ssumando(s0) <= sprd32blk(p0);
			ssumando(s1) <= sprd32blk(p1);
		else
			ssumando(s0) <= sparaminput(ax);
			ssumando(s1) <= sparaminput(bx);
		end if;
		--Sumador 1:
		if d='1' then
			ssumando(s2) <= sadd32blk(a0);
			ssumando(s3) <= sdpfifo_q;		
		elsif c='0' then
			ssumando(s2) <= sparaminput(ay);
			ssumando(s3) <= sparaminput(by);
		else
			ssumando(s2) <= sprd32blk(p2);
			ssumando(s3) <= sprd32blk(p3);
		end if;			
		--S2
		if c='0' then 
			ssumando(s4) <= sparaminput(az);
			ssumando(s5) <= sparaminput(bz);
		else
			ssumando(s4) <= sprd32blk(p4);
			ssumando(s5) <= sprd32blk(p5);
		end if;		
		--P0,P1,P2
		sfactor(f4) <= sparaminput(az);
		if (not(d) and c)='1' then
			sfactor(f0) <= sparaminput(ay);
			sfactor(f1) <= sparaminput(bz);
			sfactor(f2) <= sparaminput(az);
			sfactor(f3) <= sparaminput(by);
			sfactor(f5) <= sparaminput(bx);
		else
			sfactor(f0) <= sparaminput(ax);
			sfactor(f2) <= sparaminput(ay);
			sfactor(f1) <= sparaminput(bx) ;
			sfactor(f3) <= sparaminput(by) ;
			sfactor(f5) <= sparaminput(bz) ;
		end if;		
		--P3 P4 P5
		if (c and s)='1' then
			sfactor(f6) <= sparaminput(ax);
			sfactor(f9) <= sparaminput(by);
		else
			sfactor(f6) <= sinv32blk;
			sfactor(f9) <= q1xyz_32x19_q(ay);
		end if;
		if d='1' then
			if s='0' then
				sfactor(f7) <= q1xyz_32x19_q(ax);
				sfactor(f8) <= sinv32blk;
				sfactor(f10) <= sinv32blk;			
				sfactor(f11) <= q1xyz_32x19_q(az);
			else
				sfactor(f7) <= sparaminput(bx);
				sfactor(f8) <= sparaminput(ay);
				sfactor(f10) <= sparaminput(az);
				sfactor(f11) <= sparaminput(bz);
			end if;
		else  
			sfactor(f7) <= sparaminput(bz);
			sfactor(f8) <= sparaminput(ax);
			sfactor(f10) <= sparaminput(ay);
			sfactor(f11) <= sparaminput(bx);
		end if;		
		--res0,1,2			
		if d='1' then
			sresult(0) <= sprd32blk(p3);
			sresult(1) <= sprd32blk(p4);
			sresult(2) <= sprd32blk(p5);
		else
			sresult(0) <= sadd32blk(a0);
			sresult(1) <= sadd32blk(a1);
			sresult(2) <= sadd32blk(a2);
		end if;				
		--res3
		if c='1' then
			sresult(3) <= ssqr32blk;
			sres(3) <= ssync_chain(20) and d and not(s);
		else
			sresult(3) <= sadd32blk(a1);
			sres(3) <= ssync_chain(19) and d and not(s);
		end if;
		
		if d='1' then
			if c='1' and s='1' then
				sres(2 downto 0) <= ssync_chain(5)&ssync_chain(5)&ssync_chain(5);
			elsif c='1' then
				sres(2 downto 0) <= ssync_chain(25)&ssync_chain(25)&ssync_chain(25);
			else
				sres(2 downto 0) <= (others => '0');
			end if;			
		else  
			if c='1' and s='1' then
				sres(2 downto 0) <= ssync_chain(12)&ssync_chain(12)&ssync_chain(12);
			elsif c='0' then 
				sres(2 downto 0) <= ssync_chain(8)&ssync_chain(8)&ssync_chain(8);
			else
				sres(2 downto 0) <= (others => '0');
			end if;			
		end if;
	end process;
	
	--! Colas internas de producto punto, ubicada en el pipe line aritm&eacute;co. Paralelo a los sumadores a0 y a2.  
	q0 : scfifo --! Debe ir registrada la salida.
	generic map (
		add_ram_output_register	=> "OFF",
		allow_rwcycle_when_full => "OFF",
		intended_device_family	=> "CycloneIII",
		lpm_hint				=> "MAXIMUM_DEPTH=8",
		lpm_numwords			=> 8,
		lpm_showahead			=> "ON",
		lpm_type				=> "SCIFIFO",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "OFF"
	)
	port	map (
		rdreq		=> ssync_chain(12),
		aclr		=> '0',
		clock		=> clk,
		q			=> sdpfifo_q,
		wrreq		=> ssync_chain(5),
		data		=> sprd32blk(p2)
	);
	
	--! Cola interna de normalizaci&oacute;n de vectores, ubicada entre el pipeline aritm&eacute;tico
	q1xyzd(95 downto 64) <= q1xyz_32x19_d(ax);
	q1xyzd(63 downto 32) <= q1xyz_32x19_d(ay);
	q1xyzd(31 downto 00) <= q1xyz_32x19_d(az);
	q1xyz_32x19_q(ax) <= q1xyzq(95 downto 64);
	q1xyz_32x19_q(ay) <= q1xyzq(63 downto 32);
	q1xyz_32x19_q(az) <= q1xyzq(31 downto 00);
	
	qxqyqz : scfifo
	generic map (
		add_ram_output_register => "OFF",
		allow_rwcycle_when_full => "OFF",
		intended_device_family  => "Cyclone III",
		lpm_hint                => "RAM_BLOCK_TYPE=M9K",
		lpm_numwords			=> 32,
		lpm_showahead			=> "OFF",
		lpm_type				=> "SCFIFO",
		lpm_width				=> 96,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		rdreq		=> ssync_chain(21),
		aclr		=> '0',
		clock		=> clk,
		q			=> q1xyzq,
		wrreq		=> ssync_chain(1),
		data		=> q1xyzd
	);

	
	
	
end architecture;
