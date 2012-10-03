--! @file raytrac.vhd
--! @brief Sistema de Procesamiento Vectorial. La interface es compatible con el bus Avalon de Altera.  
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------------------
-- RAYTRAC
-- Author Julian Andres Guarin
-- raytrac.vhd
-- This file is part of raytrac.
-- 
--     raytrac is free software: you can redistribute it and/or modify
--     it under the terms of the GNU General Public License as published by
--     the Free Software Foundation, either version 3 of the License, or
--     (at your option) any later version.
-- 
--     raytrac is distributed in the hope that it will be useful,
--     but WITHOUT ANY WARRANTY; without even the implied warranty of
--     MERCHANTABILITY or FITNESS FOR a PARTICULAR PURPOSE.  See the
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

library lpm;
use lpm.lpm_components.all;


entity raytrac is 
	generic (
		wd	:	integer := 32;
		fd	:	integer := 8;	--! Result Fifo Depth = 2**fd =256
		mb	:	integer := 4	--! Max Burst Length = 2**mb		
	);
	port (
		clk:	in std_logic;
		rst:	in std_logic;
		
		--! Avalon MM Slave
		slave_address				:	in 	std_logic_vector(3 downto 0);
		slave_read				:	in 	std_logic;
		slave_write				:	in 	std_logic;
		slave_readdata			:	out	std_logic_vector(31 downto 0);
		slave_writedata			:	in	std_logic_vector(31 downto 0);
	
		--! Avalon MM Master (Read & Write common signals)	
		master_address			:	out	std_logic_vector(31 downto 0);
		master_burstcount			:	out	std_logic_vector(4 downto 0);
		master_waitrequest			:	in	std_logic;
		
		--! Avalon MM Master (Read Stage)
		master_read				:	out	std_logic;
		master_readdata			:	in	std_logic_vector(31 downto 0);
		master_readdatavalid		:	in	std_logic;	

		--! Avalon MM Master (Write Stage)
		master_write			:	out	std_logic;
		master_writedata		:	out std_logic_vector(31 downto 0);
		
		--! Avalon IRQ
		irq						:	out std_logic
		
		
		
	);
end entity;


