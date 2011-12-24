--! @file sm.vhd
--! @brief Maquina de Estados. Controla la operación interna y genera los mecanismos de sincronización con el exterior (interrupciones). 
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------------------
-- RAYTRAC
-- Author Julian Andres Guarin
-- sm.vhd
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



entity sm is
	generic (
		width : integer := 32;
		widthadmemblock : integer := 9
		--!external_readable_widthad : 				
	)
	port (
		
		clk,rst:in std_logic;
		
		adda,addb:out std_logic_vector (widthadmemblock-1 downto 0);
		sync_chain_d:out std_logic;
		
		--! Instruction Q, instruction.
		instrQq:in std_logic_vector(width-1 downto 0);
		
		
		
		--! apempty, arithmetical pipeline empty.
		arithPbusy, instrQempty ,resultQfull: in std_logic;
		
		--! DataPath Control uca code.
		dpc_uca : out std_logic_vector (2 downto 0);
		
		
	);
end entity;

architecture sm_arch of sm is

	type macState is (FLUSH_TO_NEXT_INSTRUCTION,EXECUTE_INSTRUCTION);
	signal state : macState;
	constant rstMasterValue : std_logic:='0';
	
	component customCounter
	generic (		
		width :	integer
		
	);
	port (
		clk,rst,go,set	: in std_logic;
		setValue		: in std_Logic_vector(width-1 downto 0);
		count			: out std_logic_vector(width-1 downto 0)
	)
	
	signal addt0_blocka,addt0_blockb,set_Value_A,set_Value_B : std_logic_vector(widthadmemblock-1 downto 0);
	signal add_condition_a, add_condition_b,set_a,set_b : std_logic;
	signal s_dpc_uca, s_instrQ_uca : std_logic_vector(2 downto 0);	 
	signal s_block_start_a, s_block_start_b, s_block_end_a, s_block_end_b : std_logic_vector(4 downto 0);
	

		
begin

	--! Bloques asignados
	s_block_start_a <= instrQq(width-4 downto width-8);
	s_block_start_b <= instrQq(width-14 downto width-18);
	s_block_end_a <= instrQq(width-9 downto width-13);
	s_block_end_b <= instrQq(width-19 downto width-)
	
	--! Address Counters
	counterA:customCounter
	port map (clk,rst,add_condition_a,set_a,instrQq(width-4 downto width-8)&x"0",addt0_blocka);
	counterB:customCounter
	port map (clk,rst,add_condition_b,set_b,instrQq(width-9 downto width-12)&x"0",addt0_blockb);
	adda <= addt0_blocka;
	addb <= addt0_blockb;
	
	--! uca code 
	s_instrQ_uca <= instrQq(31 downto 29);
	
	
	sm_proc:
	process (clk,rst)
	begin 
		if rst=rstMasterValue then
			state <= IDLE;
			ird_ack <= '0';
		elsif clk='1' and clk'event then
		
			case state is
				when FLUSH_TO_NEXT_INSTRUCTION =>
					
					--! Chequear si hay una instruccion en la salida de la cola de instruccioens.
					if instrQempty='0' then
						
						--! Chequear si la cola de resultados tiene espacio.
						if resultQfull='0' then
							
							--! Si el codigo de instruccion (uca) que se encuentra en el DPC es igual al que se encuentra en la instruccion de la salida de la cola de instrucciones, entonces no hay mas validaciones que hacer. 
							
							
								--! Now check that arithmetic pipline is not busy 
								if arithPbusy='0' then
														  
						
				when EXECUTE_INSTRUCTION =>
					if addt1_blockb(4 downto 0)=x"1f" and addt1_blocka=x"1f" then
						if addt1_blockb(8 downto )
					else
					
					end if; 
			end case;
		end if;
	end process;
	
	nxtadda_proc:
	process ()
end architecture;
