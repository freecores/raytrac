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
	port (
		
		clk,rst:in std_logic;
		add0,add1:out std_logic_vector (8 downto 0);
		iq:in std_logic_vector(31 downto 0);
		read_memory,ird_ack:out std_logic;
		ucsa:out std_logic(3 downto 0);
		iempty ,  rfull, opq_empty : in std_logic;
	);
end entity;

architecture sm_arch of sm is

	type macState is (IDLE,EXECUTING,FLUSHING);
	signal state : macState;
	constant rstMasterValue : std_logic:='0';
	
	
	 
	
	signal sadd0,sadd1:std_logic_vector (8 downto 0);
	signal schunk0o,schunk0f,schunk1o,schunk1f: std_logic_vector (3 downto 0);
	signal sadd0_now,sadd0_next,sadd0_reg:std_logic_vector(8 downto 0);
	signal sadd1_now,sadd1_next,sadd1_reg:std_logic_vector(8 downto 0);
	signal sadd0_adder_bit,sadd1_adder_bit,sena:std_logic;
	
	
begin
	
	
	schunk0o(3 downto 0) <=  iq(19 downto 16);
	schunk0f(3 downto 0) <=  iq(15 downto 12);
	schunk1o(3 downto 0) <= iq(11 downto 8);
	schunk1f(3 downto 0) <= iq(7 downto 4);
	
	ucsa <= iq(3 downto 0); 
	
	sadd0_next <= sadd0_now+sadd0_adder_bit;
	sadd1_next <= sadd1_now+sadd1_adder_bit;
	
	
	sm_comb:
	process (state)
	begin
		case state is
			when IDLE => 
				sadd0_now <= schunk0o(3 downto 0)&x"0";
				sadd1_now <= schunk1o(3 downto 0)&x"0";
			when others => 
				sadd0_now <= sadd0_next;
				sadd1_now <= sadd1_next;
		end case;	
						
	end process;


	sm_proc:
	process (clk,rst)
	begin 
		if rst=rstMasterValue then
			state <= IDLE;
			ird_ack <= '0';
		elsif clk='1' and clk'event and sena='1' then
		
			case state is
				when IDLE =>
					if rfull='0' and iempty='0' then
						state <= EXECUTING;
						read_memory <= '1';
					end if;
				when EXCUTING => 
					if rfull='0' then
						if sadd1_now=schunk1f&"11111" then
							if sadd0_now=schunk0f&"11111" then
								state <= FLUSHING;
								
							end if;							
						end if;
					end if;
				when FLUSHING => 
					if opq_empty='1' then
						
					end if; 
			end case;
		end if;
			
	end process;


end architecture;