architecture raytrac_arch of raytrac is


	--! Altera Compiler Directive, to avoid m9k autoinferring thanks to the guys at http://www.alteraforum.com/forum/archive/index.php/t-30784.html .... 
	attribute altera_attribute : string; 
	attribute altera_attribute of raytrac_arch : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF";
	

	type	registerblock	is array (15 downto 0) of xfloat32;
	type	transferState	is (IDLE,SINK,SOURCE);
	type upload_chain 	is (UPVX,UPVY,UPVZ,SC,DMA);
	type	download_chain  is (DWAX,DWAY,DWAZ,DWBX,DWBY,DWBZ,DWAXBX,DWAYBY,DWAZBZ);
	
	constant reg_ctrl 				:	integer:=00;
	constant reg_vz				:	integer:=01;
	constant reg_vy				:	integer:=02;
	constant reg_vx				:	integer:=03;
	constant reg_scalar			:	integer:=04;
	constant reg_nfetch			:	integer:=05;
	constant reg_timercounter		:	integer:=06;
	constant reg_inputcounter		:	integer:=07;
	constant reg_fetchstart			:	integer:=08;
	constant reg_sinkstart			:	integer:=09;
	constant reg_ax				:	integer:=10;
	constant reg_ay				:	integer:=11;
	constant reg_az				:	integer:=12;
	constant reg_bx				:	integer:=13;
	constant reg_by				:	integer:=14;
	constant reg_bz				:	integer:=15;


	
	constant reg_ctrl_cmb			:	integer:=00;	--! CMB bit : Combinatorial Instruction.
	constant reg_ctrl_s			:	integer:=01;	--! S bit of the DCS field.
	constant reg_ctrl_c			:	integer:=02;	--! C bit of the DCS field.
	constant reg_ctrl_d			:	integer:=03;	--! D bit of the DCS field.
	
	constant reg_ctrl_sc			:	integer:=04;	--! SC bit of the VTSC field.
	constant reg_ctrl_vt			:	integer:=05;	--! VT bit of the VTSC field.
	constant reg_ctrl_dma			:	integer:=06;	--! DMA bit.
	constant reg_ctrl_flags_fc		:	integer:=07;	--! Flood Condition Flag.
	
	constant reg_ctrl_flags_dc		:	integer:=08;	--! Drain Condition Flag.	
	constant reg_ctrl_flags_wp		:	integer:=09;	--! Write on Memory Pending Flag.
	constant reg_ctrl_flags_pp		:	integer:=10;	--! Pipeline Pending Flag.
	constant reg_ctrl_flags_pl		:	integer:=11;	--! Load Parameter Pending Flag.
	
	constant reg_ctrl_flags_dp		:	integer:=12;	--! Data Pending flag.
	constant reg_ctrl_flags_ap		:	integer:=13;	--! Address Pending Flag.
	constant reg_ctrl_rlsc			:	integer:=14;	--! RLSC bit : Reload Load Sync Chain.
	constant reg_ctrl_rom			:	integer:=15;	--! ROM bit : Read Only Mode bit.
	
	constant reg_ctrl_alb			:	integer:=16;	--! Conditional Writing. A<B.
	constant reg_ctrl_ageb			:	integer:=17;	--! A>=B.
	constant reg_ctrl_aeb			:	integer:=18;	--! A==B.
	constant reg_ctrl_aneb			:	integer:=19;	--! A!=B.
	
	constant reg_ctrl_accum_op		:	integer:=20;	--! Acummulative Addition/Sub. User must write in the high word of nfetch how many time should be executed the addition/sub.
	
	constant reg_ctrl_irq			:	integer:=31;	--! IRQ bit : Interrupt Request Signal.

	--! Nfetch Reg Mask
	constant reg_nfetch_high	:	integer:=11;	--! NFETCH_HIGH : Higher bit to program the number of addresses to load in the interconnection. 
			
		
	--! Avalon MM Slave
	
	signal	sreg_block			:	registerblock;
	signal	sslave_read			:	std_logic;
	signal	sslave_write		:	std_logic;
	signal	sslave_writedata	:	std_logic_vector (wd-1 downto 0);
	signal	sslave_address		:	std_logic_vector (3 downto 0);
	signal	sslave_waitrequest	:	std_logic;
	
	--! Avalon MM Master
	signal	smaster_write		:	std_logic;
	signal	smaster_read		:	std_logic;
	
	--! State Machine and event signaling
	signal sm					:	transferState;
	
	signal sr_e					:	std_logic;
	signal sr_ack				:	std_logic;
	signal soutb_ack			:	std_logic;
	
	
	
	signal soutb_d				:	std_logic_vector(wd-1 downto 0);
	
	
	signal soutb_w				:	std_logic;
	
	signal soutb_e				:	std_logic;
	signal soutb_ae				:	std_logic;
	signal soutb_af				:	std_logic;
	signal soutb_usedw			:	std_logic_vector(fd-1 downto 0);

	signal ssync_chain_1		:	std_logic;
	
	signal ssync_chain_pending	:	std_logic;
	signal sfetch_data_pending	:	std_logic;
	signal sload_add_pending	:	std_logic;
	signal spipeline_pending	:	std_logic;
	signal swrite_pending		:   std_logic;
	signal sparamload_pending	:	std_logic;
	signal sZeroTransit			:	std_logic;
	
	
	--!Unload Control
	signal supload_chain	: upload_chain;
	signal supload_start	: upload_chain;
		
	--!Se&ntilde;ales de apoyo:
	signal zero : std_logic_vector(31 downto 0);
	
	--!High Register Bank Control Signals or AKA Load Sync Chain Control
	signal sdownload_chain	: download_chain;
	signal sdownload_start	: download_chain; 
	--!State Machine Hysteresis Control Signals
	signal sdrain_condition 	: std_logic;
	signal sdrain_burstcount	: std_logic_vector(mb downto 0);
	signal sdata_fetch_counter	: std_logic_vector(reg_nfetch_high downto 0);
	signal sburstcount_sink		: std_logic_vector(mb downto 0);
	
	signal sflood_condition 	: std_logic;
	signal sflood_burstcount 	: std_logic_vector(mb downto 0);

	signal sp0,sp1,sp2,sp3,sp4,sp5,sp6,sp7,sp8: std_logic_vector(31 downto 0);
	--! Arithmetic Pipeline and Data Path Control
	component ap_n_dpc
	port (
		
		p0,p1,p2,p3,p4,p5,p6,p7,p8	: out std_logic_vector(31 downto 0);
		clk						: in	std_logic;
		rst						: in	std_logic;
		ax						: in	std_logic_vector(31 downto 0);
		ay						: in	std_logic_vector(31 downto 0);
		az						: in	std_logic_vector(31 downto 0);
		bx						: in	std_logic_vector(31 downto 0);
		by						: in	std_logic_vector(31 downto 0);
		bz						: in	std_logic_vector(31 downto 0);
		vx						: out	std_logic_vector(31 downto 0);
		vy						: out	std_logic_vector(31 downto 0);
		vz						: out	std_logic_vector(31 downto 0);
		sc						: out	std_logic_vector(31 downto 0);
		ack						: in	std_logic;
		empty					: out	std_logic;
		dcs						: in	std_logic_vector(2 downto 0);		--! Bit con el identificador del bloque AB vs CD e identificador del sub bloque (A/B) o (C/D). 
		sync_chain_1				: in	std_logic;		--! Se&ntilde;al de dato valido que se va por toda la cadena de sincronizacion.
		pipeline_pending			: out	std_logic		--! Se&ntilde;al para indicar si hay datos en el pipeline aritm&eacute;tico.	
	);
	end component;
	
	--! Nets para la salida de la cola de resultados y entrada del multiplexor del upload state machine.
	signal svx,svy,svz,ssc		: std_logic_vector(31 downto 0);
	
begin

	--!Zero agreggate
	zero	<= (others => '0');
	
	
--! *************************************************************************************************************************************************************************************************************************************************************
--! ARITHMETIC PIPELINE AND DATA PATH INSTANTIATION  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  => 
--! *************************************************************************************************************************************************************************************************************************************************************
	
	--! Arithpipeline and Datapath Control Instance
	arithmetic_pipeline_and_datapath_controller : ap_n_dpc
	port map (
		p0				=> sp0,
		p1				=> sp1,
		p2				=> sp2,
		p3				=> sp3,
		p4				=> sp4,
		p5				=> sp5,
		p6				=> sp6,
		p7				=> sp7,
		p8				=> sp8,
		
		clk 				=> clk,
		rst 				=> rst,
		ax					=> sreg_block(reg_ax),
		ay					=> sreg_block(reg_ay),
		az					=> sreg_block(reg_az),
		bx					=> sreg_block(reg_bx),
		by					=> sreg_block(reg_by),
		bz					=> sreg_block(reg_bz),
		vx					=> svx,
		vy					=> svy,
		vz					=> svz,
		sc					=> ssc,
		ack					=> sr_ack,
		empty				=> sr_e,
		dcs					=> sreg_block(reg_ctrl)(reg_ctrl_d downto reg_ctrl_s),
		sync_chain_1		=> ssync_chain_1,
		pipeline_pending	=> spipeline_pending
	);
	
	
