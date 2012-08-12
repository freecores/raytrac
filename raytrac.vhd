library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

library lpm;
use lpm.lpm_components.all;


entity slave_template is 
	generic (
		wd	:	integer := 32;
		sl	:	integer := 5;	--! Arith Sync Chain Long 2**sl
		ln	:	integer := 12;	--! Max Transfer Length = 2**ln = n_outputbuffers * 256
		fd	:	integer := 8;	--! Result Fifo Depth = 2**fd =256
		mb	:	integer := 4;	--! Max Burst Length = 2**mb		
		nr	:	integer	:= 4	--! Number of Registers = 2**nr
	);
	port (
		clk:	in std_logic;
		rst:	in std_logic;
		
		--! Avalon MM Slave
		slave_address			:	in 	std_logic_vector(3 downto 0);
		slave_read				:	in 	std_logic;
		slave_write				:	in 	std_logic;
		slave_readdata			:	out std_logic_vector(31 downto 0);
		slave_writedata			:	in	std_logic_vector(31 downto 0);
	
		--! Avalon MM Master (Read & Write common signals)	
		master_address			:	out std_logic_vector(31 downto 0);
		master_burstcount		:	out std_logic_vector(4 downto 0);
		master_waitrequest		:	in	std_logic;
		
		--! Avalon MM Master (Read Stage)
		master_read				:	out	std_logic;
		master_readdata			:	in	std_logic_vector(31 downto 0);
		master_readdatavalid	:	in	std_logic;	

		--! Avalon MM Master (Write Stage)
		master_write			:	out	std_logic;
		master_writedata		:	out std_logic_vector(31 downto 0);
		
		--! Avalon IRQ
		irq						:	out std_logic
		
		
		
	);
end entity;


