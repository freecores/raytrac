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


entity customCounter is
	generic (
		width : integer := 9;
	)
	port (
		clk,rst,go,set : in std_logic;
		setValue : in std_logic_vector(width - 1 downto 0);
		count : out std_logic_vector (width - 1 downto 0)
	);
end entity;



architecture customCounter_arch of customCounter is 

	constant rstMasterValue : std_logic := '0';
	signal scount_d, scount_q : std_logic_vector(width-1 downto 0);
	

begin
	count <= scount_d;
	add_proc:
	process (scount_q,go,set,setValue)
	begin
		case set is 
			when '1'  => scount_d <= setValue;
			when others => scount_d <= scount_q+go;
		end case;
	end process;
	
	count_proc:
	process (clk,rst)
	begin
		if rst=rstMasterValue then 
			scount_q <= (others => '0');
		elsif clk='1' and clk'event then 
			scount_q <= scount_d;
		end if;
	end process;
end architecture;
				
	