--! ******************************************************************************************************************************************************						
--! TRANSFER CONTROL RTL CODE
--! ******************************************************************************************************************************************************						
	TRANSFER_CONTROL:
	process(clk,rst,master_waitrequest,sm,soutb_ae,soutb_usedw,spipeline_pending,soutb_e,zero,soutb_af,sfetch_data_pending,sreg_block,sslave_write,sslave_address,sslave_writedata,ssync_chain_pending,smaster_read,smaster_write,sdata_fetch_counter,sload_add_pending,swrite_pending,sdownload_chain)
	begin
		
		--! Conexi&oacuteln a se&ntilde;ales externas. 
		irq <= sreg_block(reg_ctrl)(reg_ctrl_irq);				
		master_read <= smaster_read;
		master_write <= smaster_write;
		
		--! Direct Memory Access Selector.
		
		
		
		--! ZERO_TRANSIT: Cuando todos los elementos de sincronizaci&oacute;n est&aacute;n en cero menos la cola de sincronizaci&oacute;n de carga de parametros.
		sZeroTransit <= not(sload_add_pending or sfetch_data_pending or spipeline_pending or swrite_pending);
		
		--! ELEMENTO DE SINCRONIZACION OUT QUEUE: Datos pendientes por cargar a la memoria a trav&eacute;s de la interconexi&oacute;n
		swrite_pending <= not(soutb_e);
		
		
		--! ELEMENTO DE SINCRONIZACION DESCARGA DE DATOS: Hay datos pendientes por descargar desde la memoria a trav&eacute;s de la interconexi&oacute;n.
		if sdata_fetch_counter=zero(reg_nfetch_high downto 0) then
			sfetch_data_pending <= '0';
		else
			sfetch_data_pending <= '1';
		end if;		 	
			
		--! ELEMENTO DE SINCRONIZACION CARGA DE DIRECCIONES: Hay direcciones pendientes por cargar a la interconexi&oacute;n?
		if sreg_block(reg_nfetch)(reg_nfetch_high downto 0)=zero(reg_nfetch_high downto 0) then
			sload_add_pending <= '0';
		else
			sload_add_pending <= '1';
		end if;		 	
		
		--! ELEMENTO DE SINCRONIZACION CARGA DE OPERANDOS: Se est&aacute;n cargando los operandos que ser&aacute;n operados en el pipeline aritm&eacute;tico.
		if sdownload_chain /= DWAX and sdownload_chain /= DWAXBX then
			sparamload_pending <= '1';
		else 
			sparamload_pending <= '0';
		end if;
			
		--! Se debe iniciar una transacci&oacute;n de descarga de datos desde la memoria externa?
		if soutb_af='0' and sload_add_pending='1' then
			--! Flow Control : La saturaci&oacute;n de la cola de resultados continuar&aacute; si no est&aacute; tan llena y adem&aacute;s hay pendientes datos por ser descargados.
			sflood_condition <= '1';
		else
			--! Flow Control : La saturaci&oacute;n de la cola de resultados debe parar porque est&aacute; cas&iacute; llena. 	
			sflood_condition <= '0';	 
		end if;	
		
		if sreg_block(reg_nfetch)(reg_nfetch_high downto mb)/=zero(reg_nfetch_high downto mb) then
			--! Flow Control: Si el n&uacute;mero de descargas pendientes es mayor o igual al max burst length, entonces cargar max burst en el contador.
			sflood_burstcount <= '1'&zero(mb-1 downto 0); 		
		else
			--! Flow Control: Si le n&uacute;mero de descargas pendientes es inferior a Max Burst Count entonces cargar los bits menos significativos del registro de descargas pendientes.
			sflood_burstcount <= '0'&sreg_block(reg_nfetch)(mb-1 downto 0);
		end if;	
		
		--! Se debe iniciar una transacci&oacute;n de carga de datos hacia la memoria externa?
		if soutb_ae='1' then
			--! Flow Control : Cuando se est&eacute; drenando la cola de resultados, si la cola est&aacute; cas&iacute; vac&iaute;a, la longitud del burst ser&aacute;n los bits menos significativos del contador de la cola.  
			sdrain_burstcount <= soutb_usedw(mb downto 0);
			--! Flow Control: El drenado de datos continuar&aacute; si el n&uacute;mero de datos en la cola bajo y no hay datos transitando por el pipeline, ni datos pendientes por cargar desde la memoria.   
			sdrain_condition <= not(sload_add_pending) and not(sfetch_data_pending) and not(spipeline_pending) and swrite_pending;
		else
			--! Flow Control: Cuando se est&eacute; drenando la cola de resultados, si la cola de tiene una cantidad de datos mayor al burst count entonces se har&aacute; una transacci&oacute;n de longitud equivalente al burst count.
			sdrain_burstcount <= '1'&zero(mb-1 downto 0);
			--! Flow Control: El drenado de datos continuar&aacute; si el n&uacute;mero de datos en la cola es mayor o igual a 2**mb O si hay muy pocos datos y no hay datos transitando por el pipeline.   
			sdrain_condition <= '1';
		end if;
		
		--! Data dumpster: Descaratar dato de upload una vez la interconexi&oacute;n haya enganchado el dato.
		if sm=SINK and master_waitrequest='0' and smaster_write='1' then 
			soutb_ack <= '1';
		else
			soutb_ack <= '0';
		end if;
		
		
		
		--! Flow Control State Machine.
		if rst=rstMasterValue then
			
			--! State Machine 
			sm <= IDLE;			
			
			
			--! Master Write & Read Common Signals Reset Value
			master_burstcount 	<= (others => '0'); 
			master_address		<= (others => '0');
			sdata_fetch_counter	<= (others => '0');
			sburstcount_sink	<= (others => '0');

			--! Master Read Only Signals Reset Value
			smaster_read 		<= '0';
			
			--! Master Write Only Signals
			smaster_write		<= '0';
			
			--! Reg Ctrl & Fetch address and writeaddress
			--! Sinking address
			sreg_block(reg_sinkstart) <= (others => '0');
			--! Sourcing address
			sreg_block(reg_fetchstart) <= (others => '0');
			--! Control and Status Register
			sreg_block(reg_ctrl) <= (others => '0');
			--! Contador Overall
			sreg_block(reg_inputcounter) <= (others => '0');
