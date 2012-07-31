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
use work.arithpack.all;

entity customCounter is
	port (
		clk				: in std_logic;
		rst				: in std_logic;
		stateTrans			: in std_logic;
		waitrequest_n	: in std_logic;
		endaddress		: in std_logic_vector (31 downto 2); --! Los 5 bits de arriba.
		startaddress	: in std_logic_vector(31 downto 0);
		endaddressfetch	: out std_logic;
		address_master 	: out std_logic_vector (31 downto 0)
	);
end entity;

architecture customCounter_arch of customCounter is 
	--!TBXSTART:COUNTING_REGISTERS
	signal saddress_master_d	: std_logic_vector(31 downto 2);
	signal sgo					: std_logic_vector(31 downto 2);
	signal saddress_master_q	: std_logic_vector(31 downto 2);
	signal sendaddress			: std_logic_vector(31 downto 2);
	signal sendaddressfetch		: std_logic;
	--!TBXEND
begin
	--!Compara los bits superiores solamente, si subwidth es 4 y width es 9 comparara los 9-4=5 bits superiores.
	
	--! Evento de finalizaci&oacute;n de fetching de parametros
	--! Si la direcci&oacute;n en el address_master es igual a la ultima direcci&oacute;n y el slave hace fetch de dicha direcci&oacute;n (waitrequest_n=1) entonces se marca el evento de que la &uacute;ltima direcci&oacute;n ha sido leida por el slave.
	endaddressfetch <= sendaddressfetch and waitrequest_n; 
	equalFlagsProcess:
	process (saddress_master_d(31 downto 2),sendaddress,clk,rst)
	begin
		if rst=rstMasterValue then
			sendaddressfetch <= '0';
		elsif clk'event and clk='1' then
			if saddress_master_d(31 downto 2)=sendaddress then
				sendaddressfetch <= '1';
			else
				sendaddressfetch <= '0';
			end if;
		end if;
	end process;

	--Backwards or Forwards.
	sgo(31 downto 3)	<= (others => '0');
	sgo(2) 				<= waitrequest_n;
	
		
	--! Salida combinatoria del contador.
	address_master <= saddress_master_q(31 downto 2) & startaddress(1 downto 0);
	
	--! Proceso de control del conteo.
	saddress_master_d <= saddress_master_q+sgo;
	
	
	count_proc:
	process (clk,rst)
	begin
		if rst=rstMasterValue then 
			saddress_master_q <= (others => '0');
			sendaddress <= (others => '0');
			saddress_master_q <= (others => '0');
		elsif clk='1' and clk'event then 
			saddress_master_q <= saddress_master_d;
			if stateTrans='1' then
				sendaddress 		<= endaddress;
				saddress_master_q 	<= startaddress(31 downto 2);
			end if;
		end if;
	end process;
end architecture;
				
	