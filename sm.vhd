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
	);
	port (
		
		--! Se&ntilde;ales normales de secuencia.
		clk,rst:			in std_logic;
		--! Vector con las instrucción codficada
		instrQq:in std_logic_vector(width-1 downto 0);
		--! Señal de cola vacia.
		instrQ_empty:in std_logic;
		
				
		adda,addb:out std_logic_vector (widthadmemblock-1 downto 0);
		sync_chain_0,instrRdAckd:out std_logic;
		
		
		full_r: 	in std_logic;	--! Indica que la cola de resultados no puede aceptar mas de 32 elementos.
	
		
		--! End Of Instruction Event
		eoi	: out std_logic;
		
		--! DataPath Control uca code.
		dpc_uca : out std_logic_vector (2 downto 0)
		
		
	);
end entity;

architecture sm_arch of sm is

	type macState is (LOAD_INSTRUCTION,FLUSH_ARITH_PIPELINE,EXECUTE_INSTRUCTION);
	--! LOAD_INSTRUCTION: Estado en el que se espera que en la cola de instrucciones haya una instrucción para ejecutar.
	--! EXECUTE_INSTRUCTION: Estado en el que se ejecuta la instrucci&oacute;n de la cola de instrucciones.
	--! FLUSH_ARITH_PIPELINE: Estado en el que se espera un número específico de ciclos de reloj, para que se desocupe el pipeline aritmético.
	
	signal state : macState;
	constant rstMasterValue : std_logic:='0';
	
	component customCounter
	generic (		
		EOBFLAG		: string ;
		ZEROFLAG	: string ;
		BACKWARDS	: string ;
		EQUALFLAG	: string ;	
		subwidth	: integer;	
		width 		: integer
		
	);
	port (
		clk,rst,go,set	: in std_logic;
		setValue,cmpBlockValue		: in std_Logic_vector(width-1 downto subwidth);
		zero_flag,eob_flag,eq_flag	: out std_logic;
		count			: out std_logic_vector(width-1 downto 0)
	);
	end component;
	
	signal s_instr_uca: 	std_logic_vector(2 downto 0);
	signal s_dpc_uca: 		std_logic_vector(2 downto 0);	 
	signal s_block_start_a: std_logic_vector(4 downto 0);
	signal s_block_start_b: std_logic_vector(4 downto 0); 
	signal s_block_end_a:	std_logic_vector(4 downto 0); 
	signal s_block_end_b:	std_logic_vector(4 downto 0); 
	signal s_combinatory: 	std_logic;
	signal s_delay_field:	std_logic_vector(7 downto 0);
	signal s_set_b:			std_logic;						--! Se&ntilde;al para colocar un valor arbitrario en el contador B.
	signal s_set_a:			std_logic;	
	signal s_set_dly:		std_logic;
	signal s_go_b:			std_logic;						--! Salida para controlar la pausa(0) o marcha(1) del contador de direcciones del operando B/D.
	signal s_go_a:			std_logic;						--! Salida para controlar la pausa(0) o marcha(1) del contador de direcciones del operando A/C.	
	signal s_go_delay:		std_logic;						--! Salida para controlar la pausa(0) o marcha(1) del contador de delay, para el flush del pipeline aritm&eacute;tico.
	signal s_zeroFlag_delay:std_logic;						--! Bandera de cero del contador delay.	
	signal s_eq_b,s_eq_a: 	std_logic; 	--! Indica cuando se est&aacute; leyendo el &uacute;ltimo bloque de memoria con operandos de entrada de a y de b respectivamente. 
	signal s_eb_b,s_eb_a:	std_logic; 	--! Indica que se est&aacute; leyendo en memoria el &uacute;ltimo operando del bloque actual, b o a, respectivamente.
		 	