--			sreg_block(reg_timercounter) <= (others => '0');
			--! Address Fetch Counter 
			sreg_block(reg_nfetch) <= (others => '0');
			
			
		elsif clk'event and clk='1' then

			--! Nevermind the State, discount the incoming valid data counter.
			sdata_fetch_counter <= sdata_fetch_counter-master_readdatavalid;	
			
			--! Debug Counter.
			sreg_block(reg_inputcounter) <= sreg_block(reg_inputcounter) + master_readdatavalid;
			
			--!Timer Counter.
--			case sm is
--				when IDLE =>
--					sreg_block(reg_timercounter) <= sreg_block(reg_timercounter) + 0;
--				when others => 
--					sreg_block(reg_timercounter) <= sreg_block(reg_timercounter) + 1;
--			end case;				 

			--! Flags
			
						 
			case sm is
				when SOURCE => 
					--! ******************************************************************************************************************************************************						
					--! Flooding the pipeline ........
					--! ******************************************************************************************************************************************************						
					if smaster_read='0' then
						if sflood_condition = '1' then
							--! Flow Control: Hay suficiente espacio en el buffer de salida y hay descargas pendientes por hacer
							smaster_read <= '1';
							master_address <= sreg_block(reg_fetchstart);
							master_burstcount <= sflood_burstcount;
							sdata_fetch_counter <= sdata_fetch_counter+sflood_burstcount-master_readdatavalid;
							--! Context Saving:
							sreg_block(reg_fetchstart) <= sreg_block(reg_fetchstart) + (sflood_burstcount&"00");
							sreg_block(reg_nfetch)(reg_nfetch_high downto 0) <= sreg_block(reg_nfetch)(reg_nfetch_high downto 0) - sflood_burstcount;
						else
							--! Flow Control : Cambiar al estado SINK, porque o est&aacute; muy llena la cola de salida o no hay descargas pendientes por realizar.
							sm <= SINK;
						end if;
					else --master_read=1;
						if master_waitrequest='0' then
							--! Las direcciones de lectura est&aacute;n cargadas. Terminar la transferencia.
							smaster_read <= '0';
						end if;
					end if;
				when SINK => 
	
					--! ******************************************************************************************************************************************************						
					--! Draining the pipeline ........
					--! ******************************************************************************************************************************************************						
					if smaster_write='0' then 
						
						if sdrain_condition='1' then
							--! Flow Control : Hay muchos datos aun en la cola de resultados &Oacute; la cola de resultados est&aacute; cas&iacute; vac&iacute;a y no hay datos transitando en el pipeline aritm&eetico.
							smaster_write <= '1';
							master_address <= sreg_block(reg_sinkstart);
							master_burstcount <= sdrain_burstcount;							

							--!Context Saving
							sreg_block(reg_sinkstart) <= sreg_block(reg_sinkstart) + (sdrain_burstcount&"00");
							sburstcount_sink <= sdrain_burstcount-1;
						else 
							--! Flow Control: Son muy pocos los datos que hay en el buffer de salida y existen aun datos transitando en el resto del pipe ir al estado SOURCE.
							if sZeroTransit='1' then
									
								--! Flow Control: Finalizada la instrucci&oacute;n, generar una interrupci&oacute;n e ir al estado IDLE.
								sm <= IDLE;
								sreg_block(reg_ctrl)(reg_ctrl_irq) <= '1';
								sreg_block(reg_ctrl)(reg_ctrl_rom) <= '0';
								sreg_block(reg_ctrl)(reg_ctrl_flags_dc downto reg_ctrl_flags_fc) <= sdrain_condition & sflood_condition;
								sreg_block(reg_ctrl)(reg_ctrl_flags_ap downto reg_ctrl_flags_wp) <= sload_add_pending & sfetch_data_pending & sparamload_pending & spipeline_pending & swrite_pending;
							
							else
								
								--! Flow Control: Cambiar a Source porque aun hay elementos transitando.
								sm <= SOURCE;		
							end if;	
							
						end if;		
					else --!smaster_write=1 
						if master_waitrequest = '0' then
			
							--! Descartar datos : revisar antes de este proceso secuencial la parte combinatoria (Data Dumpster).


							if sburstcount_sink/=zero(mb downto 0) then

								--! Datos pendientes por transmitir aun en el burst. Restar uno 
								sburstcount_sink <= sburstcount_sink-1;
							else

								--! No escribir mas. Finalizar la transmisi&oacute;n
								smaster_write <= '0';
								
								--! Si no hay transito de dato se con terminada la instrucci&oacute;n siempre que el estado de control de flujo est&eacute; sidera  
								if sZeroTransit='1' then
									
									--! Flow Control: Finalizada la instrucci&oacute;n, generar una interrupci&oacute;n e ir al estado IDLE.
									sm <= IDLE;
									sreg_block(reg_ctrl)(reg_ctrl_irq) <= '1';
									sreg_block(reg_ctrl)(reg_ctrl_rom) <= '0';
									sreg_block(reg_ctrl)(reg_ctrl_flags_dc downto reg_ctrl_flags_fc) <= sdrain_condition & sflood_condition;
									sreg_block(reg_ctrl)(reg_ctrl_flags_ap downto reg_ctrl_flags_wp) <= sload_add_pending & sfetch_data_pending & sparamload_pending & spipeline_pending & swrite_pending;
										
								end if;	
							end if;
						end if;
					end if;
					
				when IDLE =>
					
					--! ******************************************************************************************************************************************************						
					--! Programming the pipeline
					--! ******************************************************************************************************************************************************						
					--! El registro de control en sus campos fetch e irq, es escribile solo cuando estamos en estado IDLE.		 
					if sslave_write='1' then 
						case sslave_address is 
							when x"0" =>
								--! Solo se permitira escribir en el registro de control si no hay una interrupci&oacute;n activa o si la hay solamente si se esta intentando desactivar la interrupci&acute;n 
								if sreg_block(reg_ctrl)(reg_ctrl_irq)='0' or sslave_writedata(reg_ctrl_irq)='0' then 
									sreg_block(reg_ctrl)<= sslave_writedata;
								end if;
							when x"5" => sreg_block(reg_nfetch) <= sslave_writedata;							
