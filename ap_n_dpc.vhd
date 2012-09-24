--! @file ap_n_dpc.vhd
--! @brief Decodificador de operaci&eacute;n. Sistema de decodificación de los \kdatapaths, cuyo objetivo es a partir del par&acute;ametro de entrada DCS.\nSon 4 las posibles configuraciones de \kdatapaths que existen. Los valores de los bits DC son los que determinan y decodifican la interconexi&oacute;n entre los componentes aritm&eacute;ticos. El componente S determina el signo de la operaci&oacute;n cuando es una suma la que operaci&oacute;n se es&eacutea; ejecutando en el momento.  
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------------------
-- RAYTRAC
-- Author Julian Andres Guarin
-- ap_n_dpc.vhd
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


entity ap_n_dpc is 
	
	port (
		
		p0,p1,p2,p3,p4,p5,p6,p7,p8: out std_logic_vector(31 downto 0);
		
		
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
		
		 --paraminput				: in	vectorblock06;	--! Vectores A,B
		
		dcs						: in	std_logic_vector(2 downto 0);		--! Bit con el identificador del bloque AB vs CD e identificador del sub bloque (A/B) o (C/D). 
		
		sync_chain_1			: in	std_logic;		--! Se&ntilde;al de dato valido que se va por toda la cadena de sincronizacion.
		pipeline_pending		: out	std_logic		--! Se&ntilde;al para indicar si hay datos en el pipeline aritm&eacute;tico.	
		
		
		
		--qresult_d				: out	vectorblock04 	--! 4 salidas de resultados, pues lo m&aacute;ximo que podr&aacute; calcularse por cada clock son 2 vectores. 
	


	);
end entity;

