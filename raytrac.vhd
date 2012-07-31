--! @file raytrac.vhd
--! @brief Archivo con el RTL que describe al RayTrac en su totalidad.
 
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------------------
-- RAYTRAC
-- Author Julian Andres Guarin
-- Rytrac.vhd
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

entity raytrac is
	port (
		
		clk : in std_logic;
		rst : in std_logic;
		
		
		--! Interface Avalon Master
		address_master	: out	std_logic_vector(31 downto 0);
		begintransfer	: out	std_logic;
		read_master		: out	std_logic;
		readdata_master	: in	std_logic_vector (31 downto 0);
		write_master	: out	std_logic;
		writedata_master: out	std_logic_vector (31 downto 0);
		waitrequest		: in	std_logic_vector;
		readdatavalid_m	: in	std_logic_vector;
				
		--! Interface Avalon Slave
		address_slave	: in	std_logic_vector(3 downto 0);
		read_slave		: in	std_logic;
		readdata_slave	: in	std_logic_vector(31 downto 0);
		write_slave		: in	std_logic;
		writedata_slave	: in	std_logic_vector(31 downto 0);
		readdatavalid_s	: out	std_logic;

		--! Interface Interrupt Sender
		irq	: out std_logic		
		
		
				
	);
end entity;

architecture raytrac_arch of raytrac is 

	--!Se&ntilde;ales de State Machine -> Memblock
	--!TBXSTART:SM
	signal s_adda			: std_logic_vector (8 downto 0);
	signal s_addb			: std_logic_vector (8 downto 0);
	signal s_iq_rd_ack		: std_logic;
	--!Se&ntilde;ales de State Machine -> DataPathControl
	signal s_dpc_uca		: std_logic_vector(2 downto 0);
	signal s_eoi			: std_logic;
	signal s_sign			: std_logic;
	--!TBXEND
	
	--!TBXSTART:MBLK
	--!Se&ntilde;ales de Memblock -> State Machine
	signal sqresult_e		: std_logic_vector(3 downto 0); 
	signal sqparams_e		: std_logic;
	--!Se&ntilde;ales de Memblock -> DPC.
	signal sparaminput		: vectorblock06;
	signal sqresult_q		: vectorblock04;
	--!Se&ntilde;ales de Memblock -> DPC.
	signal s_sync_chain_0	: std_logic;
	--!TBXEND
	
	--!TXBXSTART:DPC
	--! Se&ntilde que va desde DPC -> Memblock
	signal sqresult_d		: vectorblock04;
	signal sqresult_w		: std_logic_vector (3 downto 0);
	signal sqresult_rdec	: std_logic_vector (3 downto 0);
	
	--! Se&ntilde;ales de DPC a ArithBlock
	signal sprd32blki		: vectorblock12;
	signal sadd32blki 		: vectorblock06;
	
	--!TBXEND
	
	--!TBXSTART:ARITHBLOCK
	--! Se&ntilde;ales de Arithblock a DPC
	signal sadd32blko		: vectorblock03; 
	signal sprd32blko		: vectorblock06;
	signal ssq32o			: xfloat32;
	signal sinv32o			: xfloat32;
	--!TBXEND
	
	--!TBXSTART:SM
	--! Se&ntilde;ales de State Machine a DPC
	signal sqresult_sel		: std_logic_vector(1 downto 0);
	signal sdataread		: std_logic;
	signal sd				: std_logic;
	signal sc				: std_logic;
	signal ss				: std_logic;
	
	--! Se&ntilde;ales de State Machine a Memblock
	signal sgo				: std_logic;
	signal scomb			: std_logic;
	signal sload			: std_logic;
	signal sload_chain		: std_logic_vector(1 downto 0);
	--!TBXEND 	
	
	
	
begin
	--!TBXINSTANCESTART
	state_machine : raytrac_control
	port map (
		clk 			=> clk,
		rst 			=> rst,
		adda			=> s_adda,
		addb			=> s_addb,
		sync_chain_0	=> s_sync_chain_0,
		instrRdAckd		=> s_iq_rd_ack,
		full_r			=> s_full_r,
		eoi				=> s_eoi,
		dpc_uca			=> s_dpc_uca,
		state			=> s_smState
		
	);
	--!TBXINSTANCEEND

	--!TBXINSTANCESTART
	MemoryBlock : memblock
	port map (
		clk					=> clk,
		rst					=> rst,
		go					=> sgo,
		comb				=> scomb,
		load				=> sload,
		
		readdatavalid		=> readdatavalid,
		readdata_master		=> readdata_master,
		qparams_e			=> sqparams_e,
		qresult_d			=> sqresult_d,
		paraminput			=> sparaminput,
		sync_chain_0		=> s_sync_chain_0,
		qresult_e			=> sqresult_e,
		qresult_w			=> sqresult_w,
		qresult_rdec		=> sqresult_rdec
		
	);
	--!TBXINSTANCEEND

	--! Instanciar el bloque DPC
	--!TBXINSTANCESTART
	DataPathControl_And_Syncronization_Block: dpc
	port map (
		
		clk				=> clk,
		rst				=> rst,
		
		paraminput		=> sparaminput,
		
		prd32blko		=> sprd32blko,
		add32blko		=> sadd32blko,
		inv32blko		=> sinv32o,
		sqr32blko		=> ssq32o,
		
		d				=> sd,
		c				=> sc,
		s				=> ss,
		
		sync_chain_0	=> s_sync_chain_0,
		
		qresult_q		=> sqresult_q,
		qresult_sel		=> sqresult_sel,
		qresult_rdec	=> sqresult_rdec,
		qresult_w		=> sqresult_w,
		qresult_d		=> sqresult_d,
		
		dataread		=> sdataread,	 	
		
		prd32blki		=> sprd32blki,
		add32blki		=> sadd32blki,
		
		dataout			=> writedata_master


	);
	--!TBXINSTANCEEND
	--! Instanciar el bloque aritm&eacute;tico.
	--!TBXINSTANCESTART
	arithmetic_block : arithblock
	port map (
		clk 		=> clk,
		rst 		=> rst,
		sign 		=> ss,
		prd32blki	=> sprd32blki,
		add32blki	=> sadd32blki,
		add32blko	=> sadd32blko,
		prd32blko	=> sprd32blko,
		sq32o		=> ssq32o,
		inv32o		=> sinv32o
	);
	--!TBXINSTANCEEND
	 
	--!Instanciar la maquina de estados


end architecture;
