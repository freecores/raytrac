library ieee;
use ieee.std_logic_1664.all;
use work.arithpack.all;



entity rt_tb is
end entity;

architecture rt_tb_arch of rt_tb is

	signal	clk,rst,rd,wr	: std_logic;
	signal	add				: std_logic_vector(12 downto 0);
	signal	d,q				: std_logic_vector(31 downto 0);
	signal	int				: std_logic_vector(7 downto 0);

begin

	reset_p : process
	begin
		rst <= not(rstMasterValue);
		wait for 1 ns;
		rst <= rstMasterValue;
		wait for 52 ns;
		rst <= not(rstMasterValue);
	end process reset_p;
		

	clock_p : process
	begin
		clk <= '1';
		clock_loop:loop
			wait for tclk_2;
			clk <= '0';
			wait for tclk_2;
			clk <= '1';
		end loop clock_loop;
	end process clock_p;

	
	
	dude : raytrac
	port map (
		
		clk => clk,
		rst => rst,
		rd => rd,
		wr => wr,
		add => add,
		d => d,
		q => q,
		int => int
	
	);
	
	
	--! Este proceso c&aacute;lcula los rayos/vectores que desde un observador van a una pantalla de 16x16 pixeles.
	--! Posteriormente cada uno de estos rayos vectores es ingresado a la memoria del Raytrac. Son 256 rayos/vectores, que se escriben en los primeros 16 bloques vectoriales de los 32 que posee el bloque vectorial A.
	--! Finalmente se escribe en la cola de instrucciones la instrucci&oacute;n "nrm". 
	--! Para obtener m&aacute;s informaci&oacute;n sobre la interfase de programaci&oacute;n del Raytrac, refierase al libro en el cap&iacute;tulo M&aacute;quina de Estados e Interfase de Programaci&oacute;n.
	
	normalization_test_input : process (clk,rst)
		variable cam : apCamera;
		variable count : integer;
		variable v : v3f;
	begin
		if rst=rstMasterValue then
			count := 0;
			--! Camara observador.
			--! Resoluci&oacute;n horizontal
			cam.resx:=16; 
			--! Resoluci&oacute;n vertical
			cam.resy:=16;
			--! Dimensi&oacute;n horizontal
			cam.width:=100;
			--! Dimensi&oacute;n vertical
			cam.height:=100;
			--! Distancia del observador al plano de proyecci&oacute;n.
			cam.dist:=100;
			v(0):=(others => '0');
			v(1):=(others => '0');
			v(2):=(others => '0');
			d <= (others => '0');
			add <= (others => '0');
			wr <= '0';
		elsif clk='1' and clk'event then
			if count<256*3 then
				if count mod 3 = 0 then
					--! Calcular el vector que va desde el obsevador hasta un pixel x,y en particular.
					--! C&aacute;lculo de la columna:	0 <= c % 16 <= 15, 0 <= c <= 255. 
					--! C&aacute;lculo de la fila:		0 <= c / 16 <= 15, 0 <= c <= 255.	  
					v:=ap_slv_calc_xyvec((count/3) mod 16, (count/3)/16,cam);
				end if;
				--! Alistar componente vectorial para ser escrito.
				d <= v(count mod 3);
				--! Activar escritura
				wr <= '1';
				--! Direccionar en el bloque A comenzar 
				add <= "00"&conv_std_logic_vector(count mod 3,2)&'0'&conv_std_logic_vector(count/3,8);
				--! Avanzar
				count:=count+1;
			elsif count=256*3 then
				--! Escribir la instrucci&oacute;n de normalizaci&oacute;n.
				wr <= '1';
				--! La direcci&oacute;n por defecto para escribir en la cola de instrucciones es 0x0600
				-- add <= "0 0110 0000 0000";
				add <= x"0600";
				d <= ap_format_instruction("nrm",0,15,0,0,0);
				count:=count+1;
			else
				--! Parar la escritura de datos. 
				wr <= '0';	
			end if;
		end if;	
	end process normalization_test;

	disp: process
		file f : text open write_mode is "default_output.csv";
	begin
		ap_print(f,string'("#RAYTRAC TESTBENCH OUTPUT FILE"));
		ap_print(f,string'("#This file is automatically generated by tb_compiler script, by Julian Andres Guarin Reyes"));
		ap_print(f,string'("#TB_COMPILER_GEN"));
	end process


end architecture;