--							when x"6" => sreg_block(reg_timercounter) <= sslave_writedata; 
							when x"7" => sreg_block(reg_inputcounter) <= sslave_writedata;
							when x"8" => sreg_block(reg_fetchstart) <= sslave_writedata;
							when x"9" => sreg_block(reg_sinkstart) <= sslave_writedata;
							when others => null;
						end case;
					else
					
						if sZeroTransit='0' then
							
							
							--! Flow Control: Existe un n&uacute;mero de descargas programadas por el sistema, comenzar a realizarlas.
							--! Ir al estado Source.
							sm <= SOURCE;
							sreg_block(reg_ctrl)(reg_ctrl_rom) <= '1';
						else
							sreg_block(reg_ctrl)(reg_ctrl_rom) <= '0';
						
						end if;
					end if;
			end case;
		end if; 
	end process;
--! ******************************************************************************************************************************************************						
--! FLOW CONTROL RTL CODE
--! ******************************************************************************************************************************************************						
--! buffer de salida
--! ******************************************************************************************************************************************************						
	output_buffer:scfifo
	generic map (almost_empty_value => 2**mb,almost_full_value => (2**fd)-52, lpm_widthu => fd, lpm_numwords => 2**fd, lpm_showahead => "ON", lpm_width => 32, overflow_checking => "ON", underflow_checking => "ON", use_eab => "ON")
	port map 	(empty => soutb_e, aclr => '0', clock => clk, rdreq 	=> soutb_ack, wrreq	=> soutb_w,	q => master_writedata, usedw	=> soutb_usedw,	almost_full => soutb_af, almost_empty => soutb_ae, data => soutb_d);
--! ******************************************************************************************************************************************************						
--! PROCESO DE CONTROL DE FLUJO ENTRE EL BUFFER DE RESULTADOS Y EL BUFFER DE SALIDA
--! ******************************************************************************************************************************************************						

	FLOW_CONTROL_OUTPUT_STAGE:
	process (clk,rst,master_readdata, master_readdatavalid,sr_e,sreg_block(reg_ctrl)(reg_ctrl_vt downto reg_ctrl_sc),sm,supload_chain,zero,ssync_chain_pending,supload_start)
	begin
		

		--! Compute initial State.

		--! Escribir en el output buffer.
		if supload_chain=DMA then
			--! Modo DMA escribir los datos de entrada directamente en el buffer.
			soutb_w <= master_readdatavalid;
		else
			--!Modo Arithmetic Pipeline 
			soutb_w <= not(sr_e);
		end if;
		
		--! Control de lectura de la cola de resultados.
		if sr_e='0' then
			--!Hay datos en la cola de resultados.
			if (supload_chain=UPVZ and sreg_block(reg_ctrl)(reg_ctrl_sc)='0') or supload_chain=SC then
				--!Se transfiere el ultimo componente vectorial y no se estan cargando resultados escalares.
				sr_ack <= '1';
			else
				sr_ack <= '0';
			end if;
		else
			sr_ack <= '0';
		end if;
			
			
		--! Decodificar que salida de la cola de resultados se conecta a la entrada del otput buffer
		--! DMA Path Control: Si se encuentra habilitado el modo dma entonces conectar la entrada del buffer de salida a la interconexi&oacute;n
		case supload_chain is
			when UPVX => 
				soutb_d <= svx;
			when UPVY => 
				soutb_d <= svy;
			when UPVZ => 
				soutb_d <= svz;
			when SC => 
				soutb_d <= ssc;
			when DMA => 
				soutb_d <= master_readdata;
		end case;
					
	
		case sreg_block(reg_ctrl)(reg_ctrl_vt downto reg_ctrl_sc) is
			when "01" => 
				supload_start <= SC;
			when others => 
				supload_start <= UPVX;
		end case;
					
			
		--! M&aacute;quina de estados para el width adaptation RES(128) -> OUTPUTBUFFER(32). 	
		if rst=rstMasterValue then
			supload_chain <= UPVX;
		elsif clk'event and clk='1' and sreg_block(reg_ctrl)(reg_ctrl_dma)='0' then
			--! Modo de operaci&oacute;n normal.
			case supload_chain is
				when UPVX => 
					if sr_e='1' then 
						supload_chain <= supload_start;
					else
						supload_chain <= UPVY;
					end if;
				when UPVY =>
					supload_chain <= UPVZ;
				when UPVZ =>
					if sreg_block(reg_ctrl)(reg_ctrl_sc)='0' then 
						supload_chain <= UPVX;
					else
						supload_chain <= SC;
					end if;
				when SC|DMA => 
					supload_chain <= supload_start;
				
			end case;
		
		elsif clk'event and clk='1' then
			--! Modo DMA
			supload_chain <= DMA;
		end if;									
											
				
	end process;