architecture slave_template_arch of slave_template is

	--! Altera Compiler Directive, to avoid m9k autoinferring thanks to the guys at http://www.alteraforum.com/forum/archive/index.php/t-30784.html .... 
	attribute altera_attribute : string; 
	attribute altera_attribute of slave_template_arch : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF";
	

	subtype	xfloat32		is std_logic_vector(wd-1 downto 0);
	type	registerblock	is array ((2**nr)-1 downto 0) of xfloat32;
	type	transferState	is (IDLE,SINK,SOURCE);
	
	constant rstMasterValue : std_logic :='0';
	
	
	constant reg_ctrl 				:	integer:=00;
	constant reg_vz					:	integer:=01;
	constant reg_vy					:	integer:=02;
	constant reg_vx					:	integer:=03;
	constant reg_scalar				:	integer:=04;
	constant reg_scratch00			:	integer:=05;
	constant reg_outputcounter		:	integer:=06;
	constant reg_inputcounter		:	integer:=07;
	constant reg_fetchstart			:	integer:=08;
	constant reg_sinkstart			:	integer:=09;
	constant reg_ax					:	integer:=10;
	constant reg_ay					:	integer:=11;
	constant reg_az					:	integer:=12;
	constant reg_bx					:	integer:=13;
	constant reg_by					:	integer:=14;
	constant reg_bz					:	integer:=15;


	
	constant reg_ctrl_cmb			:	integer:=00;	--! CMB bit : Combinatorial Instruction.
	constant reg_ctrl_s				:	integer:=01;	--! S bit of the DCS field.
	constant reg_ctrl_c				:	integer:=02;	--! C bit of the DCS field.
	constant reg_ctrl_d				:	integer:=03;	--! D bit of the DCS field.
	
	constant reg_ctrl_sc			:	integer:=04;	--! SC bit of the VTSC field.
	constant reg_ctrl_vt			:	integer:=05;	--! VT bit of the VTSC field.
	constant reg_ctrl_flags_ae		:	integer:=06;	--! Almost Empty Flag.
	constant reg_ctrl_flags_fc		:	integer:=07;	--! Flood Condition Flag.
	
	constant reg_ctrl_flags_dc		:	integer:=08;	--! Drain Condition Flag.	
	constant reg_ctrl_flags_wp		:	integer:=09;	--! Write on Memory Pending Flag.
	constant reg_ctrl_flags_pp		:	integer:=10;	--! Pipeline Pending Flag.
	constant reg_ctrl_flags_pl		:	integer:=11;	--! Load Parameter Pending Flag.
	
	constant reg_ctrl_flags_dp		:	integer:=12;	--! Data Pending flag.
	constant reg_ctrl_flags_ap		:	integer:=13;	--! Address Pending Flag.
	constant reg_ctrl_rlsc			:	integer:=14;	--! RLSC bit : Reload Load Sync Chain.
	constant reg_ctrl_rom			:	integer:=15;	--! ROM bit : Read Only Mode bit.
	
	constant reg_ctrl_nfetch_low	:	integer:=16;	--! NFETCH_LOW : Lower bit to program the number of addresses to load in the interconnection.
	constant reg_ctrl_nfetch_high	:	integer:=30;	--! NFETCH_HIGH : Higher bit to program the number of addresses to load in the interconnection. 
	constant reg_ctrl_irq			:	integer:=31;	--! IRQ bit : Interrupt Request Signal.
			
		
	--! Avalon MM Slave
	signal	sreg_block			:	registerblock;
	signal	sslave_read			:	std_logic;
	signal	sslave_write		:	std_logic;
	signal	sslave_writedata	:	xfloat32;
	signal	sslave_address		:	std_logic_vector	(nr-1 downto 0);
	signal	sslave_waitrequest	:	std_logic;
	--! Avalon MM Master
	signal	smaster_write		:	std_logic;
	signal	smaster_read		:	std_logic;
	
	
	--! State Machine and event signaling
	signal sm					:	transferState;
	
	signal sres_ack				:	std_logic;
	signal soutb_ack			:	std_logic;
	
	signal sres_q				:	std_logic_vector(4*wd-1 downto 0);
	
	signal sres_d				:	std_logic_vector(4*wd-1 downto 0);
	signal soutb_d				:	std_logic_vector(wd-1 downto 0);
	
	
	signal sres_w				:	std_logic;
	signal soutb_w				:	std_logic;
	
	signal sres_e				:	std_logic;
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
	type upload_chain is (VX,VY,VZ,SC);
	signal supload_chain	: upload_chain;
	signal supload_start	: upload_chain;
		
	--!Se&ntilde;ales de apoyo:
	signal zero : std_logic_vector(31 downto 0);
	
	--!High Register Bank Control Signals or AKA Load Sync Chain Control
	type download_chain is (AX,AY,AZ,BX,BY,BZ,AXBX,AYBY,AZBZ);
	signal sdownload_chain	: download_chain;
	signal sdownload_start	: download_chain; 
	signal srestart_chain	: std_logic;
	--!State Machine Hysteresis Control Signals
	signal sdrain_condition 	: std_logic;
	signal sdrain_burstcount	: std_logic_vector(mb downto 0);
	signal sdata_fetch_counter	: std_logic_vector(reg_ctrl_nfetch_high downto reg_ctrl_nfetch_low);
	signal sburstcount_sink		: std_logic_vector(mb downto 0);
	
	signal sflood_condition 	: std_logic;
	signal sflood_burstcount 	: std_logic_vector(mb downto 0);

	
begin

	--! Unos y ceros
	zero	<= (others => '0');
	
	--! Salidas no asignadas
	
	--! Mientras tanto
	ssync_chain_pending <= ssync_chain_1;
	sres_d ((wd*1)-1 downto wd*0)<= sreg_block(reg_bz) ;
	sres_d ((wd*2)-1 downto wd*1)<= sreg_block(reg_by) ;
	sres_d ((wd*3)-1 downto wd*2)<= sreg_block(reg_bx) ;
	sres_d ((wd*4)-1 downto wd*3)<= sreg_block(reg_ax) ;
	sres_w <= ssync_chain_1;  
	
	
	