architecture ap_n_dpc_arch of ap_n_dpc is 
	--!Constantes de apoyo
	constant ssync_chain_max : integer :=32;
	constant ssync_chain_min : integer :=2;
	
	--! Tunnning delay
	constant adder2_delay: integer := 1; 
	constant adder1_delay : integer := 1;
	
	--!TBXSTART:FACTORS_N_ADDENDS
	signal sfactor0	: std_logic_vector(31 downto 0);
	signal sfactor1	: std_logic_vector(31 downto 0);
	signal sfactor2	: std_logic_vector(31 downto 0);
	signal sfactor3	: std_logic_vector(31 downto 0);
	signal sfactor4	: std_logic_vector(31 downto 0);
	signal sfactor5	: std_logic_vector(31 downto 0);
	signal sfactor6	: std_logic_vector(31 downto 0);
	signal sfactor7	: std_logic_vector(31 downto 0);
	signal sfactor8	: std_logic_vector(31 downto 0);
	signal sfactor9	: std_logic_vector(31 downto 0);
	signal sfactor10	: std_logic_vector(31 downto 0);
	signal sfactor11	: std_logic_vector(31 downto 0);
	--signal sfactor		: vectorblock12;
	
	signal ssumando0	: std_logic_vector(31 downto 0);
	signal ssumando1	: std_logic_vector(31 downto 0);
	signal ssumando2	: std_logic_vector(31 downto 0);
	signal ssumando3	: std_logic_vector(31 downto 0);
	signal ssumando4	: std_logic_vector(31 downto 0);
	signal ssumando5	: std_logic_vector(31 downto 0);
	--signal ssumando		: vectorblock06;
	
	signal sq0_q		: std_logic_vector(31 downto 0);
	--!TBXEND
	
	
	--!TBXSTART:ARITHMETIC_RESULTS

	signal sp0			: std_logic_vector(31 downto 0);
	signal sp1			: std_logic_vector(31 downto 0);
	signal sp2			: std_logic_vector(31 downto 0);
	signal sp3			: std_logic_vector(31 downto 0);
	signal sp4			: std_logic_vector(31 downto 0);
	signal sp5			: std_logic_vector(31 downto 0);
	--signal sprd32blk	: vectorblock06;
	
	signal sa0			: std_logic_vector(31 downto 0);
	signal sa1			: std_logic_vector(31 downto 0);
	signal sa2			: std_logic_vector(31 downto 0);
	
	--signal sadd32blk	: vectorblock03;
	
	signal ssq32	: std_logic_vector(31 downto 0);
	signal sinv32	: std_logic_vector(31 downto 0);
	
	signal sqx_q		: std_logic_vector(31 downto 0);
	signal sqy_q		: std_logic_vector(31 downto 0);
	signal sqz_q		: std_logic_vector(31 downto 0);
	--signal sqxyz_q		: vectorblock03;
	
	signal sq1_e		: std_logic;
	--!TBXEND
	
	
	--!TBXSTART:SYNC_CHAIN
	signal ssync_chain	: std_logic_vector(ssync_chain_max downto ssync_chain_min);
	--!TBXEND

	--signal qxyzd		: std_logic_vector(95 downto 0);
	
	--signal qxyzq		: std_logic_vector(95 downto 0);
	
	signal sq2_d		: std_logic_vector(31 downto 0);
	signal sq2_q		: std_logic_vector(31 downto 0);
	signal sq2_w		: std_logic;
	signal sq2_e		: std_logic;

	signal sqr_e		: std_logic;
	signal sqr_w		: std_logic;		--! Salidas de escritura y lectura en las colas de resultados.
	signal sqr_dx		: std_logic_vector(31 downto 0);
	signal sqr_dy		: std_logic_vector(31 downto 0);
	signal sqr_dz		: std_logic_vector(31 downto 0);
	signal sqr_dsc		: std_logic_vector(31 downto 0);
	


	signal sa0o			: std_logic_vector(31 downto 0);
	signal sa1o			: std_logic_vector(31 downto 0);
	signal sa2o			: std_logic_vector(31 downto 0);
	--signal sadd32blko 	: vectorblock03;	--! Salidas de los 3 sumadores.
	
	signal sp0o			: std_logic_vector(31 downto 0);
	signal sp1o			: std_logic_vector(31 downto 0);
	signal sp2o			: std_logic_vector(31 downto 0);
	signal sp3o			: std_logic_vector(31 downto 0);
	signal sp4o			: std_logic_vector(31 downto 0);
	signal sp5o			: std_logic_vector(31 downto 0);
	--signal sprd32blko	: vectorblock06;	--! Salidas de los 6 multiplicadores.
	
	signal sinv32o	: std_logic_vector(31 downto 0);		--! Salidas de la raiz cuadradas y el inversor.
	signal ssq32o	: std_logic_vector(31 downto 0);		--! Salidas de la raiz cuadradas y el inversor.
	
	--! Bloque Aritmetico de Sumadores y Multiplicadores (madd)
	component arithblock
	port (
		
		clk	: in std_logic;
		rst : in std_logic;
	
		sign 		: in std_logic;
		
		factor0		: in std_logic_vector(31 downto 0);
		factor1		: in std_logic_vector(31 downto 0);
		factor2		: in std_logic_vector(31 downto 0);
		factor3		: in std_logic_vector(31 downto 0);
		factor4		: in std_logic_vector(31 downto 0);
		factor5		: in std_logic_vector(31 downto 0);
		factor6		: in std_logic_vector(31 downto 0);
		factor7		: in std_logic_vector(31 downto 0);
		factor8		: in std_logic_vector(31 downto 0);
		factor9		: in std_logic_vector(31 downto 0);
		factor10	: in std_logic_vector(31 downto 0);
		factor11	: in std_logic_vector(31 downto 0);
		--prd32blki	: in vectorblock06;
	
		sumando0	: in std_logic_vector(31 downto 0);
		sumando1	: in std_logic_vector(31 downto 0);
		sumando2	: in std_logic_vector(31 downto 0);
		sumando3	: in std_logic_vector(31 downto 0);
		sumando4	: in std_logic_vector(31 downto 0);
		sumando5	: in std_logic_vector(31 downto 0);
		--add32blki	: in vectorblock06;
		
		a0			: out std_logic_vector(31 downto 0);
		a1			: out std_logic_vector(31 downto 0);
		a2			: out std_logic_vector(31 downto 0);
		--add32blko	: out vectorblock03;
		
		p0			: out std_logic_vector(31 downto 0);
		p1			: out std_logic_vector(31 downto 0);
		p2			: out std_logic_vector(31 downto 0);
		p3			: out std_logic_vector(31 downto 0);
		p4			: out std_logic_vector(31 downto 0);
		p5			: out std_logic_vector(31 downto 0);
		--prd32blko	: out vectorblock06;
		
		sq32o		: out std_logic_vector(31 downto 0);
		inv32o		: out std_logic_vector(31 downto 0)
			
	);
	end component;
	
