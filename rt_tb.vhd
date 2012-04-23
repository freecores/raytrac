library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use work.arithpack.all;



entity rt_tb is
end entity;

architecture rt_tb_arch of rt_tb is

	--!TBXSTART:CTRL
	signal	sclk,srst,srd,swr	: std_logic;
	--!TBXEND
	--!TBXSTART:ADD_BUS
	signal	sadd				: std_logic_vector(12 downto 0);
	--!TBXEND
	--!TBXSTART:DATA_BUS
	signal	sd,sq				: xfloat32;
	--!TBXEND
	--!TXBXSTART:INT_BUS
	signal	sint				: std_logic_vector(7 downto 0);
	--!TBXEND
	
begin

	reset_p : process
	begin
		srst <= not(rstMasterValue);
		wait for 1 ns;
		srst <= rstMasterValue;
		wait for 52 ns;
		srst <= not(rstMasterValue);
		wait;
	end process reset_p;
		

	clock_p : process
	begin
		sclk <= '1';
		clock_loop:loop
			wait for tclk_2;
			sclk <= '0';
			wait for tclk_2;
			sclk <= '1';
		end loop clock_loop;
	end process clock_p;

	
	--!TBXINSTANCESTART
	dude : raytrac
	port map (
		
		clk => sclk,
		rst => srst,
		rd => srd,
		wr => swr,
		add => sadd,
		d => sd,
		q => sq,
		int => sint
	
	);
	--!TBXINSTANCEEND
	
	
	--! Este proceso c&aacute;lcula los rayos/vectores que desde un observador van a una pantalla de 16x16 pixeles.
	--! Posteriormente cada uno de estos rayos vectores es ingresado a la memoria del Raytrac. Son 256 rayos/vectores, que se escriben en los primeros 16 bloques vectoriales de los 32 que posee el bloque vectorial A.
	--! Finalmente se escribe en la cola de instrucciones la instrucci&oacute;n "nrm". 
	--! Para obtener m&aacute;s informaci&oacute;n sobre la interfase de programaci&oacute;n del Raytrac, refierase al libro en el cap&iacute;tulo M&aacute;quina de Estados e Interfase de Programaci&oacute;n.
	
	normalization_test_input : process (sclk,srst)
		variable cam : apCamera;
		variable count : integer;
		variable v : v3f;
		
	begin
		if srst=rstMasterValue then
			count := 0;
			--! Camara observador.
			--! Resoluci&oacute;n horizontal
			cam.resx:=16; 
			--! Resoluci&oacute;n vertical
			cam.resy:=16;
			--! Dimensi&oacute;n horizontal
			cam.width:=100.0;
			--! Dimensi&oacute;n vertical
			cam.height:=100.0;
			--! Distancia del observador al plano de proyecci&oacute;n.
			cam.dist:=100.0;
			v(0):=(others => '0');
			v(1):=(others => '0');
			v(2):=(others => '0');
			sd <= (others => '0');
			sadd <= (others => '0');
			swr <= '0';
		elsif sclk='1' and sclk'event then
			if count<256*3 then
				if count mod 3 = 0 then
					--! Calcular el vector que va desde el obsevador hasta un pixel x,y en particular.
					--! C&aacute;lculo de la columna:	0 <= c % 16 <= 15, 0 <= c <= 255. 
					--! C&aacute;lculo de la fila:		0 <= c / 16 <= 15, 0 <= c <= 255.	  
					v:=ap_slv_calc_xyvec((count/3) mod 16, (count/3)/16,cam);
				end if;
				--! Alistar componente vectorial para ser escrito.
				sd <= v(count mod 3);
				--! Activar escritura
				swr <= '1';
				--! Direccionar en el bloque A comenzar 
				sadd <= "00"&conv_std_logic_vector(count mod 3,2)&'0'&conv_std_logic_vector(count/3,8);
				--! Avanzar
				count:=count+1;
			elsif count=256*3 then
				--! Escribir la instrucci&oacute;n de normalizaci&oacute;n.
				swr <= '1';
				--! La direcci&oacute;n por defecto para escribir en la cola de instrucciones es 0x0600
				-- add <= "0 0110 0000 0000";
				sadd <= '0'&x"600";
				sd <= ap_format_instruction(string'("nrm"),"00000","01111","00000","00000",'0');
				count:=count+1;
			else
				--! Parar la escritura de datos. 
				swr <= '0';	
			end if;
		end if;	
	end process;


	--! tb_compiler: The following line (disp:process) is MANDATORY to be so tb_compiler knows here is where the display process takes place. 
	disp: process
		--! if a csv output file is NOT specefied then defaultoutput.csv is the name took as the default output file name, otherwise tb_compiler will change the following line to the proper user selected name. 
		file f : text open write_mode is "default_output.csv";
		variable l : line; 
	begin
		wait for 5 ns;
		--wait until srst=not(rstMasterValue);
		wait until sclk='1';
		wait for tclk_2+tclk_4;
		
		
		--! from here on, tb_compiler writes the data to be displayed
		--! tb_compiler: the following line MUST go here
		--!TBXDISPTOPLINE
		disp_loop:loop
			--! tb_compiler: the following line MUST go here
			--!TBXDISPLAYOPERATION
			wait for tclk;
			
		end loop;
		
			
	end process;


end architecture;

