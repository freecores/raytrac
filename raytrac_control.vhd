--! @file raytrac_control.vhd
--! @brief Maquina de Estados. Controla la operaci&oacute;n interna y genera los mecanismos de sincronizaci&oacute;n con el exterior (interrupciones). 
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------------------
-- RAYTRAC
-- Author Julian Andres Guarin
-- raytrac_control.vhd
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

entity raytrac_control is
	generic (
		wd	:	integer:=
	)
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
		--readdatavalid_m	: in	std_logic;
				
		--! Interface Avalon Slave
		slave_address	:	in std_logic_vector(n-1 downto 0);
		slave_read		:	in std_logic;
		slave_write		:	in std_logic;
		slave_readdata	:	out std_logic_vector(wd-1 downto 0);
		slave_writedata	:	in std_logic_vector(wd-1 downto 0);
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
end entity;

architecture raytrac_control_arch of raytrac_control is
	
	--! Estados
	type rtState is (IDLE,FETCH,ARITH,TX,DMAFETCH,DMATX);
	signal state : rtState;
	
	constant reg_ctrl	 	: integer := 00;
	constant reg_sadd_r		: integer := 01;
	constant reg_eadd_r 	: integer := 02;
	constant reg_sadd_w		: integer := 03;
	constant reg_scratch	: integer := 07;
	
	constant cr_go	: integer:=00;
	constant cr_tx	: integer:=01;
	constant cr_ld	: integer:=02;
	constant cr_s	: integer:=03;
	constant cr_c	: integer:=04;
	constant cr_d	: integer:=05;
	constant cr_cmb : integer:=06;
	constant cr_sc	: integer:=07;
	constant cr_vt	: integer:=08;
	constant cr_nrl	: integer:=09;
	constant cr_nrh : integer:=18;
	constant cr_dma : integer:=19;
	
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! Control Register (cr)																													|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! Bit No.	| Nombre	| Descripci&oacute;n																								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! 0		| go (rw)	| 1:	Comienza el fetch de parametros en la Interfase Master.														|
	--! 		|			| 		Go permite la carga de datos desde la cola de par&aacute;metros al pipeline aritm&eacute;tico.				|
	--!			|			| 0:	Estado Idle. El fetch de parametros de la Interfase Master queda suspendida si se hab&iacute;a iniciado.	|
	--!			|			|		El sistema pasa de estado fetch a estado Idle autom&aacute;ticamente. Una vez haya terminado de registrar en|
	--!			|			|		el slave la &uacute;ltima direcci&oacute;n (endaddress).													|
	--!			|			|																													|
	--!			|			|		Para mas informaci&oacute;n sobre como el slave hace fecth de las direcciones que env&iacute;a el maste		|
	--!			|			|		consultar el documento, Avalon Interface Specification, Chapter 3, Avalon Memory-Mapped Interfaces,			|
	--!			|			|		pag 3-11. Altera Corp. Design Suite 11.0 May 2011.															|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! 1		| tx (r)	| 1:	El RayTrac se encuentra transmitiendo los resultados de las operaciones en el pipeline aritm&eacute;tico 	|
	--!			|			|		por la interface Master hacia una memoria exterior. No necesariamente en ese momento está transmitiendo		|
	--!			|			|		puede tambi&eacute;n darse el caso que est&eacute; esperando a que haya datos en las colas de resultados	|
	--!			|			| 0:	La transmis&oacute;n de resultados hacia el exterior se encuentra inactiva.									|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 2		| ld (rw)	| 1:	Resetea todas las colas, las de resultados y la de par&aacute;metros. Resetea la carga de la cadena de		| 
	--!			|			|		sincronizaci&oacute;n de carga y coloca el resultado de los bit csc0 y csc1.								| 
	--!			|			|		Una vez el usuario desarrollador, deje de escribir en este registro este bit se autoescribe en 0			|
	--!			|			| 0:	Este valor es el observado por el usuario desarrollador una vez lea este registro. 							|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--!			|			|		Configuraci&oacute;n del Datapath, Interconexi&oacute;n del Pipeline Aritm&eacute;tico y Cadena de Carga	|
	--!			|			|		Dependiendo del valor de estos 3 bits se configura la operaci&oacute;n a ejecutar.							|
	--!			|			|																													|
	--! [5:3]	| dcs (rw)	| 011:	Producto Cruz																								|
	--!			|			| 000:	Suma Vectorial																								|
	--!			|			| 001:	Resta Vectorial																								|
	--!			|			| 110:	Normalizaci&oacute;n Vectorial y c&aacute;lculo de Magnitud Vectorial										|
	--!			|			| 100:	Producto Punto																								|
	--!			|			| 111:	Producto Simple																								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 6		| cmb (rw)	| 1:	La operaci&oacute;n es combinatoria, por lo tanto solo se cargan vectores en el operando B.					|
	--!			|			| 0:	La operaci&oacute;n no es combinatoria, se cargan vectores en los operandos A y B.							|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--!			|			| En el caso de que dcs sea 110 (Normalizaci&oacute;n y Magnitud Vectorial) este par de bits indica que resultados	|
	--!			|			| escribir. Si dcs tiene un valor diferente a 110 se ignora este campo.												|
	--!			|			|																													|
	--![8:7]	| vtsc (rw)	| 00:	Solo leer los resultados vectoriales.																		|
	--!			|			| 01:	Solo leer los resultados escalares.																			|
	--!			|			| 10:	Solo leer los resultados vectoriales.																		|
	--!			|			| 11:	Leer los resultados escalares y vectoriales.																|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--![18:9]	| nres (rw) | N&uacute;mero de resultados a escribir en la memoria de resultados.												|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 19		| dma (rw)	| 1:	Operaci&oacute;n de DMA simple. Transfiere los datos entre psadd y peadd a rsadd. El sistema				|
	--!			|			|		Se hace un override del sistema completo. Se escribe cuando el sistema esta IDLE. Una vez se termina la 	|
	--!			|			|		trasnferencia el sistema vuelve al estado IDLE. El n&uacute;mero m&aacute;ximo de transferencis es 256		|
	--!			|			|		datos.																										|
	--!			|			| 0:	El se encuentra en operaci&oacute;n normal.																	|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Start Parameter Address (psadd)																											|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--![31:0]	| sadd (rw) | Direcci&oacute;n de memoria donde se encuentra el primer par&aacute;metro de entrada.								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! End Parameter Address (peadd)																											|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--![31:0]	| eadd (rw) | Direcci&oacute;n de memoria donde se encuentra el &uacute;ltimo par&aacute;metro de entrada.						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Start Result Address (rsadd)																											|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--![31:0]	| rsadd (rw)| Direcci&oacute;n de memoria donde se encuentra el primer par&aacute;metro de entrada.								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Scratch Register (screg)																												|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--![31:0]	| screg (rw)| Direcci&oacute;n de memoria donde se pueden escribir y leer valores de 32 bits.									|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	

		
	signal sregister_block	: vectorblock08;
	signal swaitrequest_n	: std_logic;
	signal sstartadd		: std_logic_vector(31 downto 0);
	signal sendadd			: std_logic_vector(31 downto 2);			
	signal sstateTrans			: std_logic;
	signal sendaddressfetch	: std_logic;
	
	
	--! Slave Drive
	signal saddress_slave	: std_logic_vector(03 downto 0);
	signal sread_slave		: std_logic;
	signal swrite_slave		: std_logic;
	signal swritedata_slave	: std_logic_vector(31 downto 0);
	