begin

	--! Bloque Aritm&eacute;tico
	ap : arithblock
	port map (
		clk 		=> clk,
		rst	 		=> rst,
		
		sign 		=> dcs(0),
		
		factor0	=>sfactor0,
		factor1	=>sfactor1,
		factor2	=>sfactor2,
		factor3	=>sfactor3,
		factor4	=>sfactor4,
		factor5	=>sfactor5,
		factor6	=>sfactor6,
		factor7	=>sfactor7,
		factor8	=>sfactor8,
		factor9	=>sfactor9,
		factor10=>sfactor10,
		factor11=>sfactor11,
		--prd32blki 	=> sfactor,

		sumando0=>ssumando0,
		sumando1=>ssumando1,
		sumando2=>ssumando2,
		sumando3=>ssumando3,
		sumando4=>ssumando4,
		sumando5=>ssumando5,
		--add32blki	=> ssumando,
		
		a0=>sa0o,
		a1=>sa1o,
		a2=>sa2o,
		--add32blko 	=> sadd32blko, 
		
		p0=>sp0o,
		p1=>sp1o,
		p2=>sp2o,
		p3=>sp3o,
		p4=>sp4o,
		p5=>sp5o,
		--prd32blko	=> sprd32blko,
		
		sq32o=> ssq32o,
		inv32o=> sinv32o
	);	
	
	--! Cadena de sincronizaci&oacute;n: 29 posiciones.
	pipeline_pending <= sync_chain_1 or not(sq2_e) or not(sq1_e) or not(sqr_e);
	empty <= sqr_e;
	sync_chain_proc:
	process(clk,rst,sync_chain_1)
	begin
		if rst=rstMasterValue then
			ssync_chain(ssync_chain_max downto ssync_chain_min) <= (others => '0');

			p0 <= (others => '0');
			p1 <= (others => '0');
			p2 <= (others => '0');

		elsif clk'event and clk='1' then
			for i in ssync_chain_max downto ssync_chain_min+1 loop
				ssync_chain(i) <= ssync_chain(i-1);
			end loop;
			ssync_chain(ssync_chain_min) <= sync_chain_1;
			
			--! Salida de los multiplicadores p0 p1 p2 
			if ssync_chain(23)='1' then
				p0 <= ssq32; -- El resultado quedara consignado en VZ1=BASE+1
			elsif ssync_chain(28)='1' then 
				p1 <= sq2_q; -- El resultado quedara consignado en VX1=BASE+3
 			elsif ssync_chain(24)='1' then
				p2 <= sinv32; -- El resutlado quedara consignado en VY1=BASE+2
				p3 <= sqx_q;
				p4 <= sqy_q;
				p5 <= sqz_q;
			elsif ssync_chain(28)='1' then 
				p6 <= sp3o;
				p7 <= sp4o;	
				p8 <= sp5o;	
			end if;
			
		end if;
	end process sync_chain_proc;
	
	
	
	
	
	--! El siguiente c&oacute;digo sirve para conectar arreglos a se&ntilde;ales std_logic_1164, son abstracciones de c&oacute;digo tambi&eacute;n, sin embargo se realizan a trav&eacute;s de registros. 
	register_products_outputs:
	process (clk)
	begin
		if clk'event and clk='1' then
			sp0 <= sp0o;
			sp1 <= sp1o;
			sp2 <= sp2o;
			sp3 <= sp3o;
			sp4 <= sp4o;
			sp5 <= sp5o;
			sa0 <= sa0o;
			sa1 <= sa1o;
			sa2 <= sa2o;
			sinv32 <= sinv32o;
			ssq32 <= ssq32o;
		end if;
	end process;
	
	--! Decodificaci&oacute;n del Datapath.
	datapathproc:process(dcs,ax,bx,ay,by,az,bz,sinv32,sp0,sp1,sp2,sp3,sp4,sp5,sa0,sa1,sa2,sq0_q,sqx_q,sqy_q,sqz_q,ssync_chain,ssq32,sq2_q)
	begin
	
		case dcs is
			when "011"  => 

				sq2_w <= '0';
				sq2_d <= ssq32;
				
				sfactor0 <= ay;
				sfactor1 <= bz;
				sfactor2 <= az;
				sfactor3 <= by;
				sfactor4 <= az;
				sfactor5 <= bx;
				sfactor6 <= ax;
				sfactor7 <= bz;
				sfactor8 <= ax;
				sfactor9 <= by;
				sfactor10 <= ay;
				sfactor11 <= bx;
				
				ssumando0 <= sp0;
				ssumando1 <= sp1;
				ssumando2 <= sp2;
				ssumando3 <= sp3;
				ssumando4 <= sp4;
				ssumando5 <= sp5;
				
				sqr_dx <= sa0;
				sqr_dy <= sa1;
				sqr_dz <= sa2;
				
				sqr_w <= ssync_chain(13+adder2_delay);
			
			when"000"|"001" => 

				sq2_w <= '0';
				sq2_d <= ssq32;

				sfactor0 <= ay;
				sfactor1 <= bz;
				sfactor2 <= az;
				sfactor3 <= by;
				sfactor4 <= az;
				sfactor5 <= bx;
				sfactor6 <= ax;
				sfactor7 <= bz;
				sfactor8 <= ax;
				sfactor9 <= by;
				sfactor10 <= ay;
				sfactor11 <= bx;

				
				ssumando0 <= ax;
				ssumando1 <= bx;
				ssumando2 <= ay;
				ssumando3 <= by;
				ssumando4 <= az;
				ssumando5 <= bz;
				
				sqr_dx <= sa0;
				sqr_dy <= sa1;
				sqr_dz <= sa2;
				
				sqr_w <= ssync_chain(9+adder2_delay);
			
			when"110" |"100" => 
				
			
				
				sfactor0 <= ax;
				sfactor1 <= bx;
				sfactor2 <= ay;
				sfactor3 <= by;
				sfactor4 <= az;
				sfactor5 <= bz;
				
				sfactor6 <= sinv32;
				sfactor7 <= sqx_q;
				sfactor8 <= sinv32;
				sfactor9 <= sqy_q;
				sfactor10 <= sinv32;
				sfactor11 <= sqz_q;
				
				
				ssumando0 <= sp0;
				ssumando1 <= sp1;
				ssumando2 <= sa0;
				ssumando3 <= sq0_q;
				ssumando4 <= az;
				ssumando5 <= bz;
				
				if dcs(1)='1' then 
					sq2_d <= ssq32;
					sq2_w <= ssync_chain(22+adder1_delay);
				else
					sq2_d <= sa1;
					sq2_w <= ssync_chain(21+adder1_delay);
				end if;
				
				sqr_dx <= sp3;
				sqr_dy <= sp4;
				sqr_dz <= sp5;
				
				sqr_w <= ssync_chain(27+adder1_delay);
			
			when others => 
				
				sq2_w <= '0';
				sq2_d <= ssq32;
				
				sfactor0 <= ax;
				sfactor1 <= bx;
				sfactor2 <= ay;
				sfactor3 <= by;
				sfactor4 <= az;
				sfactor5 <= bz;
				
				sfactor6 <= ax;
				sfactor7 <= bx;
				sfactor8 <= ay;
				sfactor9 <= by;
				sfactor10 <= az;
				sfactor11 <= bz;
				
				ssumando0 <= sp0;
				ssumando1 <= sp1;
				ssumando2 <= sa0;
				ssumando3 <= sq0_q;
				ssumando4 <= az;
				ssumando5 <= bz;

				sqr_dx <= sp3;
				sqr_dy <= sp4;
				sqr_dz <= sp5;

				sqr_w <= ssync_chain(5);
						
		end case;
				
			
						
	
	end process;
	
	--! Colas internas de producto punto, ubicada en el pipe line aritm&eacute;co. Paralelo a los sumadores a0 y a2.  
	q0 : scfifo --! Debe ir registrada la salida.
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 4,
		lpm_numwords			=> 16,
		lpm_showahead			=> "ON",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		sclr		=> '0',
		clock		=> clk,
		rdreq		=> ssync_chain(13),
		wrreq		=> ssync_chain(5),
		data		=> sp2,
		q			=> sq0_q
	);
	--! Colas internas de producto punto, ubicada en el pipe line aritm&eacute;co. Paralelo a los sumadores a0 y a2.  
	q2 : scfifo --! Debe ir registrada la salida.
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 4,
		lpm_numwords			=> 16,
		lpm_showahead			=> "ON",
		lpm_type				=> "SCIFIFO",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port map (
		rdreq		=> ssync_chain(28),
		sclr		=> '0',
		clock		=> clk,
		empty		=> sq2_e,
		q			=> sqr_dsc,
		wrreq		=> sq2_w,
		data		=> sq2_d
	);
	
	--! Cola interna de normalizaci&oacute;n de vectores, ubicada entre el pipeline aritm&eacute;tico
	qx : scfifo
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 5,
		lpm_numwords			=> 32,
		lpm_showahead			=> "ON",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		aclr		=> '0',
		clock		=> clk,
		empty		=> sq1_e,
		rdreq		=> ssync_chain(23+adder1_delay),
		wrreq		=> sync_chain_1,
		data		=> ax,
		q			=> sqx_q
	);
	qy : scfifo
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 5,
		lpm_numwords			=> 32,
		lpm_showahead			=> "ON",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		aclr		=> '0',
		clock		=> clk,
		rdreq		=> ssync_chain(23+adder1_delay),
		wrreq		=> sync_chain_1,
		data		=> ay,
		q			=> sqy_q
	);
	qz : scfifo
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 5,
		lpm_numwords			=> 32,
		lpm_showahead			=> "ON",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		aclr		=> '0',
		clock		=> clk,
		rdreq		=> ssync_chain(23+adder1_delay),
		wrreq		=> sync_chain_1,
		data		=> az,
		q			=> sqz_q
	);