--! *************************************************************************************************************************************************************************************************************************************************************
--! AVALON MEMORY MAPPED MASTER INTERFACE BEGIN  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  =>  => 
--! *************************************************************************************************************************************************************************************************************************************************************
--! ******************************************************************************************************************************************************						
--! TRANSFER CONTROL RTL CODE
--! ******************************************************************************************************************************************************						
	TRANSFER_CONTROL:
	process(clk,rst,master_waitrequest,soutb_ae,soutb_usedw,spipeline_pending,soutb_e,zero,soutb_af,sfetch_data_pending,sreg_block,sslave_write,sslave_address,sslave_writedata,ssync_chain_pending,sres_e,smaster_read,smaster_write,sdata_fetch_counter,sload_add_pending,swrite_pending,sdownload_chain)
	begin
		
		--! Conexi&oacuteln a se&ntilde;ales externas. 
		irq <= sreg_block(reg_ctrl)(reg_ctrl_irq);				
		master_read <= smaster_read;
		master_write <= smaster_write;
		
		
		--! ZERO_TRANSIT: Cuando todos los elementos de sincronizaci&oacute;n est&aacute;n en cero menos la cola de sincronizaci&oacute;n de carga de parametros.
		sZeroTransit <= not(sload_add_pending or sfetch_data_pending or spipeline_pending or swrite_pending);
		
		--! ELEMENTO DE SINCRONIZACION OUT QUEUE: Datos pendientes por cargar a la memoria a trav&eacute;s de la interconexi&oacute;n
		swrite_pending <= not(soutb_e);
		
		--! ELEMENTO DE SINCRONIZACION ARITH PIPELINE: Hay datos transitando por el pipeline aritm&eacute;tico.
		if ssync_chain_pending='1' or sres_e='0' then
			spipeline_pending <= '1';
		else
			spipeline_pending <= '0';
		end if;		 	
		
		--! ELEMENTO DE SINCRONIZACION DESCARGA DE DATOS: Hay datos pendientes por descargar desde la memoria a trav&eacute;s de la interconexi&oacute;n.
		if sdata_fetch_counter=zero(reg_ctrl_nfetch_high downto reg_ctrl_nfetch_low) then
			sfetch_data_pending <= '0';
		else
			sfetch_data_pending <= '1';
		end if;		 	
			
		--! ELEMENTO DE SINCRONIZACION CARGA DE DIRECCIONES: Hay direcciones pendientes por cargar a la interconexi&oacute;n?
		if sreg_block(reg_ctrl)(reg_ctrl_nfetch_high downto reg_ctrl_nfetch_low)=zero(reg_ctrl_nfetch_high downto reg_ctrl_nfetch_low) then
			sload_add_pending <= '0';
		else
			sload_add_pending <= '1';
		end if;		 	
		
		--! ELEMENTO DE SINCRONIZACION CARGA DE OPERANDOS: Se est&aacute;n cargando los operandos que ser&aacute;n operados en el pipeline aritm&eacute;tico.
		if sdownload_chain /= AX and sdownload_chain /= AXBX then
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
		if sreg_block(reg_ctrl)(reg_ctrl_nfetch_high downto reg_ctrl_nfetch_low+mb)/=zero(reg_ctrl_nfetch_high downto reg_ctrl_nfetch_low+mb) then
			--! Flow Control: Si el n&uacute;mero de descargas pendientes es mayor o igual al max burst length, entonces cargar max burst en el contador.
			sflood_burstcount <= '1'&zero(mb-1 downto 0); 		
		else
			--! Flow Control: Si le n&uacute;mero de descargas pendientes es inferior a Max Burst Count entonces cargar los bits menos significativos del registro de descargas pendientes.
			sflood_burstcount <= '0'&sreg_block(reg_ctrl)(reg_ctrl_nfetch_low+mb-1 downto reg_ctrl_nfetch_low);
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
		
		--! Restart param load chain
		srestart_chain <= sreg_block(reg_ctrl)(reg_ctrl_irq) and sreg_block(reg_ctrl)(reg_ctrl_rlsc);
		
		--! Data dumpster: Dump data once the interconeection has loaded the data to write.
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
			sreg_block(reg_outputcounter) <= (others => '0');
			
			
		elsif clk'event and clk='1' then

			--! Nevermind the State, discount the incoming valid data counter.
			sdata_fetch_counter <= sdata_fetch_counter-master_readdatavalid;	
			
			--! Debug Counter.
			sreg_block(reg_inputcounter) <= sreg_block(reg_inputcounter) + master_readdatavalid;
			sreg_block(reg_outputcounter) <= sreg_block(reg_outputcounter) + soutb_ack;

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
							sreg_block(reg_ctrl)(reg_ctrl_nfetch_high downto reg_ctrl_nfetch_low) <= sreg_block(reg_ctrl)(reg_ctrl_nfetch_high downto reg_ctrl_nfetch_low) - sflood_burstcount;
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
								sreg_block(reg_ctrl)(reg_ctrl_flags_dc downto reg_ctrl_flags_ae) <= sdrain_condition & sflood_condition & soutb_ae;
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
									sreg_block(reg_ctrl)(reg_ctrl_flags_dc downto reg_ctrl_flags_ae) <= sdrain_condition & sflood_condition & soutb_ae;
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
									sreg_block(reg_ctrl)(reg_ctrl_irq downto reg_ctrl_nfetch_low) <= sslave_writedata(reg_ctrl_irq downto reg_ctrl_nfetch_low);
									sreg_block(reg_ctrl)(reg_ctrl_flags_wp-1 downto reg_ctrl_cmb) <= sslave_writedata(reg_ctrl_flags_wp-1 downto reg_ctrl_cmb);
								end if;
							when x"6" => sreg_block(reg_outputcounter) <= sslave_writedata; 
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

						end if;
					end if;
				when others => 
					null;					
			end case;
		end if; 
	end process;