begin
	--! Código UCA, pero en la etapa DPC: La diferencia es que UCA en la etapa DPC, decodifica el datapath dentro del pipeline aritmético.
	dpc_uca <= s_dpc_uca;


	--! Bloques asignados en la instrucci´øn
	s_block_start_a <= instrQq(width-4 downto width-8);
	s_block_end_a <= instrQq(width-9 downto width-13);
	
	s_block_start_b <= instrQq(width-14 downto width-18);
	s_block_end_b <= instrQq(width-19 downto width-23);
	
	--! Campo que define si la instrucción es combinatoria
	s_combinatory <= instrQq(width-24);
	
	--! Campo que define cuantos clocks debe esperar el sistema, despues de que se ejecuta una instrucción, para que el pipeline aritmético quede vacio.
	s_delay_field <= instrQq(width-25 downto width-32);
	
	--! UCA code, código con la instrucción a ejecutar. 
	s_instr_uca <= instrQq(31 downto 29);
	
	--! Address Counters
	counterA:customCounter
	generic map ("YES","NO","NO","YES",4,9)
	port map (clk,rst,s_go_a,s_set_a,s_block_start_a,s_block_end_a,open,s_eb_a,s_eq_a,adda);
	counterB:customCounter
	generic map ("YES","NO","NO","YES",4,9)
	port map (clk,rst,s_go_b,s_set_b,s_block_start_b,s_block_end_b,open,s_eb_b,s_eq_b,addb);
	counterDly:customCounter
	generic map("NO","YES","YES","NO",0,5)
	port map (clk,rst,s_go_delay,s_set_dly,s_delay_field(4 downto 0),"00000",s_zeroFlag_delay,open,open,open);
	
	
	sm_comb:
	process (state, full_r,s_eb_b,s_combinatory,s_zeroFlag_delay,s_eq_b,s_eb_a,s_eq_a,instrQ_empty)
	begin
		--!Se&ntilde;al de play/pause del contador de direcciones para el par&aacute;metro B/D.
		s_go_b <= not(full_r and s_eb_b);
	
		--!Se&ntilde;al de play/pause del contador de direcciones para el par&aacute;metro A/C.
		if s_combinatory='0' then
			s_go_a <= not(full_r and s_eb_b);
				
		else
			s_go_a <= not(full_r) and s_eb_b and s_eq_b;
		end if; 
		
		--!Se&ntilde;al de play/pause del contador del arithmetic pipeline flush counter.
		s_go_delay  <= not(s_zeroFlag_delay);	
		
		--! Si estamos en el final de la instrucción, "descargamos" esta de la máquina de estados con acknowledge read.
		if s_eb_b='1' and s_eq_b='1' and s_eb_a='1' and s_eq_a='1' and state=EXECUTE_INSTRUCTION then
			instrRdAckd <= '1';
		else
			instrRdAckd <= '0';
		end if;
		
		if (s_eb_a='1' and s_eq_a='1') or state=LOAD_INSTRUCTION or state=FLUSH_ARITH_PIPELINE then
			s_set_a <= '1';
		else
			s_set_a <= '0';
		end if;
		 
		
			
		if (s_eb_b='1' and s_eq_b='1') or state=LOAD_INSTRUCTION or state=FLUSH_ARITH_PIPELINE then
			s_set_b <= '1';
		else
			s_set_b <= '0';
		end if;			
				
	end process;
	
	sm_proc:
	process (clk,rst,state, full_r,s_eb_b,s_combinatory,s_zeroFlag_delay,s_eq_b,s_eb_a,s_eq_a,instrQ_empty)
	begin 
		
		if rst=rstMasterValue then
		
			state <= LOAD_INSTRUCTION;
			s_set_dly <= '1';
			sync_chain_0 <= '0';
			eoi<='0';
			s_dpc_uca <= (others => '0');
			
		
		elsif clk='1' and clk'event then
		
			case state is
					
				--! Cargar la siguiente instrucción. 
				when LOAD_INSTRUCTION => 
				
					eoi <= '0';
				
					if instrQ_empty='0' and full_r='0' then
						
						--! Siguiente estado: Ejecutar la instrucción.  
						state <= EXECUTE_INSTRUCTION;
						
						--! Asignar el código UCA para que comience la decodificación.
						s_dpc_uca <= s_instr_uca;
						
						--! Validar el siguiente dato dentro del pipeline aritmético.
						sync_chain_0 <= '1';
						
						--! En el estado EXECUTE, el valor del contador de delay se debe mantener fijo, y puesto en el valor de delay que contiene la instruccion.
						s_set_dly <= '1';
						
						
						
					end if;
					
				--! Ejecución de la instruccion		
				when EXECUTE_INSTRUCTION =>
					

					if s_eb_b='1'and s_eq_b='1' and s_eb_a='1' and s_eq_a='1' then	--! Revisar si es el fin de la instruccion
						
						
						--!Ya no ingresaran mas datos al pipeline aritmético, invalidar.
						sync_chain_0 <= '0';
						
						if s_zeroFlag_delay='1' then 
						
							--! Notificar fin de procesamiento de la instruccion (End Of Instruction)
							eoi <= '1';
							state <= LOAD_INSTRUCTION;
							s_set_dly <= '1';
							
						
						else	
							
							state <= FLUSH_ARITH_PIPELINE;
							s_set_dly <= '0';
							
						end if;								
					
					--! Invalidar/validar datos dentro del pipeline aritmético.
					elsif s_eb_b='1' and full_r='1' then
						--! Invalidar el siguiente dato dentro del pipeline aritmético.
						sync_chain_0 <= '0';
					else
						sync_chain_0 <= '1';
					end if;
				
				--! Ejecución de la instrucción 		
				when FLUSH_ARITH_PIPELINE =>
					--! Este estado permanece así hasta que, haya una instrucción 
					if s_zeroFlag_delay='1' then
					
						--! Notificar fin de procesamiento de la instruccion (End Of Instruction)
						eoi <= '1';
						state <= LOAD_INSTRUCTION;
						s_set_dly <= '1';
					
					end if;
				
				when others => null;	
			
			end case;
		end if;
	end process;
	
end architecture;
