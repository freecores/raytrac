------------------------------------------------
--! @file
--! @brief Entidad top del Rt Engine \n Rt Engine's top hierarchy.
--------------------------------------------------


-- RAYTRAC
-- Author Julian Andres Guarin
-- raytrac.vhd
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
--     along with raytrac.  If not, see <http://www.gnu.org/licenses/>

--! Libreria de definicion de senales y tipos estandares, comportamiento de operadores aritmeticos y logicos.\n Signal and types definition library. This library also defines 
library ieee;
--! Paquete de definicion estandard de logica. Standard logic definition pack.
use ieee.std_logic_1164.all;

--! Se usaran en esta descripcion los componentes del package arithpack.vhd.\n It will be used in this description the components on the arithpack.vhd package. 
use work.arithpack.all;

--! La entidad raytrac es la top en la jerarquia de descripcion del Rt Engine.\n Raytrac entity is the top one on the Rt Engine description hierarchy.

--! RayTrac es basicamente una entidad que toma las entradas de cuatro vectores: A,B,C,D y las entradas opcode y addcode.
--! En el momento de la carga se llevaran a cabo las siguientes operaciones: \n
--! - Producto Cruz (opcode = 1):
--! - Cross Product (opcode = 1):
--! \n\n
--! \t Los resultados apareceran 3 clocks despues de la carga de los operadores y el codigo operacion
--! \n\n  
--! <table>
--! <tr>
--! <th></th>
--! <th></th><th>addcode=0</th><th></th>
--! </tr>
--! <tr>
--! <th>Opcode 1</th>
--! <td>CPX <= AxB<B> i</B></td>
--! <td>CPY <= AxB<B> j</B></td>
--! <td>CPZ <= AxB<B> k</B></td>
--! </tr>
--! </table>
--! \n
--! <table>
--! <tr>
--! <th></th>
--! <th></th><th>addcode=1</th><th></th>
--! </tr>
--! <tr>
--! <th>Opcode 1</th>
--! <td>CPX <= CxD<B> i</B></td>
--! <td>CPY <= CxD<B> j</B></td>
--! <td>CPZ <= CxD<B> k</B></td>
--! </tr>
--! </table>
--! \n
--! - Producto Punto (opcode = 0):
--! - Dot Product (opcode = 0):
--! \n\n
--! \t Los resultados se encontraran en DP0 y DP1 4 clocks despues de la carga.
--! \n\n 
--! <table>
--! <tr>
--! <th></th><th>addcode, ignorar</th> 
--! </tr>
--! <tr>
--! <th>opcode=0</th><td> DP0 = A.B, DP1 = C.D</td>
--! </tr>
--! </table>


entity raytrac is 
	generic (
		registered : string := "YES" --! Este parametro, por defecto "YES", indica si se registran o cargan en registros los vectores A,B,C,D y los codigos de operacion opcode y addcode en vez de ser conectados directamente al circuito combinatorio. \n This parameter, by default "YES", indicates if vectors A,B,C,D and operation code inputs opcode are to be loaded into a register at the beginning of the pipe rather than just connecting them to the operations decoder (opcoder). 
	);
	port (
		A,B,C,D 		: in std_logic_vector(18*3-1 downto 0); --! Vectores de entrada A,B,C,D, cada uno de tamano fijo: 3 componentes x 18 bits. \n Input vectors A,B,C,D, each one of fixed size: 3 components x 18 bits. 
		opcode,addcode	: in std_logic;							--! Opcode and addcode input bits, opcode selects what operation is going to perform one of the entities included in the design and addcode what operands are going to be involved in such. \n Opcode & addcode, opcode selecciona que operacion se va a llevar a cabo dentro de una de las entidades referenciadas dentro de la descripcion, mientras que addcode decide cuales van a ser los operandos que realizaran tal. 
		clk,rst,ena		: in std_logic;							--! Las senales de control usual. The usual control signals.
		CPX,CPY,CPZ,DP0,DP1 : out std_logic_vector(31 downto 0)	--! Salidas que representan los resultados del RayTrac: pueden ser dos resultados, de dos operaciones de producto punto, o un producto cruz. Por favor revisar el documento de especificacion del dispositivo para tener mas claridad.\n  Outputs representing the result of the RayTrac entity: can be the results of two parallel dot product operations or the result of a single cross product, in order to clarify refere to the entity specification documentation.
		
		
	);