--! ******************************************************************************************************************************************************						
--! FLOW CONTROL RTL CODE
--! ******************************************************************************************************************************************************						
--! Colas de resultados y buffer de salida
--! ******************************************************************************************************************************************************						
	res:scfifo
	generic map	(lpm_numwords => 2**fd, lpm_showahead => "ON", lpm_width => 128, lpm_widthu	=> fd, overflow_checking => "ON", underflow_checking => "ON", use_eab => "ON")
	port map 	(rdreq => sres_ack, aclr => '0', empty => sres_e, clock => clk, q => sres_q,	wrreq => sres_w, data => sres_d);
	output_buffer:scfifo
	generic map (almost_empty_value => 2**mb,almost_full_value => (2**fd)-52, lpm_widthu => fd, lpm_numwords => 2**fd, lpm_showahead => "ON", lpm_width => 32, overflow_checking => "ON", underflow_checking => "ON", use_eab => "ON")
	port map 	(empty => soutb_e, aclr => '0', clock => clk, rdreq 	=> soutb_ack, wrreq	=> soutb_w,	q => master_writedata, usedw	=> soutb_usedw,	almost_full => soutb_af, almost_empty => soutb_ae, data => soutb_d);
--! ******************************************************************************************************************************************************						
--! PROCESO DE CONTROL DE FLUJO ENTRE EL BUFFER DE RESULTADOS Y EL BUFFER DE SALIDA
--! ******************************************************************************************************************************************************						

	FLOW_CONTROL_OUTPUT_STAGE:
	process (clk,rst,sres_e,sreg_block(reg_ctrl)(reg_ctrl_vt downto reg_ctrl_sc),sm,supload_chain,zero,ssync_chain_pending,sres_q,supload_start)
	begin
		

		--! Compute initial State.

		--! Escribir en el output buffer.
		soutb_w <= not(sres_e);
		
		--! Control de lectura de la cola de resultados.
		if sres_e='0' then
			--!Hay datos en la cola de resultados.
			if (supload_chain=VZ and sreg_block(reg_ctrl)(reg_ctrl_sc)='0') or supload_chain=SC then
				--!Se transfiere el ultimo componente vectorial y no se estan cargando resultados escalares.
				sres_ack <= '1';
			end if;
		else
			sres_ack <= '0';
		end if;
			
		--! Decodificar que salida de la cola de resultados se conecta a la entrada del otput buffer
		case supload_chain is
			when VX => 
				soutb_d <= sres_q ((wd*1)-1 downto wd*0);
			when VY => 
				soutb_d <= sres_q ((wd*2)-1 downto wd*1);
			when VZ => 
				soutb_d <= sres_q ((wd*3)-1 downto wd*2);
			when SC => 
				soutb_d <= sres_q ((wd*4)-1 downto wd*3);
		end case;
					
	
		case sreg_block(reg_ctrl)(reg_ctrl_vt downto reg_ctrl_sc) is
			when "01" => 
				supload_start <= SC;
			when others => 
				supload_start <= VX;
		end case;
					
			
		--! M&aacute;quina de estados para el width adaptation RES(128) -> OUTPUTBUFFER(32). 	
		if rst=rstMasterValue then
			supload_chain <= VX;
		elsif clk'event and clk='1' then
			case supload_chain is
				when VX => 
					if sres_e='1' then 
						supload_chain <= supload_start;
					else
						supload_chain <= VY;
					end if;
				when VY =>
					supload_chain <= VZ;
				when VZ =>
					if sreg_block(reg_ctrl)(reg_ctrl_sc)='0' then 
						supload_chain <= VX;
					else
						supload_chain <= SC;
					end if;
				when SC => 
					supload_chain <= supload_start;
			end case;
		end if;									
											
				
	end process;
