--! @file arithpack.vhd
--! @author Juli�n Andr�s Guar�n Reyes
--! @brief Este package contiene la descripc�on de los parametros y los puertos de las entidades: uf, opcoder, multiplicador, sumador, cla_logic_block y rca_logic_block.
-- RAYTRAC
-- Author Julian Andres Guarin
-- arithpack.vhd
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


--! Biblioteca de definicion de senales y tipos estandares, comportamiento de operadores aritmeticos y logicos. 
library ieee;
--! Paquete de definicion estandard de logica.
use ieee.std_logic_1164.all;



--! Package con las definiciones de constantes y entidades, que conformar�an el Rt Engine.

--! En general el package cuenta con entidades para instanciar, multiplicadores, sumadores/restadores y un decodificador de operaciones. 
package arithpack is
	
	--! Constante con el nivel l�gico de reset.
	constant rstMasterValue : std_logic := '1';

	--! Entidad uf: sus siglas significan undidad funcional. La unidad funcional se encarga de realizar las diferentes operaciones vectoriales (producto cruz � producto punto). 
	component uf
	port (
		opcode		: in std_logic;
		m0f0,m0f1,m1f0,m1f1,m2f0,m2f1,m3f0,m3f1,m4f0,m4f1,m5f0,m5f1 : in std_logic_vector(17 downto 0);
		cpx,cpy,cpz,dp0,dp1 : out std_logic_vector(31 downto 0);
		clk,rst		: in std_logic
	);
	end component;
		
	--! Entidad opcoder: opcoder decodifica la operaci�n que se va a realizar. Para tal fin coloca en la entrada de uf (unidad funcional), cuales van a ser los operandos de los multiplicadores con los que uf cuenta y adem�s escribe en el selector de operaci�n de uf, el tipo de operaci�n a realizar.
	component opcoder 
	generic (
		width : integer := 18;
		structuralDescription : string:= "NO"
	);
	port (
		Ax,Bx,Cx,Dx,Ay,By,Cy,Dy,Az,Bz,Cz,Dz : in std_logic_vector (17 downto 0);
		m0f0,m0f1,m1f0,m1f1,m2f0,m2f1,m3f0,m3f1,m4f0,m4f1,m5f0,m5f1 : out std_logic_vector (17 downto 0);
		opcode,addcode : in std_logic
	);
	end component;
	
	--! Multiplexor estructural.
	component fastmux is 
	generic (
		width : integer := 18
	);
	port (
		a,b:in std_logic_vector(width-1 downto 0);
		s:in std_logic;
		c: out std_logic_vector(width-1 downto 0)
	);
	end component;
	--! Esta entidad corresponde al multiplicador que se instanciar�a dentro de la unidad funcional. El multiplicador registra los operandos a la entrada y el respectivo producto de la multiplicaci�n a la salida. 
	component r_a18_b18_smul_c32_r
	port (
		aclr,clock:in std_logic;
		dataa,datab:in std_logic_vector (17 downto 0);
		result: out std_logic_vector(31 downto 0)
	);
	end component;
	
	--! cla_logic_block corresponde a un bloque de l�gica Carry look Ahead. Se instancia y utiliza dentro de un sumador cualquiera, pues sirve para calcular los carry out de la operaci�n. 
	component cla_logic_block 
	generic ( w: integer:=4);
	port (
		p,g:in std_logic_vector(w-1 downto 0);
		cin:in std_logic;
		c:out std_logic_vector(w downto 1)
	);
	end component;
	
	--! rca_logic_block corresponde a un bloque de l�gica Ripple Carry Adder. Se instancia y utiliza dentro de un sumador cualquiera, pues sirve para calcular los carry out de la operaci�n.
	component rca_logic_block
	generic ( w : integer := 4);
	port (
		p,g: in std_logic_vector(w-1 downto 0);
		cin: in std_logic;
		c: out std_logic_vector(w downto 1)
	);
	end component;
	
	--! Entidad sumador. Esta entidad tiene un proposito bien claro: sumar. Es altamente parametrizable. Hay 3 cosas que se pueden parametrizar: el ancho del sumador, el tipo de circuito que queremos realice la suma y si el sumador estar� en capacidad de realizar mediante un selector restas.
	component adder
	generic ( 
		w 						: integer := 4;
		carry_logic				: string := "CLA";
		substractor_selector	: string := "YES"
	);
	port (
		a,b		:	in std_logic_vector (w-1 downto 0);
		s,ci	:	in	std_logic;
		result	:	out std_logic_vector (w-1 downto 0);
		cout	:	out std_logic
	);	 		
	end component;
		
end package; 
