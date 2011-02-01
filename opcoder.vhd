--! @file opcoder.vhd
--! @brief Decodificador de operacion. 
--! @author Julián Andrés Guarín Reyes.
--------------------------------------------------------------
-- RAYTRAC
-- Author Julian Andres Guarin
-- opcoder.vhd
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


--! Libreria de definicion de senales y tipos estandares, comportamiento de operadores aritmeticos y logicos.\n Signal and types definition library. This library also defines 
library ieee;
--! Paquete de definicion estandard de logica. Standard logic definition pack.
use ieee.std_logic_1164.all;

--! La entidad opcoder es la etapa combinatoria que decodifica la operacion que se va a realizar.

--! \n\n   
--! Las entradas a esta descripci&oacute;n son: los vectores A,B,C,D, las entradas opcode y addcode. Las salidas del decodificador, estar&aacute;n conectadas a las entradas de los 6 multiplicadores de una entidad uf. Los operandos de los multiplicadores, tambi&eacute;n conocidos como factores, son las salida m0f0, m0f1 para el multiplicador 1 y as&iacute; hasta el multiplicador 5. B&aacute;sicamente lo que opera aqu&iacute; en esta descripci&oacute;n es un multiplexor, el cual selecciona a trav&eacute;s de opcode y addcode qu&eacute; componentes de los vectores se conectaran a los operandos de los multiplicadores.  
entity opcoder is 
	port (
		Ax,Bx,Cx,Dx,Ay,By,Cy,Dy,Az,Bz,Cz,Dz : in std_logic_vector (17 downto 0);
		m0f0,m0f1,m1f0,m1f1,m2f0,m2f1,m3f0,m3f1,m4f0,m4f1,m5f0,m5f1 : out std_logic_vector (17 downto 0);
		
		opcode,addcode : in std_logic
	);
end entity;

--! Arquitectura del decodificador de operaci&oacute;n.

--! El bloque de arquitectura del decodificador es simplemente una cascada de multiplexores. La selecci&oacute;n se hace en funci&oacute;n de las se&ntilde;ales appcode y addcode\n
--! La siguiente tabla describe el comportamiento de los multiplexores:\n
--! \n\n
--! 
--! <table>
--! <tr><th></th><th>OPCODE</th><th>ADDCODE</th><th>f0</th><th>f1</th><th>&nbsp;</th><th>OPCODE</th><th>ADDCODE</th><th>f0</th><th>f1</th><th>&nbsp;</th></tr> <tr><td>m0</td><td>0</td><td>0</td><td>Ax</td><td>Bx</td><td>&nbsp;</td><td>0</td><td>0</td><td>Cx</td><td>Dx</td><td>m3</td></tr> <tr><td>m0</td><td>0</td><td>1</td><td>Ax</td><td>Bx</td><td>&nbsp;</td><td>0</td><td>1</td><td>Cx</td><td>Dx</td><td>m3</td></tr> <tr><td>m0</td><td>1</td><td>0</td><td>Ay</td><td>Bz</td><td>&nbsp;</td><td>1</td><td>0</td><td>Ax</td><td>Bz</td><td>m3</td></tr> <tr><td>m0</td><td>1</td><td>1</td><td>Cy</td><td>Dz</td><td>&nbsp;</td><td>1</td><td>1</td><td>Cx</td><td>Dz</td><td>m3</td></tr> <tr><td>m1</td><td>0</td><td>0</td><td>Ay</td><td>By</td><td>&nbsp;</td><td>0</td><td>0</td><td>Cy</td><td>Dy</td><td>m4</td></tr> <tr><td>m1</td><td>0</td><td>1</td><td>Ay</td><td>By</td><td>&nbsp;</td><td>0</td><td>1</td><td>Cy</td><td>Dy</td><td>m4</td></tr> <tr><td>m1</td><td>1</td><td>0</td><td>Az</td><td>By</td><td>&nbsp;</td><td>1</td><td>0</td><td>Ax</td><td>By</td><td>m4</td></tr> <tr><td>m1</td><td>1</td><td>1</td><td>Cz</td><td>Dy</td><td>&nbsp;</td><td>1</td><td>1</td><td>Cx</td><td>Dy</td><td>m4</td></tr> <tr><td>m2</td><td>0</td><td>0</td><td>Az</td><td>Bz</td><td>&nbsp;</td><td>0</td><td>0</td><td>Cz</td><td>Dz</td><td>m5</td></tr> <tr><td>m2</td><td>0</td><td>1</td><td>Az</td><td>Bz</td><td>&nbsp;</td><td>0</td><td>1</td><td>Cz</td><td>Dz</td><td>m5</td></tr> <tr><td>m2</td><td>1</td><td>0</td><td>Az</td><td>Bx</td><td>&nbsp;</td><td>1</td><td>0</td><td>Ay</td><td>Bx</td><td>m5</td></tr> <tr><td>m2</td><td>1</td><td>1</td><td>Cz</td><td>Dx</td><td>&nbsp;</td><td>1</td><td>1</td><td>Cy</td><td>Dx</td><td>m5</td></tr></table>
--! \n\n
--! Por ejemplo para ver la tabla de verdad del m0f0, consultar el registro (línea) m0 y el atributo (columna) f0.\n

architecture opcoder_arch of opcoder is 
	
begin
	--! Proceso que describe las 2 etapas de multiplexores. 
	--! Proceso que describe las 2 etapas de multiplexores. Una corresponde al selector addcode, que selecciona con que operadores realizará la operación producto cruz, es decir, seleccionará si realiza la operación AxB ó CxD. En el caso del producto punto, esta etapa de multiplexación no tendrá repercusión en el resultado de la deocdificación de la operación. La otra etapa utiliza el selector opcode, el cual decide si usa los operandos decodificados en la primera etapa de multiplexores, en el caso de que opcode sea 1, seleccionando la operación producto cruz, o por el contrario seleccionando una decodificación de operadores que lleven a cabo la operación producto punto. 

	procOpcoder:
	process (Ax,Bx,Cx,Dx,Ay,By,Cy,Dy,Az,Bz,Cz,Dz,opcode,addcode)
		variable scoder : std_logic_vector (1 downto 0);
	begin 
		scoder := opcode & addcode;
		case (scoder) is
			when "10" =>
				m0f0 <= Ay;
				m0f1 <= Bz;
				m1f0 <= Az;
				m1f1 <= By;
				m2f0 <= Az;
				m2f1 <= Bx;
				m3f0 <= Ax;
				m3f1 <= Bz;
				m4f0 <= Ax;
				m4f1 <= By;
				m5f0 <= Ay;
				m5f1 <= Bx;
			when "11" =>
				m0f0 <= Cy;
				m0f1 <= Dz;
				m1f0 <= Cz;
				m1f1 <= Dy;
				m2f0 <= Cz;
				m2f1 <= Dx;
				m3f0 <= Cx;
				m3f1 <= Dz;
				m4f0 <= Cx;
				m4f1 <= Dy;
				m5f0 <= Cy;
				m5f1 <= Dx;
			when others => 
				m0f0 <= Ax;
				m0f1 <= Bx;
				m1f0 <= Ay;
				m1f1 <= By;
				m2f0 <= Az;
				m2f1 <= Bz;
				m3f0 <= Cx;
				m3f1 <= Dx;
				m4f0 <= Cy;
				m4f1 <= Dy;
				m5f0 <= Cz;
				m5f1 <= Dz;

		end case;
				
				 
		
		
	
	end process procOpcoder;
	

end opcoder_arch;