--! ******************************************************************************************************************************************************						
--! PROCESO DE CONTROL DE FLUJO ENTRE LA ENTRADA DESDE LA INTERCONEXI&OACUTE;N Y LOS PARAMETROS DE ENTRADA EN EL PIPELINE ARITMETICO
--! ******************************************************************************************************************************************************						
	FLOW_CONTROL_INPUT_STAGE:
	process(clk,rst,master_readdatavalid,master_readdata,sreg_block(reg_ctrl)(reg_ctrl_d downto reg_ctrl_s),sslave_write,sslave_address)
	begin
		--! Est&aacute; ocurriendo un evento de transici&oacute;n del estado TX al estado FETCH: Programar el enganche de par&aacute;metros que vienen de la interconexi&oacute;n.
		--! Mirar como es la carga inicial. Si es Normalizacion o Magnitud (dcs=110) entonces cargar AXBX de lo contrario solo AX.
		case sreg_block(reg_ctrl)(reg_ctrl_d downto reg_ctrl_s) is 
			when "110" | "100"	=>	sdownload_start	<= AXBX; 
			when others			=>	sdownload_start	<= AX;
		end case;
		if rst=rstMasterValue then
			ssync_chain_1 <= '0';
			sdownload_chain <= AX;
			for i in reg_bz downto reg_ax loop
				sreg_block(i) <= (others => '0');
			end loop;
		elsif clk'event and clk='1' then
			ssync_chain_1	<= '0';
			if master_readdatavalid='1' then 
				--! El dato en la interconexi&oacute;n es valido, se debe enganchar. 
				case sdownload_chain is 
					when AX | AXBX  =>
						--! Cargar el operando correspondiente al componente "X" del vector "A" 
						ssync_chain_1 <= '0';
						sreg_block(reg_ax) <= master_readdata;
						if sdownload_start = AXBX then
							--! Operaci&oacute;n Unaria por ejemplo magnitud de un vector
							--! Escribir en el registro bx adicionalmente. 
							sreg_block(reg_bx) <= master_readdata;
							--! El siguiente estado es cargar el componente "Y" de del operando a ejecutar.	
							sdownload_chain <= AYBY;
						else
							--! Operaci&oacute;n de dos operandos. Por ejemplo Producto Cruz.
							--! El siguiente estado es cargar el vector "Y" del operando "A".
							sdownload_chain <= AY;
						end if;
					when AY | AYBY =>
						sreg_block(reg_ay) <= master_readdata;
						ssync_chain_1 <= '0';
						if sdownload_chain = AYBY then
							sreg_block(reg_by) <= master_readdata;
							sdownload_chain <= AZBZ;
						else
							sdownload_chain <= AZ;
						end if;
					when AZ  | AZBZ => 
						sreg_block(reg_az) <= master_readdata;
						if sdownload_chain=AZBZ then
							ssync_chain_1 <= '1'; 
							sreg_block(reg_bz) <= master_readdata;
							sdownload_chain <= AXBX;
						else	
							ssync_chain_1 <= '0';
							sdownload_chain <= BX;
						end if;
					when BX  => 
						ssync_chain_1 <= '0';
						sreg_block(reg_bx) <= master_readdata;
						sdownload_chain <= BY;
					when BY => 
						ssync_chain_1 <= '0';
						sreg_block(reg_by) <= master_readdata;
						sdownload_chain <= BZ;
					when BZ => 
						sreg_block(reg_bz) <= master_readdata;
						ssync_chain_1 <= '1';
						if sreg_block(reg_ctrl)(reg_ctrl_cmb)='1' then 
							sdownload_chain <= BX;
						else
							sdownload_chain <= AX;
						end if;
					when others => 
						null;
				end case;
				
				if srestart_chain='1' then
					sdownload_chain <= sdownload_start;
				end if;				
				
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
	process (clk,rst,sreg_block)
	begin
		if rst=rstMasterValue then
			for i in reg_scratch00 downto reg_vz loop
				sreg_block(i) <= (others => '0');
			end loop;

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
			for i in reg_scratch00 downto reg_vz loop
				if sslave_address=i then
					if sslave_write='1' then
						sreg_block(i) <= sslave_writedata;
					end if;
				end if;
			end loop;
			for i in 15 downto 0 loop
				if sslave_address=i then
					if sslave_read='1' then
						slave_readdata <= sreg_block(i);
					end if;
				end if;
			end loop;
		end if;
	end process;
