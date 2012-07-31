--! @file memblock.vhd
--! @brief Bloque de memoria.
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------------------
-- RAYTRAC
-- Author Julian Andres Guarin
-- memblock.vhd
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

entity memblock is 
	generic (
		
			
		external_readable_widthad	: integer := 3;				
		external_writeable_widthad	: integer := 4		
	);
	port (
		
		--!Entradas de Control
		clk 		: in std_logic;
		rst 		: in std_logic;
		go			: in std_logic;
		comb		: in std_logic;
		load		: in std_logic;
		load_chain	: in std_logic_vector(1 downto 0);
		
		--! Cola de par&aacute;metros 
		readdatavalid: in std_logic;
		readdata_master: in xfloat32;
		qparams_e: out std_logic;
		
		--! Cola de resultados		
		qresult_d: in vectorblock04;
		qresult_q: out vectorblock04;
				
		--! Registro de par&aacute;metros
		paraminput : out vectorblock06;
		
		--! Cadena de sincronización
		sync_chain_0 : out std_logic;
		
		--! se&ntilde;ales de colas vacias
		qresult_e : out std_logic_vector(3 downto 0);
		
	
		
		--! Colas de resultados
		qresult_w: in std_logic_vector(3 downto 0);
		qresult_rdec: in std_logic_vector(3 downto 0)		
		
		
	);
end entity;

architecture memblock_arch of memblock is 

	--!TBXSTART:LOAD_CHAIN
	signal sparams_chain		: std_logic_vector (5 downto 0);
	signal sgo					: std_logic;
	signal sqparams_q			: xfloat32;
	signal sqparams_e			: std_logic;
	--!TBXEND

begin 
	
	--! Cadena de Carga
	sync_chain_0 <= sparams_chain(5);
	load_chain_proc: process (clk,rst,sparams_chain,load,comb,sgo)
	begin
		if rst=rstMasterValue then
			--!LD Section
			sparams_chain <= (others => '0');
			for i in 5 downto 0 loop
				paraminput(i) <= (others => '0');
			end loop;
		elsif clk'event and clk='1' then
			--LOAD SECTION COMBINATORIAL CIRCUIT
			--! Ax enabler.	
			if load='1' then
				sparams_chain(0) <= load_chain(0);
			elsif sgo='1' then
				sparams_chain(0) <= sparams_chain(5) and not(comb);
			else
				sparams_chain(0) <= sparams_chain(0);
			end if;
			--! Ay Az By Bz Enabler.
			for i in 2 downto 1 loop
				if load='1' then
					sparams_chain(i) <= '0';
					sparams_chain(i+3) <= '0';
				elsif sgo='1' then
					sparams_chain(i) <= sparams_chain(i-1);
					sparams_chain(i+3) <= sparams_chain(i+2);
				else
					sparams_chain(i) <= sparams_chain(i);
					sparams_chain(i+3) <= sparams_chain(i+3);
				end if;
			end loop;
			--! Bx enabler.	
			if load='1' then
				sparams_chain(3) <= load_chain(1);
			elsif sgo='1' then
			
				if comb='1' then
					sparams_chain(3) <= sparams_chain(5);
				else
					sparams_chain(3) <= sparams_chain(2);
				end if;
			else
				sparams_chain(3) <= sparams_chain(3);
			end if;
			
			for i in 5 downto 0 loop
				if sparams_chain(i)='1' then
					paraminput(i) <= sqparams_q;
				end if;
			end loop;
		end if; 
	end process; 
	--! Cola de Entrada de parametros
	sgo <= not(sqparams_e) and go; 
	qparams_e <= sqparams_e;
	qparams : scfifo
	generic map(
		add_ram_output_register => "OFF",
		allow_rwcycle_when_full => "OFF",
		intended_device_family	=> "Cyclone III",
		lpm_hint				=> "RAM_BLOCK_TYPE=M9K",
		lpm_numwords			=> 256,
		lpm_showahead			=> "ON",
		lpm_type				=> "SCIFIFO",
		lpm_width				=> 32,
		overflow_checking		=> "ON",
		underflow_checking		=> "ON",
		use_eab					=> "ON"
		
	)
	port map (
		rdreq 	=> sgo,
		aclr 	=> '0',
		empty	=> sqparams_e,
		clock 	=> clk,
		q		=> sqparams_q,
		wrreq	=> readdatavalid,
		data	=> readdata_master
		   
	);
	--! Instanciaci&oacute;n de la cola de resultados.
	results_blocks: 
	for i in 3 downto 0 generate
		resultsfifo : scfifo
		generic map	(
			add_ram_output_register => "OFF",
			allow_rwcycle_when_full => "OFF",
			intended_device_family	=> "Cyclone III",
			lpm_hint				=> "RAM_BLOCK_TYPE=M9K",
			lpm_numwords			=> 256,
			lpm_showahead			=> "ON",
			lpm_type				=> "SCIFIFO",
			lpm_width				=> 32,
			overflow_checking		=> "ON",
			underflow_checking		=> "ON",
			use_eab					=> "ON"
		)
		port map (
			rdreq		=> qresult_rdec(i),
			aclr		=> load,
			empty		=> qresult_e(i),
			clock		=> clk,
			q			=> qresult_q(i),
			wrreq		=> qresult_w(i),
			data		=> qresult_d(i)
		);
	end generate results_blocks;
	
end architecture;

