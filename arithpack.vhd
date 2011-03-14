--! @file arithpack.vhd
--! @author Julian Andres Guarin Reyes
--! @brief Este package contiene la descripcion de los parametros y los puertos de las entidades: uf, opcoder, multiplicador, sumador, cla_logic_block y rca_logic_block.
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

--use ieee.std_logic_unsigned.conv_integer;


--! Biblioteca de definicion de memorias de altera
library altera_mf;
--! Paquete para manejar memorias internas tipo M9K
use altera_mf.all;

--! Biblioteca de modulos parametrizados.
library lpm;
use lpm.all;

--! Package de entrada y salida de texto.
use std.textio.all;



--! Package con las definiciones de constantes y entidades, que conformaran el Rt Engine. Tambien con algunas descripciones para realizar test bench.

--! En general el package cuenta con entidades para instanciar, multiplicadores, sumadores/restadores y un decodificador de operaciones. 
package arithpack is
	
	--! TestBenchState
	type tbState is (abcd,axb,cxd,stop);
	
	--! Constante con el nivel l—gico de reset.
	constant rstMasterValue : std_logic := '1';
	
	--! Constante: periodo del reloj;
	constant tclk : time := 20 ns;
	constant tclk2: time := tclk/2;
	constant tclk4: time := tclk/4;
	
	
	--! Generacion de Clock y de Reset.
	component clock_gen 
		generic	(tclk : time := tclk);
		port	(clk,rst : out std_logic);
	end component;
	
	--! Ray Trac: Implementacion del Rt Engine
	component raytrac
	generic (
		
		registered : string := "NO" --! Este parametro, por defecto "YES", indica si se registran o cargan en registros los vectores A,B,C,D y los codigos de operacion opcode y addcode en vez de ser conectados directamente al circuito combinatorio. \n This parameter, by default "YES", indicates if vectors A,B,C,D and operation code inputs opcode are to be loaded into a register at the beginning of the pipe rather than just connecting them to the operations decoder (opcoder). 
	);
	port (
		A,B,C,D 		: in std_logic_vector(18*3-1 downto 0); --! Vectores de entrada A,B,C,D, cada uno de tamano fijo: 3 componentes x 18 bits. \n Input vectors A,B,C,D, each one of fixed size: 3 components x 18 bits. 
		opcode,addcode	: in std_logic;							--! Opcode and addcode input bits, opcode selects what operation is going to perform one of the entities included in the design and addcode what operands are going to be involved in such. \n Opcode & addcode, opcode selecciona que operacion se va a llevar a cabo dentro de una de las entidades referenciadas dentro de la descripcion, mientras que addcode decide cuales van a ser los operandos que realizaran tal. 
		clk,rst,ena			: in std_logic;							--! Las senales de control usual. The usual control signals.
		CPX,CPY,CPZ,DP0,DP1 : out std_logic_vector(31 downto 0)	--! Salidas que representan los resultados del RayTrac: pueden ser dos resultados, de dos operaciones de producto punto, o un producto cruz. Por favor revisar el documento de especificacion del dispositivo para tener mas claridad.\n  Outputs representing the result of the RayTrac entity: can be the results of two parallel dot product operations or the result of a single cross product, in order to clarify refere to the entity specification documentation.
		
		
	);
	end component;
	
	--! componente memoria instanciado mediante la biblioteca de altera
	component altsyncram
	generic (
		address_aclr_a		: string;
		clock_enable_input_a		: string;
		clock_enable_output_a		: string;
		init_file		: string;
		intended_device_family		: string;
		lpm_hint		: string;
		lpm_type		: string;
		numwords_a		: natural;
		operation_mode		: string;
		outdata_aclr_a		: string;
		outdata_reg_a		: string;
		ram_block_type		: string;
		widthad_a		: natural;
		width_a		: natural;
		width_byteena_a		: natural
	);
	port (
			clock0	: in std_logic ;
			address_a	: in std_logic_vector (8 downto 0);
			q_a	: out std_logic_vector (17 downto 0)
	);
	end component;	--! Entidad uf: sus siglas significan undidad funcional. La unidad funcional se encarga de realizar las diferentes operaciones vectoriales (producto cruz — producto punto). 
	
	component uf
	generic (
			use_std_logic_signed	: string := "NO";
			carry_logic	: string := "CLA"
	);
	port (
		opcode		: in std_logic;
		m0f0,m0f1,m1f0,m1f1,m2f0,m2f1,m3f0,m3f1,m4f0,m4f1,m5f0,m5f1 : in std_logic_vector(17 downto 0);
		cpx,cpy,cpz,dp0,dp1 : out std_logic_vector(31 downto 0);
			clk,rst		: in std_logic
	);
	end component;
		
	--! Entidad opcoder: opcoder decodifica la operaci—n que se va a realizar. Para tal fin coloca en la entrada de uf (unidad funcional), cuales van a ser los operandos de los multiplicadores con los que uf cuenta y adem‡s escribe en el selector de operaci—n de uf, el tipo de operaci—n a realizar.
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
	--! Esta entidad corresponde al multiplicador que se instanciar’a dentro de la unidad funcional. El multiplicador registra los operandos a la entrada y el respectivo producto de la multiplicaci—n a la salida. 
	component r_a18_b18_smul_c32_r
	generic (
		lpm_hint		: string := "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9";
		lpm_pipeline	: natural:= 2;
		lpm_representation : string:="SIGNED";
		lpm_type		: string:="LPM_MULT";
		lpm_widtha		: natural:=18;
		lpm_widthb		: natural:=18;
		lpm_widthp		: natural:=32
	);
	port (
		aclr,clock:in std_logic;
		dataa,datab:in std_logic_vector (17 downto 0);
		result: out std_logic_vector(31 downto 0)
	);
	end component;
	
	--! cla_logic_block corresponde a un bloque de l—gica Carry look Ahead. Se instancia y utiliza dentro de un sumador cualquiera, pues sirve para calcular los carry out de la operaci—n. 
	component cla_logic_block 
	generic ( width: integer:=4);
	port (
		p,g:in std_logic_vector(width-1 downto 0);
		cin:in std_logic;
		c:out std_logic_vector(width downto 1)
	);
	end component;
	
	--! rca_logic_block corresponde a un bloque de l—gica Ripple Carry Adder. Se instancia y utiliza dentro de un sumador cualquiera, pues sirve para calcular los carry out de la operaci—n.
	component rca_logic_block
	generic ( width : integer := 4);
	port (
		p,g: in std_logic_vector(width-1 downto 0);
		cin: in std_logic;
		c: out std_logic_vector(width downto 1)
	);
	end component;
	
	--! Entidad sumador. Esta entidad tiene un proposito bien claro: sumar. Es altamente parametrizable. Hay 3 cosas que se pueden parametrizar: el ancho del sumador, el tipo de circuito que queremos realice la suma y si el sumador estar‡ en capacidad de realizar mediante un selector restas.
	component adder
	generic ( 
		width 					: integer := 4;
		carry_logic				: string := "CLA";
		substractor_selector	: string := "YES"
	);
	port (
		a,b		:	in std_logic_vector (width-1 downto 0);
		s,ci	:	in	std_logic;
		result	:	out std_logic_vector (width-1 downto 0);
		cout	:	out std_logic
	);	 		
	end component;
	
	
	procedure hexwrite_0(l:inout line; h: in std_logic_vector);
	 	
end package; 

package body arithpack is
	--! Funciones utilitarias, relacionadas sobre todo con el testbench
	constant hexchars : string (1 to 16) := "0123456789ABCDEF";
	
	procedure hexwrite_0(l:inout line;h:in std_logic_vector) is
		variable index_high,index_low,acc : integer;
	begin 
		for i in (h'high)/4 downto 0 loop
			index_low:=i*4;
			if (index_low+3)>h'high then
				index_high := h'high;
			else
				index_high := i*4+3;
			end if;
			write(l,hexchars(1+ieee.std_logic_unsigned.conv_integer(h(index_high downto index_low))));
		end loop; 
	end procedure;	
end package body arithpack;
