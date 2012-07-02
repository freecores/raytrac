--! @file im.vhd
--! @brief Maquina de Interrupciones. Circuito que detecta eventos que generan interrupciones para que el usuario externo del RayTrac detecte eventos como el final de una instrucción.  
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

--! 

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.arithpack.all;
entity im is
	generic (
		num_events : integer :=4;
		cycles_to_wait : integer := 1023
	);
	port (
		clk,rst:		in std_logic;
		rfull_event:	in std_logic;
		eoi_event:		in std_logic;	--! end of instruction related events
		int:			out std_logic;	--! interruption
		state:			out iCtrlState
		
	);
end entity;

architecture im_arch of im is

	
	signal s_state : iCtrlState;
	
	 
begin
	state <= s_state;
	
	--! Existen 2 estados para disparar la se&ntilde;al de interrupci&oacute;n : WAITING_FOR_A_RFULL_EVENT y INHIBIT_RFULL_INT. Siempre que haya el final de una instrucci&oacute;n en cualquiera de los dos estados se notificar&aacute; el evento sin importar el estado en que se encuentre la m&aacute;quina.
	--! Si cualquiera de las se&ntilde;ales de cola llena se encuentra activa, el evento ser&aacute; notificado en el estado WAITING_FOR_A_RFULL_EVENT, inmediatamente se cambia al estado INHIBIT_RFULL_INT, donde durante un n&uacte;mero de ciclos (parametrizado) se ignora la se&ntilde;al de full de las colas de resultados.
	--! Despues que han transcurrido los ciclos mencionados, se vuelve al estado WAITING_FOR_A_RFULL_EVENT.
	sm_proc:
	process (clk,rst)
		variable tempo : integer range 0 to cycles_to_wait:=cycles_to_wait;
	begin
		if rst=rstMasterValue then
			tempo := cycles_to_wait;
			int <= '0';
		elsif clk'event and clk='1' then
						
			case s_state is
				when WAITING_FOR_A_RFULL_EVENT =>
				
					int <= rfull_event or eoi_event;
					if rfull_event='1' then
						s_state <= INHIBIT_RFULL_INT;
						
					end if;
				
				when INHIBIT_RFULL_INT =>
					
					int <= eoi_event;
					if tempo=0 then
						s_state <= WAITING_FOR_A_RFULL_EVENT;
						tempo := cycles_to_wait;
					else
						tempo:=tempo-1;
					end if;
				when others => null;
			end case;
		end if;	
	end process;	
end architecture;

	