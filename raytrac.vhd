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
		
		--! Se&ntilde;al de lectura de alguna de las colas de resultados.
		rd	: in std_logic;
		
		--! Se&ntilde;al de escritura en alguno de los bloques de memoria de operandos o en la cola de instrucciones.
		wr	: in std_logic;
		
		--! Direccion de escritura o lectura
		add : in std_logic_vector (12 downto 0);
		
		--! datos de entrada
		d	: in std_logic_vector (31 downto 0);
		
		--! Interrupciones
		irq : out std_logic;
		
		--! Salidas
		q : out std_logic_vector (31 downto 0)
		
		
				
	);
end entity;

architecture raytrac_arch of raytrac is 

	--! Se&ntilde;ales de State Machine -> Memblock
	--!TBXSTART:SM
	signal s_int_rd_add		: std_logic_vector (17 downto 0);
	signal s_adda			: std_logic_vector (8 downto 0);
	signal s_addb			: std_logic_vector (8 downto 0);
	signal s_iq_rd_ack		: std_logic;
	--! Se&ntilde;ales de State Machine -> DataPathControl
	signal s_sync_chain_0	: std_logic;
	signal s_dpc_uca		: std_logic_vector(2 downto 0);
	signal s_eoi			: std_logic;
	signal s_sign			: std_logic;
	--!TBXEND
	--! Se&ntilde;ales de State Machine -> Testbench
	signal s_smState		: macState;
	
	
	
	
	
	
	--!TBXSTART:MBLK
	--! Se&ntilde;ales de Memblock -> State Machine
	signal s_iq_empty		: std_logic; 
	signal s_iq				: std_logic_vector (31 downto 0);
	--! Se&ntilde;ales de Memblock -> Interruption Machine
	signal s_rfull_events 	: std_logic_vector (3 downto 0); --Estas se&ntilde;ales tambien entran a DPC.
	--! Se&ntilde;ales de Memblock -> DPC.
	signal s_q				: vectorblock12;
	signal s_normfifo_q		: std_logic_vector (3*32-1 downto 0);
	signal s_dpfifo_q		: std_logic_vector (2*32-1 downto 0);
	--!TBXEND
	--!TXBXSTART:SQR32
	--!Se&ntilde;ales de Bloque de Ra&iacute;z Cuadrada a DPC
	signal s_sq32			: std_logic_vector (31 downto 0);
	--!TBXEND
	--!TXBXSTART:INV32
	--!Se&ntilde;ales del bloque inversor a DPC.
	signal s_qout32			: std_logic_vector (31 downto 0);
	--!TBXEND
	--!TXBXSTART:DPC
	--! Se&ntilde;ales de DataPathControl -> State Machine
	signal s_full_r			: std_logic;
	--! Se&ntilde;ales de DPC a sqrt32.
	signal s_rd32			: std_logic_vector (31 downto 0);
	--! Se&ntilde;ales de DPC a inv32.
	signal s_dvd32			: std_logic_vector (31 downto 0);
	--! Se&ntilde;ales de DPC  a invr32.
	--! Se&ntilde que va desde DPC -> Memblock
	signal s_resultfifo_wr	: std_logic_vector (7 downto 0);
	signal s_dpfifo_w		: std_logic;
	signal s_dpfifo_r		: std_logic;
	signal s_dpfifo_d		: std_logic_vector (2*32-1 downto 0);
	signal s_normfifo_w		: std_logic;
	signal s_normfifo_r		: std_logic;
	signal s_results_d		: vectorblock08;
	signal s_normfifo_d		: std_logic_vector (3*32-1 downto 0);
	--!Se&ntilde;ales de DPC a Interruption Machine
	signal s_eoi_events		: std_logic_vector (3 downto 0);
	--! Se&ntilde;ales de DPC a ArithBlock
	signal s_f				: vectorblock12;
	signal s_a 				: vectorblock08;
	--! Parcialmente las se&ntilde;ales de salida de los sumadores van al data path control.
	signal s_s				: vectorblock04; 
	signal s_p				: vectorblock06;
	--!TBXEND
	signal s_resultsfifo_w	: std_logic_vector (4 downto 0);
	
	--!TBXSTART:IM
	--! Se&ntilde;ales de Interruption Machine al testbench
	signal s_iCtrlState		: iCtrlState;
	signal s_int			: std_logic;
	--!TBXEND 	