--!***********************************************************************************************************
--!Q RESULT
--!***********************************************************************************************************
	
	--Colas de resultados
	rx : scfifo
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 5,
		lpm_numwords			=> 32,
		lpm_showahead			=> "ON",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		aclr		=> '0',
		clock		=> clk,
		empty		=> sqr_e,
		rdreq		=> ack,
		wrreq		=> sqr_w,
		data		=> sqr_dx,
		q			=> vx
	);
	ry : scfifo
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 5,
		lpm_numwords			=> 32,
		lpm_showahead			=> "ON",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		aclr		=> '0',
		clock		=> clk,
		rdreq		=> ack,
		wrreq		=> sqr_w,
		data		=> sqr_dy,
		q			=> vy
	);
	rz : scfifo
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 5,
		lpm_numwords			=> 32,
		lpm_showahead			=> "ON",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		aclr		=> '0',
		clock		=> clk,
		rdreq		=> ack,
		wrreq		=> sqr_w,
		data		=> sqr_dz,
		q			=> vz
	);
	rsc : scfifo
	generic map (
		allow_rwcycle_when_full	=> "ON",
		lpm_widthu				=> 5,
		lpm_numwords			=> 32,
		lpm_showahead			=> "ON",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
	)
	port	map (
		aclr		=> '0',
		clock		=> clk,
		rdreq		=> ack,
		wrreq		=> sqr_w,
		data		=> sqr_dsc,
		q			=> sc
	);
	
	
end architecture;