--! ******************************************************************************************************************************************************						
--! PROCESO DE CONTROL DE FLUJO ENTRE LA ENTRADA DESDE LA INTERCONEXI&OACUTE;N Y LOS PARAMETROS DE ENTRADA EN EL PIPELINE ARITMETICO
--! ******************************************************************************************************************************************************						
	FLOW_CONTROL_INPUT_STAGE:
	process(clk,rst,master_readdatavalid,master_readdata,sreg_block(reg_ctrl)(reg_ctrl_dma downto reg_ctrl_s),sslave_write,sslave_address,supload_chain)
	begin
		--! Est&aacute; ocurriendo un evento de transici&oacute;n del estado TX al estado FETCH: Programar el enganche de par&aacute;metros que vienen de la interconexi&oacute;n.
		--! Mirar como es la carga inicial. Si es Normalizacion o Magnitud (dcs=110) entonces cargar DWAXBX de lo contrario solo DWAX.
		case sreg_block(reg_ctrl)(reg_ctrl_d downto reg_ctrl_s) is 
			when "110" 	=>	sdownload_start	<= DWAXBX; 
			when others	=>	sdownload_start	<= DWAX;
		end case;
		if rst=rstMasterValue then
			ssync_chain_1 <= '0';
			sdownload_chain <= DWAX;
			for i in reg_bz downto reg_ax loop
				sreg_block(i) <= (others => '0');
			end loop;
		elsif clk'event and clk='1' then
			ssync_chain_1	<= '0';
			if master_readdatavalid='1' and sreg_block(reg_ctrl)(reg_ctrl_dma)='0' and (sreg_block(reg_ctrl)(reg_ctrl_irq)='0' or sreg_block(reg_ctrl)(reg_ctrl_rlsc)='0') then 
				--! El dato en la interconexi&oacute;n es valido, se debe enganchar. 
				case sdownload_chain is 
					when DWAX | DWAXBX  =>
						--! Cargar el operando correspondiente al componente "X" del vector "A" 
						ssync_chain_1 <= '0';
						sreg_block(reg_ax) <= master_readdata;
						if sdownload_start = DWAXBX then
							--! Operaci&oacute;n Unaria por ejemplo magnitud de un vector
							--! Escribir en el registro bx adicionalmente. 
							sreg_block(reg_bx) <= master_readdata;
							--! El siguiente estado es cargar el componente "Y" de del operando a ejecutar.	
							sdownload_chain <= DWAYBY;
						else
							--! Operaci&oacute;n de dos operandos. Por ejemplo Producto Cruz.
							--! El siguiente estado es cargar el vector "Y" del operando "A".
							sdownload_chain <= DWAY;
						end if;
					when DWAY | DWAYBY =>
						sreg_block(reg_ay) <= master_readdata;
						ssync_chain_1 <= '0';
						if sdownload_chain = DWAYBY then
							sreg_block(reg_by) <= master_readdata;
							sdownload_chain <= DWAZBZ;
						else
							sdownload_chain <= DWAZ;
						end if;
					when DWAZ  | DWAZBZ => 
						sreg_block(reg_az) <= master_readdata;
						if sdownload_chain=DWAZBZ then
							ssync_chain_1 <= '1'; 
							sreg_block(reg_bz) <= master_readdata;
							sdownload_chain <= DWAXBX;
						else	
							ssync_chain_1 <= '0';
							sdownload_chain <= DWBX;
						end if;
					when DWBX  => 
						ssync_chain_1 <= '0';
						sreg_block(reg_bx) <= master_readdata;
						sdownload_chain <= DWBY;
					when DWBY => 
						ssync_chain_1 <= '0';
						sreg_block(reg_by) <= master_readdata;
						sdownload_chain <= DWBZ;
					when DWBZ => 
						sreg_block(reg_bz) <= master_readdata;
						ssync_chain_1 <= '1';
						if sreg_block(reg_ctrl)(reg_ctrl_cmb)='1' then 
							sdownload_chain <= DWBX;
						else
							sdownload_chain <= DWAX;
						end if;
					when others => 
						null;
				end case;
			--! Ok operation check if operation has ended.	If that's the case.
			elsif sreg_block(reg_ctrl)(reg_ctrl_irq)='1' and sreg_block(reg_ctrl)(reg_ctrl_rlsc)='1' then
				sdownload_chain <= sdownload_start;
			end if;
		end if;
	end process;
--! *************************************************************************************************************************************************************************************************************************************************************
--! AVALON MEMORY MAPPED MASTER FINISHED
--! *************************************************************************************************************************************************************************************************************************************************************
--! *************************************************************************************************************************************************************************************************************************************************************
--! AVALON MEMORY MAPPED SLAVE BEGINS =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>
--! *************************************************************************************************************************************************************************************************************************************************************
	--! Master Slave Process: Proceso para la escritura y lectura de registros desde el NIOS II.
	low_register_bank:
	process (clk,rst,sreg_block,soutb_w,supload_chain)
	begin
		if rst=rstMasterValue then
			for i in reg_scalar downto reg_vz loop
				sreg_block(i) <= (others => '0');
			end loop;
			sreg_block(reg_timercounter) <= (others => '0');
			slave_readdata <= (others => '0');
			sslave_address <= (others => '0');
			sslave_writedata <= (others => '0');
			sslave_write <= '0';
			sslave_read <= '0';
		elsif clk'event and clk='1' then
		
			
			sslave_address		<= slave_address;
			sslave_write		<= slave_write;
			sslave_read			<= slave_read; 
			sslave_writedata	<= slave_writedata;
			
			if sslave_write='1' and sslave_address=reg_timercounter then
				sreg_block(reg_timercounter) <= sslave_writedata;
			else
				sreg_block(reg_timercounter) <= sreg_block(reg_timercounter)+1;
			end if;				
			
			if sslave_write='1' and sslave_address=reg_scalar then
				sreg_block(reg_scalar) <= sslave_writedata;
			else
				sreg_block(reg_scalar) <= sreg_block(reg_scalar);
			end if;			
			