begin

--	stateProc:
--	process(
--		clk,
--		rst,
--		sendaddressfetch,
--		address_slave,
--		write_slave,
--		swritedata_slave(0),
--		swritedata_slave(19),
--		qresult_e(0),
--		qresult_e(3),
--		sregister_block(reg_ctrl)(cr_vt downto cr_sc)
--	)
--	begin
--		if rst=rstMasterValue  then
--			state <= IDLE;
--		elsif clk'event and clk='1' then
--		
--			case state is
--				when IDLE => 
--					--!Detectar si es inminente el cambio al siguiente estado
--					if saddress_slave=x"0" and swritedata_slave(cr_dma)='1' and swrite_slave='1' then
--						--state <= DMAFETCH;
--						state <= IDLE;
--					elsif saddress_slave=x"0" and swritedata_slave(cr_go)='1' and swrite_slave='1' then
--						--! Nuevo Estado
--						--state <= FETCH;
--						state <= IDLE;
--					end if;
--				when FETCH => 
--					if sendaddressfetch='1' then 
--						--! Revisar si la operaci&oacute;n da la opci&oacute;n de obtener dos tipos de resultados: vectorial y escalar.
--						if  (sregister_block(reg_ctrl)(cr_vt downto cr_sc)="01" and qresult_e(3)='0') or (sregister_block(reg_ctrl)(cr_vt downto cr_sc)/="01" and qresult_e(0)='0') then
--							--! Si solo se va a leer los resultados escalares
--							state <= TX;
--						else
--							state <= ARITH;
--						end if;
--					end if;
--				when TX => 
--					if sendaddressfetch='1' then
--						state <= IDLE;									
--					end if;
--				when ARITH => 
--					--!Esperar a que haya un resultado 
--					if  (sregister_block(reg_ctrl)(cr_vt downto cr_sc)="01" and qresult_e(3)='0') or (sregister_block(reg_ctrl)(cr_vt downto cr_sc)/="01" and qresult_e(0)='0') then
--						--! Si solo se va a leer los resultados escalares
--						state <= TX;
--					end if;
--				
--				when DMAFETCH => 
--					if sendaddressfetch='1' then 
--						state <= DMATX;
--					end if;
--				when DMATX => 
--					if sendaddressfetch='1' then
--						state <= IDLE;
--					end if;
--				when others => 
--					state <= IDLE;
--			end case;  						
--		end if;
--	end process;
--	
	--! Address Counters
	--!TBXINSTANCESTART
	swaitrequest_n <= not(waitrequest);
	addCntr:customCounter
	port map (
		clk 			=> clk,
		rst 			=> rst,
		stateTrans 		=> sstateTrans,
		waitrequest_n	=> swaitrequest_n,
		endaddress 		=> sendadd,
		startaddress	=> sstartadd,
		endaddressfetch	=> sendaddressfetch,
		address_master	=> address_master
		
	);
	--!TBXINSTANCEEND
	
	addCntrLoadValueSelector:
	process (state)
	begin
		--! TRANSMISI&OACUTE;N : Si el estado es modo de transmisi&oacute;n de resultados (tx='1') entonces asignar las direcciones de escritura de resultados.
		if state = IDLE then 
			sendadd 	<= sregister_block(reg_eadd_r)(31 downto 2);
			sstartadd	<= sregister_block(reg_sadd_r);
		--! FETCH : Si el modo NO ES transmisi&oacute;n de resultados (tx='0') entonces asignar las direcciones de lectura de param&eacute;tros.
		else
			sendadd 	<= (X"00000"&sregister_block(reg_ctrl)(cr_nrh downto cr_nrl))+sregister_block(reg_sadd_w)(31 downto 2);
			sstartadd	<= sregister_block(reg_sadd_w);
		end if;
	end process;
	
	
	loadCtrl:
	process (state)
	begin
		if state=IDLE then
			load <= '1';
		elsif state=FETCH and sendaddressfetch='1' then
			--! Si solo se va a leer los resultados escalares
			load <= '1';
		else
			load <= '0';
		end if;  
	end process;
	  
	--! Slave Interface Drive
	
	i_s:
	process (clk,rst,address_slave,read_slave,write_slave,writedata_slave,sendaddressfetch,state)
	begin
		if rst=rstMasterValue then
			sregister_block(reg_ctrl)(31 downto cr_go) <= (others => '0');
			for i in 07 downto 01 loop
				sregister_block(i) <= (others => '0');
			end loop;
			--readdatavalid_s <= '0';
			readdata_slave <= (others => '0');
		elsif clk'event and clk='1' then
			--! Register Slave Interface Input Signals.
			saddress_slave	<= address_slave;
			sread_slave		<= read_slave;
			swrite_slave	<= write_slave;
			swritedata_slave<= writedata_slave;
			case state is 
				when IDLE  => 
					--readdatavalid_s <= swrite_slave; 
					case saddress_slave is
						when x"0" =>
							if swrite_slave='1' then
								sregister_block(reg_ctrl)(31 downto cr_ld) <= swritedata_slave(31 downto cr_ld);
								sregister_block(reg_ctrl)(cr_tx) <= '0';
								sregister_block(reg_ctrl)(cr_go) <= swritedata_slave(cr_go);  
								
							end if;
							if sread_slave='1' then 
								readdata_slave <= sregister_block(reg_ctrl);
							end if;
						when x"1" => 
							if swrite_slave='1' then 
								sregister_block(reg_sadd_r) <= swritedata_slave;
							end if;
							if sread_slave='1' then 
								readdata_slave <= sregister_block(reg_sadd_r);
							end if;
						when x"2" =>
							if swrite_slave='1' then 
								sregister_block(reg_eadd_r) <= swritedata_slave;
							end if;
							if sread_slave='1' then 
								readdata_slave <= sregister_block(reg_eadd_r);
							end if;
						when x"3" =>
							if swrite_slave='1' then
								sregister_block(reg_sadd_w) <= swritedata_slave;
							end if;
							if sread_slave='1' then 
								readdata_slave <= sregister_block(reg_sadd_w);
							end if;
						when others =>
							if swrite_slave='1' then  
								sregister_block(reg_scratch) <= swritedata_slave;
							end if;
							if sread_slave='1' then 
								readdata_slave <= sregister_block(reg_scratch);
							end if;
					end case;
					
				when others => 
					--readdatavalid_s <= '0';
			end case;
		end if;				
	end process;		
	
	--! Se&ntilde;ales de Control (Memblock)
	go			<= sregister_block(reg_ctrl)(cr_go);
	comb		<= sregister_block(reg_ctrl)(cr_cmb);
	--load		<= sregister_block(reg_ctrl)(cr_ld);
	load_chain(0)	<= '1';
	load_chain(1)	<= sregister_block(reg_ctrl)(cr_d) and sregister_block(reg_ctrl)(cr_c) and not(sregister_block(reg_ctrl)(cr_s));
	 
	--! Se&ntilde;ales a Datapath
	d	<= sregister_block(reg_ctrl)(cr_d); 
	c	<= sregister_block(reg_ctrl)(cr_c); 
	s	<= sregister_block(reg_ctrl)(cr_s); 
	
	
	
end architecture;