end raytrac;

--! Arquitectura general del RayTrac. \n RayTrac general architecture.

--! La Arquitectura general de RayTrac se consiste en 3 componentes esenciales:
--! - Etapa de registros para la carga de los operadores y el codigo de operacion.
--! - Etapa combinatoria para la seleccion de operadores, dependiendo del codigo de operacion.
--! - Etapa aritmetica del calculo del producto punto o el producto cruz segun el caso.
--! \n\n
--! Las senales referidas en la arquitectura simplemente son conectores asignadas en la instanciaci&oacute;n de los componentes y en la asignacion entre ellas mismas en los procesos explicitos.
--! \n\n
--! RayTrac general architecture is made of 3 essential components: 
--! - Register stage to load operation code and operators.
--! - Combinatory Stage to operator selection, depending on the operation code.
--! - Arithmetic stage to calculate dot product or cross product, depending on the case.
--! \n\n 
--! Referred signals in the architecture are simple connectors assigned in the components intantiation and in the assignation among them in explicit processes.  
 

architecture raytrac_arch of raytrac is 
	signal SA,SB,SC,SD			: std_logic_vector(18*3-1 downto 0); --! Signal to register or bypass the vector inputs.  
	signal sopcode,saddcode		: std_logic;
	signal smf00,smf01,smf10,smf11,smf20,smf21,smf30,smf31,smf40,smf41,smf50,smf51	: std_logic_vector(17 downto 0);
	
begin

	reg:
	if registered="YES" generate

		--! By default: the inputs are going to be registered or loaded. This process describes how the register loading is to be make. \n Por defecto: las entradas se van a registrar o cargar. Este proceso describe como la carga de los registros con los valores de las entradas se va a realizar. 
		procReg:
		process(clk,rst)
		begin
			if rst=rstMasterValue then 
				SA <= (others => '0');
				SB <= (others => '0');
				SC <= (others => '0');
				SD <= (others => '0');
				sopcode <= '0';
				saddcode <= '0';
			elsif clk'event and clk='1' then
				if ena <= '1' then
					SA <= A;
					SB <= B;
					SC <= C;
					SD <= D;
					sopcode <= opcode;
					saddcode <= addcode;
				end if;
			end if;
		end process procReg;
	end generate reg;
	
	notreg:
	if registered="NO" generate 
		--! Just bypass or connect the inputs to the opcoder.
		procNotReg:
		process (A,B,C,D,opcode,addcode)
		begin
			SA <= A;
			SB <= B;
			SC <= C;
			SD <= D;
			sopcode <= opcode;
			saddcode <= addcode;
		end process procNotReg;
	end generate notreg;
	
	--! Instantiate Opcoder 
	opcdr : opcoder
	port map (
		SA(17 downto 0),SB(17 downto 0),SC(17 downto 0),SD(17 downto 0),SA(35 downto 18),SB(35 downto 18),SC(35 downto 18),SD(35 downto 18),SA(53 downto 36),SB(53 downto 36),SC(53 downto 36),SD(53 downto 36),
		smf00,smf01,smf10,smf11,smf20,smf21,smf30,smf31,smf40,smf41,smf50,smf51,
		sopcode,saddcode
	);
	--! Instantiate uf, cross product and dot product functional unit.
	uf0 : uf 
	port map (
		sopcode,
		smf00,smf01,smf10,smf11,smf20,smf21,smf30,smf31,smf40,smf41,smf50,smf51,
		CPX,CPY,CPZ,DP0,DP1,
		clk,rst
	);

end raytrac_arch;

		
		 