
-- RAYTRAC
--! @file cla_logic_block.vhd
--! @author Julian Andres Guarin
--! @brief Bloque de lógica Carry Look Ahead. 
-- cla_logic_block.vhd
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
--     along with raytrac.  If not, see <http://www.gnu.org/licenses/>.library ieee;

-- Check out arithpack.vhd to understand in general terms what this file describes,
-- or checkout this file to check in detailed way what this file intends to.
--! Libreria de definicion de senales y tipos estandares, comportamiento de operadores aritmeticos y logicos.\n Signal and types definition library. This library also defines 
library ieee;
--! Paquete de definicion estandard de logica. Standard logic definition pack.
use ieee.std_logic_1164.all;

--! Entidad generadora de un bloque de cálculo de carry, carry look ahead.

--! En una suma A+B para cada par de bits Ai, Bi, se genera un carry out Couti, este Couti en un bloque generador de carry Carry Look Ahead, no depende del cálculo de los Carry Out anteriores, Couti-1, Couti-2,...., Cout0. Lo que hace el Carry Look Ahead Logic Block, es calcular en paralelo los valores de toso los Couti, usando las señales de propagación y generación, Pi y Gi, y através de una formula "recurrente". Comparado con el Ripple Carry Adder el Carry Look Ahead Adder, empleará la mitad del tiempo, pero para lograrlo usará muchas elementos lógicos en una FPGA o mas transistores en un procesos de fabricación CMOS. En síntesis se sacrifica un mayor uso de recursos para lograr mayor desempeño.

entity cla_logic_block is
	generic (
		w : integer := 4							--! Tamaño por defecto de un bloque Carry Look Ahead.  
	);

	port (
		p,g : in std_logic_vector(w-1 downto 0);	--! Señales de Propagación y Generación. 
		cin : in std_logic;							--! Señal de Carry de entrada. 
		
		c : out std_logic_vector(w downto 1)		--! Carry Out.
	);
end cla_logic_block;


--! Arquitectura del bloque Carry Look Ahead.

--! El bloque de lógica de Carry Look Ahead, se sintetiza a partir de un código comportamental.
--! Para cada Couti, se instancia una función combinatoria. La complejidad de las funciones combinatorias crece con el número de Couti a calcular.
--! La siguiente tabla describe el funcionamiento de este circuito.    

architecture cla_logic_block_arch of cla_logic_block is

begin
	--! El siguiente proceso instancia funciones combinatorias para CADA UNO de los valores de Couti a calcular. En ningun momemnto se utiliza el resultado de los Cout antrerioes a Couti, agilizando el cálculo de las funciones. 

	--! La razón principal para realizar la instanciación de las funciones combinatorias necesarias con un process en vez de un generate, rádica en utilizar un conjunto de variables que afecte unicamente al proceso comportamental descrito y no a la arquitectura entera. 
	claProc:	-- claProc instancia funciones combinatorias en las variables iCarry,
				-- pero notese que los valores de iCarry(i) no dependen jamas de iCarry(i-1) a diferencia de rcaProc.
	process(p,g,cin)

		variable i,j,k :	integer range 0 to w;				-- Variables de control de loop
		variable iCarry:	std_logic_vector(w downto 1);			-- Carry Interno
		variable iResults:	std_logic_vector(((w+w**2)/2)-1 downto 0);	-- Resultados intermedios			
		variable index:		integer;
	begin

		iCarry(w downto 1) := g(w-1 downto 0);
		index := 0; 
		for j in 0 to w-1 loop
			for i in 1 to j+1 loop
				iResults(index) := '1'; 
				for k in j-i+1 to j loop
					iResults(index) := iResults(index) and p(k);
				end loop;
				if j>=i then
					iResults(index) := iResults(index) and g(j-i);
				else
					iResults(index) := iResults(index) and cin;
				end if;
				iCarry(j+1) := iCarry(j+1) or iResults(index);
				index := index + 1;
			end loop;  	  		 			

			c(j+1) <= iCarry(j+1);	

		end loop;

		
		
	end process claProc;

	

end cla_logic_block_arch;

