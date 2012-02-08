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
	generic (
		EOBFLAG		: string := "NO";
		ZEROFLAG	: string := "YES";
		BACKWARDS	: string := "YES";
		EQUALFLAG	: string := "NO";	
		subwidth	: integer := 0;	
		width 		: integer := 5
	);
	port (
		clk,rst,go,set : in std_logic;
		setValue, cmpBlockValue : in std_logic_vector (width-1 downto subwidth); --! Los 5 bits de arriba.
		zero_flag,eob_flag, eq_flag : out std_logic;
		count : out std_logic_vector (width - 1 downto 0)
	);
end entity;



architecture customCounter_arch of customCounter is 

	
	signal scount_d, scount_q, sgo : std_logic_vector(width-1 downto 0);
	signal seob_flag : std_logic;

begin

	--!Compara los bits superiores solamente, si subwidth es 4 y width es 9 comparara los 9-4=5 bits superiores.
	steadyEqualFlag:
	if EQUALFLAG/="YES" generate
		eq_flag <= '0';
	end generate steadyEqualFlag;
	equalFlagsProcess:
	if EQUALFLAG="YES" generate
		process (scount_d(width-1 downto subwidth),cmpBlockValue,clk,rst)
		begin
			if rst=rstMasterValue then
				eq_flag <= '0';
			elsif clk'event and clk='1' then
				if scount_d(width-1 downto subwidth)=cmpBlockValue then
					eq_flag <= '1';
				else
					eq_flag <= '0';
				end if;
			end if;
		end process;
	end generate equalFlagsProcess;

	--Backwards or Forwards.
	forwardGenerator:
	if BACKWARDS="NO" generate
		sgo(width-1 downto 1) <= (others => '0');
		sgo(0) <= go;
	end generate forwardGenerator;

	backwardGenerator:
	if BACKWARDS="YES" generate
		sgo(width-1 downto 0) <= (others => go);		
	end generate backwardGenerator;  
		 

	--! Si en los par&aacute;metros no se encuentra especificado que detecte el zero entonces la salida zero_flag estar&aacute; en cero siempre.
	steadyZeroFlag:
	if ZEROFLAG/="YES" generate
		zero_flag <= '0';
	end generate steadyZeroFlag;
	
	--! Si el par&aacute;metro para la bandera de cero se especifica, entonces se instancia un proceso que depende del valor del conteo.	
	zeroFlagProcess:
	if ZEROFLAG="YES" generate
		--! Proceso para calcular la bandera de cero, en el conteo.
		process (scount_d,clk,rst)
		begin
			if rst=rstMasterValue then
				zero_flag <= '0';
			elsif clk'event and clk='1' then
				zero_flag <= '1';				
				for i in width-1 downto 0 loop
					if scount_d(i) = '1' then
						zero_flag <= '0';
						exit;--the loop;
					end if;
				end loop;
			end if;
		end process;	
	end generate zeroFlagProcess;
	
	
	--! Proceso para controlar la salida de la bandera de fin de bloque. Se colocar&aacute; en uno l&oacute;gico cuando el conteo vaya en multiplo de 32 menos 1.
	steadyEobFlag:
	if EOBFLAG/="YES" generate
		eob_flag <= '0';
	end generate steadyEobFlag;
	eobFlagProcess:
	if EOBFLAG="YES" generate
		process (scount_d(subwidth-1 downto 0),clk,rst)
		begin
			if rst=rstMasterValue then
				eob_flag <= '0';
			elsif clk'event and clk='1' then
				eob_flag <= '1';
				for i in subwidth-1 downto 0 loop 
					if scount_d(i) /= '1' then 
						eob_flag <= '0';
						exit;--the loop
					end if;
				end loop;
			end if;
		end process;
	end generate eobFlagProcess;
		
	--! Salida combinatoria del contador.
	count <= scount_d;
	
	--! Proceso de control del conteo.
	add_proc:
	process (scount_q,sgo,set,setValue)
	begin
		case set is
			--! Si subwidth es cero, p.ej. cuando se quiere hacer un contador simple y no detectar el final de bloques de 4 bits de ancho, el compilador ignora el statement con la expresi&oacute;n por fuera del rango. 
			when '1'  => scount_d(subwidth-1 downto 0) <= (others => '0');scount_d(width-1 downto subwidth) <= setValue;
			when others => scount_d <= scount_q+sgo;
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
				
	