--! *************************************************************************************************************************************************************************************************************************************************************
--! AVALON MEMORY MAPPED SLAVE FINISHED
--! *************************************************************************************************************************************************************************************************************************************************************
	
	
	
	
	

	
end architecture;

	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! Control Register (cr)	BASE_ADDRESS + 0x0																								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! Bit No.	| Nombre	| Descripci&oacute;n																								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------
	--! 0		| cmb (rw)	| 1:	La operaci&oacute;n es combinatoria, por lo tanto solo se cargan vectores en el operando B.					|
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
	--!			|			| En el caso de que dcs sea 110 (Normalizaci&oacute;n y Magnitud Vectorial) este par de bits indica que resultados	|
	--!			|			| escribir. Si dcs tiene un valor diferente a 110 se ignora este campo.												|
	--!			|			|																													|
	--! [5:4]	| vtsc (rw)	| 00:	Solo leer los resultados vectoriales.																		|
	--!			|			| 01:	Solo leer los resultados escalares.																			|
	--!			|			| 10:	Solo leer los resultados vectoriales.																		|
	--!			|			| 11:	Leer los resultados escalares y vectoriales.																|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 14		| rlsc (rw)	| 1:	El sistema est&aacute; configurado para resetear la recarga sincronizada de par&aacute;metros una vez 	 	|
	--!			|			|		concluya la instrucci&oacute;n																				|
	--!			|			| 																													|
	--!			|			| 0:	El sistema est&aacute; configurado para no resetear la cadena de sincronizaci&oacute;n de carga.																									|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! 15		| rom (r)	| 1: Los registros solo se pueden leer no se pueden escribir.														|
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
	--! Start Parameter Address (psadd)	BASE_ADDRESS + 0x4																						|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! [31:0]	| sadd (rw) | Direcci&oacute;n de memoria donde se encuentra el primer par&aacute;metro de entrada.								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Start Result Address (rsadd) BASE_ADDRESS + 0x8																							|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! [31:0]	| rsadd (rw)| Direcci&oacute;n de memoria donde se encuentra el primer par&aacute;metro de entrada.								|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! Scratch Register (screg) BASE_ADDRESS + 0x1C																							|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
	--! [31:0]	| screg (rw)| Direcci&oacute;n de memoria donde se pueden escribir y leer valores de 32 bits.									|
	--!---------|-----------|-------------------------------------------------------------------------------------------------------------------|