begin

	--! Sacar las interrupciones
	irq <= s_int;
	
	--! Signo de los bloques de suma
	s_sign <= not(s_dpc_uca(2)) and s_dpc_uca(1);
	--! Instanciar el bloque de memorias MEMBLOCK
	s_resultfifo_wr <= s_resultsfifo_w(4)&s_resultsfifo_w(4)&s_resultsfifo_w(4)&s_resultsfifo_w(3)&s_resultsfifo_w(2)&s_resultsfifo_w(1)&s_resultsfifo_w(2)&s_resultsfifo_w(0);
	s_int_rd_add  <= s_addb&s_adda;
	--!TBXINSTANCESTART
	MemoryBlock : memblock
	port map (
		clk					=> clk,
		rst					=> rst,
		dpfifo_rd			=> s_dpfifo_r,
		normfifo_rd			=> s_normfifo_r,
		dpfifo_wr			=> s_dpfifo_w,
		normfifo_wr			=> s_normfifo_w,
		instrfifo_rd		=> s_iq_rd_ack,
		resultfifo_wr		=> s_resultfifo_wr,
		instrfifo_empty		=> s_iq_empty,
		ext_rd				=> rd,
		ext_wr				=> wr,
		ext_wr_add			=> add,
		ext_rd_add			=> add(12 downto 9),
		ext_d				=> d,
		resultfifo_full		=> s_rfull_events,
		int_d				=> s_results_d,
		status_register		=> s_eoi_events,
		ext_q				=> q,
		instrfifo_q			=> s_iq,
		int_q				=> s_q,
		int_rd_add			=> s_int_rd_add,
		dpfifo_d			=> s_dpfifo_d,
		normfifo_d			=> s_normfifo_d,
		dpfifo_q			=> s_dpfifo_q,
		normfifo_q			=> s_normfifo_q
	);
	--!TBXINSTANCEEND

	--! Instanciar el bloque DPC
	--!TBXINSTANCESTART
	DataPathControl_And_Syncronization_Block: dpc
	port map (
		
		clk				=> clk,
		rst				=> rst,
		paraminput		=> s_q,
		prd32blko		=> s_p,
		add32blko		=> s_s,
		sqr32blko		=> s_sq32,
		inv32blko		=> s_qout32,
		fifo32x23_q		=> s_normfifo_q,
		fifo32x09_q		=> s_dpfifo_q,
		unary			=> s_dpc_uca(2),
		crossprod		=> s_dpc_uca(1),
		addsub			=> s_dpc_uca(0),
		sync_chain_0	=> s_sync_chain_0,
		eoi_int			=> s_eoi,
		eoi_demuxed_int => s_eoi_events,
		sqr32blki		=> s_rd32,
		inv32blki		=> s_dvd32,
		fifo32x26_d		=> s_normfifo_d,
		fifo32x09_d		=> s_dpfifo_d,
		prd32blki		=> s_f,
		add32blki		=> s_a,
		resw			=> s_resultsfifo_w,
		fifo32x09_w		=> s_dpfifo_w,
		fifo32x23_w		=> s_normfifo_w,
		fifo32x09_r		=> s_dpfifo_r,
		fifo32x23_r		=> s_normfifo_r,
		resf_vector		=> s_rfull_events,
		resf_event		=> s_full_r,
		resultoutput	=> s_results_d
	);
	--!TBXINSTANCEEND
	

	--! Instanciar el bloque de inversion
	--!TBXINSTANCESTART
	inversion_block : invr32
	port map (
		clk		=> clk,
		dvd32	=> s_dvd32,
		qout32	=> s_qout32
	);
	--!TBXINSTANCEEND

	--! Instanciar el bloque de ra&iacute;z cuadrada.
	--!TBXINSTANCESTART
	square_root : sqrt32
	port map (
		clk 	=> clk,
		rd32	=> s_rd32,
		sq32	=> s_sq32 
	);
	--!TBXINSTANCEEND
	
	--! Instanciar el bloque aritm&eacute;tico.
	--!TBXINSTANCESTART
	arithmetic_block : arithblock
	port map (
		clk => clk,
		rst => rst,
		dpc => s_sign,
		f	=> s_f,
		a	=> s_a,
		s	=> s_s,
		p	=> s_p
	);
	--!TBXINSTANCEEND
	 
	--! Instanciar la maquina de interrupciones
	--!TBXINSTANCESTART
	interruption_machine : im
	generic map (
		num_events 		=> 4,
		cycles_to_wait	=> 1023 
	)
	port map (
		clk				=> clk,
		rst				=> rst,
		rfull_event		=> s_full_r,
		eoi_event		=> s_eoi,
		int				=> s_int,
		state			=> s_iCtrlState
		
	);
	--!TBXINSTANCEEND
	--!Instanciar la maquina de estados
	
	--!TBXINSTANCESTART
	state_machine : sm

	port map (
		clk 			=> clk,
		rst 			=> rst,
		instrQq			=> s_iq,
		instrQ_empty	=> s_iq_empty,
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

end architecture;