--			for i in reg_scalar downto reg_scalar loop
--				if sslave_address=i then
--					if sslave_write='1' then
--						sreg_block(i) <= sslave_writedata;
--					end if;
--				end if;
--			end loop;
			for i in 15 downto 0 loop
				if sslave_address=i then
					if sslave_read='1' then
					
						if (i<10 and i>3) or i=0 then
							slave_readdata <= sreg_block(i);
						elsif i=1 then 
							slave_readdata <= sp0;
						elsif i=2 then 
							slave_readdata <= sp1;
						elsif i=3 then
							slave_readdata <= sp2;
						elsif i=10 then
							slave_readdata <= sp3;
						elsif i=11 then
							slave_readdata <= sp4;
						elsif i=12 then
							slave_readdata <= sp5;
						elsif i=13 then
							slave_readdata <= sp6;
						elsif i=14 then
							slave_readdata <= sp7;
						elsif i=15 then
							slave_readdata <= sp8;
						end if;
							
					end if;
				end if;
			end loop;
		end if;
	end process;
	
--! *************************************************************************************************************************************************************************************************************************************************************
--! AVALON MEMORY MAPPED SLAVE FINISHED
--! *************************************************************************************************************************************************************************************************************************************************************
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! Control Register (reg_ctrl)	BASE_ADDRESS + 0x0																								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! Bit No.	| Nombre	| Descripci&oacute;n																								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! 0		| cmb (rw)	| 1:	La operaci&oacute;n es combinatoria, por lo tanto cargan los primeros 3 valores en el Operando A y el		|
	--!			|			|		de vectores en el operando B.																				|
	--!			|			| 0:	La operaci&oacute;n no es combinatoria, se cargan vectores en los operandos A y B.							|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--!			|			|		Configuraci&oacute;n del Datapath, Interconexi&oacute;n del Pipeline Aritm&eacute;tico y Cadena de Carga	|
	--!			|			|		Dependiendo del valor de estos 3 bits se configura la operaci&oacute;n a ejecutar.							|
	--!			|			|																													|
	--! [3:1]	| dcs (rw)	| 011:	Producto Cruz																								|
	--!			|			| 000:	Suma Vectorial																								|
	--!			|			| 001:	Resta Vectorial																								|
	--!			|			| 110:	Normalizaci&oacute;n Vectorial y c&aacute;lculo de Magnitud Vectorial										|
	--!			|			| 100:	Producto Punto																								|
	--!			|			| 111:	Producto Simple																								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! [5:4]	| vtsc (rw)	| 00:	Solo leer los resultados vectoriales.																		|
	--!			|			| 01:	Solo leer los resultados escalares.																			|
	--!			|			| 10:	Solo leer los resultados vectoriales.																		|
	--!			|			| 11:	Leer los resultados escalares y vectoriales.																|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 6		| dma (rw)	|  1:	Modo DMA: Los datos que ingresan se leen desde la direcci&oacute;n FETCHSTART (BASE+0x08) y se escriben en  |
	--!			|			|		la direcci&oacute;n SINKSTART (BASE+0x09).																	|
	--!			|			|  0:	Modo Arithmetic Pipeline: Los datos ingresan en grupos de a 6 valores para 2 vectores de 3 valores cada uno,|
	--!			|			|		cuando se usa en modo uno a uno (cmb=1), &oacute; en grupos de 3 valores para 1 vector de 3 valores, 		|
	--!			|			|		pero con el operando A fijado con el valor de la primera carga de valores en modo combinatorio (cmb=1).		|
	--!			|			|		De la misma manera que en modo DMA se cargan los operandos en la direcci&oacute;n FETCHSTART y se escriben	|
	--!			|			|		los resultados en la direcci&oacute;n SINKSTART.															|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 7		| flag_fc(r)|  1:	Al momento de generar una interrupci&oacute;n este bit se coloca en 1 si se cumplen las condiciones de  	|
	--!			|			|		descarga de datos de la memoria (revisar el net signal sflood_condition). Si se encuentra en uno se			|
	--!			|			|		tratar&iacute;a de una inconsistencia puesto que la interrupci&oacute;n se dispara una vez se ha terminado	|
	--! 		|			|		de ejecutar una instrucci&oacute;n y el que la bandera este en uno significa que hay transacciones de 		|	
	--!			|			|		descarga de datos desde la memoria pendientes.																|
	--!			|			|																													|
	--!			|			|		En general que cualquiera de estas banderas se coloque en uno es una se&ntilde;alizacion de error, puesto	|
	--!			|			|		que una vez se ha terminado de ejecutar una instrucci&oacute;n no deben haber transacciones pendientes.		|
	--!			|			|		La raz&oacute;n de ser de estas banderas es hacer depuraci&oacute;n del hardware mas que del software.		|
	--!			|			|																													|
	--!			|			|  0:	Flood Condition off. 																						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 8		| flag_dc(r)|  1:	Error, la instrucci&oacute;n ya se ejecut&oacute; y hay datos transitando en el buffer de salida aun.		|
	--!			|			|  0:	Drain Condition off.																						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 9		| wp(r)		|  1:	Error, la instrucci&oacute;n ya se ejecut&oacute; y hay datos transitando en el buffer de salida aun. 		|																							
	--!			|			|  0:	Write on Memory not pending.																				|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 10		| pp(r)		|  1:	Error, la instrucci&oacute;n ya se ejecut&oacute;n y hay datos transitando el pipeline aritm&eacute;tico.	|
	--!			|			|  0:	Pipeline not pending.																						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 11		| pl(r)		|  1:	La carga de parametros no se complet&oacute;. Esto por lo general pasa cuando uno va a realizar una			|
	--! 		|			|		operaci&acute;n combinatoria y solo cargo el primer operando, el A, esto puede ocurrir porque por ejemplo 	|
	--!			|			|		se puede desear sumar un conjunto de vectores a un vector de referencia. Este vector de referencia puede	|
	--!			|			|		estar en un area de memoria distinta, que el resto de los vectores. Por lo tanto el pseudo codigo para		|
	--!			|			|		ejecutar una operaci&oacute;n de este tipo seria:															|
	--!			|			|																													|	
	--!			|			|		ld vect,add,cmb;	//Resultados solo vectoriales, ejecutar operaci&oacute;n suma en modo combinatorio		|
	--!			|			|		ld &A;				//Cargar la direccion del Vector A.														|
	--!			|			|		ld 3;				//Cargar 3 valores, o sea el Vector A.													| 
	--!			|			|		wait int;			//Esperar a que se ejecute la interrupcion. Una vez se termine de ejecutar si la bandera|
	--!			|			|							//pl est&aacute; en uno se vuelve a comenzar y se deshecha el dato que hay como 		|
	--!			|			|							//par&aacute;metro.	Para este ejemplo se asume que est&aacute en uno					|
	--!			|			|		ld &B;				//Cargar la direcci&oacute;n donde se encuentran los vectores B							|
	--!			|			|		ld &C;				//Cargar la direcci&oacute;n donde se exribiran los resultados.							|
	--!			|			|		ld 24;				//Cargar los siguientes 24 valores a partir de &B correspondiente a 8 vectores			|
	--!			|			|							//ejecutando 8 sumas vectoriales que se escribir&iacute;n a apartir de &C				|
	--!			|			|		wait int;			//Esperar a que termine la ejecuci&oacute;n de las sumas.								|
	--!			|			|																													|
	--!			|			|  0:	Los operandos se cargaron integros se cargo del todo y no hubo que desechar parametros. 					|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 12		| dp (r)	|  1:	Error, la instrucci&oacute;n se termino y aun hay datos pendientes por ser descargados						|
	--!			|			|  0:	No hay datos pendientes por ser descargados.																|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 13		| ap (r)	|  1:	Carga de direcciones en la interconexi&oacute;n a&uacute;n est&aacute; pendiente y la instrucci&oacute; ya	|
	--!			|			|		se ejecut&oacute;																							|
	--!			|			|  0:	No hay direcciones pendientes por cargar.																	|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 14		| rlsc (rw)	| 1:	El sistema est&aacute; configurado para resetear la recarga sincronizada de par&aacute;metros una vez 	 	|
	--!			|			|		concluya la instrucci&oacute;n																				|
	--!			|			| 																													|
	--!			|			| 0:	El sistema est&aacute; configurado para no resetear la cadena de sincronizaci&oacute;n de carga.			|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 15		| rom (r)	| 1: Los registros solo se pueden leer no se pueden escribir. Etsado SINK y SOURCE									|
	--!			|			| 0: Los registros se pueden leer y escribir.																		|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! [30:16]	| nfetch(rw)| Cantidad de direcciones a cargar en la interconex&oacute;n para realizar la posterior descarga de datos de la  	|
	--!			|			| memoria al RayTrac.
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--!	31		| irq		| 1:	Evento de interrupci&oacute;n. El usuario debe hacer clear de este bit para dar la interrupci&o;n por		|
	--!			|			|		por atendida. Este bit se pone en uno cuando el sistema pasa de estado TX a FETCH o FETCH a TX.				|
	--!			|			| 																													|
	--!			|			| 0:	El RayTrac se encuentra en operaci&oacute;n Normal.															|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! Result Vector Z component (reg_vz)	BASE_ADDRESS + 0x4																					|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Result Vector Y component (reg_vy) BASE_ADDRESS + 0x8																					|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Result Vector X component (reg_vx) BASE_ADDRESS + 0xC																					|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Result Vector Scalar component (reg_scalar) BASE_ADDRESS + 0x10																			|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Scratch Vector 00	(reg_nfetch) BASE_ADDRESS + 	0x14																				|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! output Data Counter (reg_timercounter) BASE_ADDRESS + 0x18																				|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Input Data Counter	(reg_inputcounter) BASE_ADDRESS + 0x1C																				|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Data Fetch Start Address (reg_fetchstart) BASE_ADDRESS + 0x20																			|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Data Write Start Address (reg_sinkstart) BASE_ADDRESS + 0x24																			|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Parameter AX component (reg_ax) BASE_ADDRESS + 0x28																						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Parameter Ay component (reg_ay) BASE_ADDRESS + 0x2C																						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Parameter Az component (reg_az) BASE_ADDRESS + 0x30																						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Parameter Bx component (reg_bx) BASE_ADDRESS + 0x34																						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Parameter By component (reg_by) BASE_ADDRESS + 0x38																						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Parameter Bz component (reg_bz) BASE_ADDRESS + 0x3C																						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|	
	
	
	
	

	
end architecture;

