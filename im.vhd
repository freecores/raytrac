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
		rfull_events:	in std_logic_vector(num_events-1 downto 0);	--! full results queue events
		eoi_events:		in std_logic_vector(num_events-1 downto 0);	--! end of instruction related events
		eoi_int:		out std_logic_vector(num_events-1 downto 0);--! end of instruction related interruptions
		rfull_int:		out std_logic_vector(num_events-1downto 0);	--! full results queue related interruptions
		state:			out iCtrlState
		
	);
end entity;

architecture im_arch of im is

	
	signal s_state : iCtrlState;
	
	signal s_event_polling_chain : std_logic_vector(num_events-1 downto 0);
	signal s_eoi_events : std_logic_vector(num_events-1 downto 0);
	 
begin
	state <= s_state;
	
	sm_proc:
	process (clk,rst,s_event_polling_chain,rfull_events,eoi_events)
		variable tempo : integer range 0 to cycles_to_wait:=cycles_to_wait;
	begin
		if rst=rstMasterValue then
			tempo := cycles_to_wait;
			s_state  <= WAITING_FOR_AN_EVENT;
			s_event_polling_chain <= (others => '0');
			s_eoi_events <= (others => '0');
			rfull_int <= (others => '0');
			eoi_int <= (others => '0');
		elsif clk'event and clk='1' then
			
			for i in num_events-1 downto 0 loop
				if s_eoi_events(i)='0' then --! Hooking events
					s_eoi_events(i) <= eoi_events(i);
				else						--! Event Hooked
					s_eoi_events(i) <= not(s_event_polling_chain(i));
				end if;	
				rfull_int(i) <= s_event_polling_chain(i) and rfull_events(i);
				eoi_int(i) <= s_event_polling_chain(i) and s_eoi_events(i);
				
			end loop;
			case s_state is
				when WAITING_FOR_AN_EVENT => 
					for i in num_events-1 downto 0 loop
						if rfull_events(i)='1' then 
							s_state <= FIRING_INTERRUPTIONS;
							s_event_polling_chain(0) <= '1';
						end if;
					end loop;
				when FIRING_INTERRUPTIONS =>
					if s_event_polling_chain(num_events-1)='1' then
						s_state <= SUSPEND;
						tempo := cycles_to_wait;
					end if;
					for i in num_events-1 downto 1 loop
						s_event_polling_chain(i) <= s_event_polling_chain(i-1);						
					end loop;
					s_event_polling_chain(0) <= '0';
				when SUSPEND => 
					if tempo=0 then
						s_state <= WAITING_FOR_AN_EVENT;
					else
						tempo:=tempo-1;
					end if;
				when others => null;
			end case;
		end if;	
	end process;	
end architecture;

	