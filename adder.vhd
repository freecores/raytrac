--! @file adder.vhd
--! @brief Sumador parametrizable.  


--! Libreria de definicion de senales y tipos estandares, comportamiento de operadores aritmeticos y logicos.\n Signal and types definition library. This library also defines 
library ieee;
--! Paquete de definicion estandard de logica. Standard logic definition pack.
use ieee.std_logic_1164.all;
--! Se usaran en esta descripcion los componentes del package arithpack.vhd.\n It will be used in this description the components on the arithpack.vhd package. 
use work.arithpack.all;

--! Sumador parametrizable.

--! La entidad es un sumador parametrizable. Las características parametrizables son el ancho de los sumandos, si se usa un circuito ripple carry adder y si se sintetiza una compuerta xor en la entrada que permita la selección de la operación a realizar (suma o resta).
--! Las entradas y las salidas son las usuales de un sumador: a y b los sumandos, ci el carry de entrada, cout el carry de salida y el valor de la suma en result. Adicionalmente si se selecciona el parametro substractor_selector como "YES" entonces la entrada s, servirá para seleccionar si el sumador realizará la operacion A+B (s=0) ó A-B (s=0). Finalmente la siguiente tabla sintetiza el comportamiento de la entidad.
--! \n\n
--! <table>
--! <tr><th>substractor_selector</th><th>S</th><th>Operación ejecutada</th></tr> <tr><td>"YES"</td><td>0</td><td>A+B</td></tr> --! <tr><td>"YES"</td><td>1</td><td>A-B</td></tr> <tr><td>Otro valor.</td><td>n/a</td><td>A+B</td></tr></table>

--! El circuito es combinatorio puro y la propagación de las señales hasta el resultado del ultimo carry tiene un tiempo, el cual debe ser considerado para implementar posteriores etapas de pipe en caso de ser necesario.   
entity adder is 
	generic (
		w : integer := 9;	--! Ancho de los sumandos
		carry_logic : string := "CLA";			--! Carry logic, seleccione "CLA" para Carry Look Ahead ó "RCA" para Ripple Carry Adder. 
		substractor_selector : string := "YES" 	--! Al seleccionar este parametro en "YES" se puede usar el sumador para restar a través de la señal s.
	);

	port (
		a,b	: in std_logic_vector(w-1 downto 0);	--! Sumandos
		s	: in std_logic;							--! Selector Suma / Resta
		ci	: in std_logic;							--! Datos Carry In.								 
		result	: out std_logic_vector(w-1 downto 0);--! Resultado de la suma.
		cout	: out std_logic						--! Carry out (Overflow).
	);
end adder;
--! Arquitectura del sumador parametrizable.

--! Si se configura el sumador para que s seleccione si se va a realizar una suma ó una resta, entonces se instanciara para cada bit de la entrada a, una compuerta xor. Por cada bit del operando a se realizará la operación lógica ai xor s. El resultado se almacena en la señal sa. Si por el contrario el sumador está configurado para ignorar el selector s, entonces la señal sa se conecta directamente a la entrada a. 

architecture adder_arch of adder is 

	signal sa,p,g:	std_logic_vector(w-1 downto 0);
	signal sCarry:	std_logic_vector(w downto 1); 
	

begin 
	-- Usual Structural Model / wether or not CLA/RCA is used and wether or not add/sub selector is used, this port is always instanced --
	
	result(0)<= a(0) xor b(0) xor ci;
	wide_adder:
	if (w>1) generate
		wide_adder_generate_loop:
		for i in 1 to w-1 generate
			result(i) <= a(i) xor b(i) xor sCarry(i);
		end generate wide_adder_generate_loop;
	end generate wide_adder;
	cout <= sCarry(w);    
	g<= sa and b;
	p<= sa or b;
	
	
	-- Conditional Instantiation / Adder Substraction Logic --
	
	adder_sub_logic :	-- adder substractor logic
	if substractor_selector = "YES" generate
		a_xor_s: 
		for i in 0 to w-1 generate
			sa(i) <= a(i) xor s;
		end generate a_xor_s;
	end generate adder_sub_Logic;
		
	add_logic:	-- just adder.
	if substractor_selector = "NO" generate
		sa <= a;
	end generate add_logic;
	


	-- Conditional Instantiation / RCA/CLA Logical Blocks Generation --
	rca_logic_block_instancing:	-- Ripple Carry Adder
	if carry_logic="RCA" generate
		--! Generar un bloque de cálculo de Carry, Ripple Carry Adder. carry_logic = "RCA". 
		rca_x: rca_logic_block 
		generic map (w=>w)
		port map (
			p=>p,
			g=>g,
			cin=>ci,
			c=>sCarry
		);
	end generate rca_logic_block_instancing;
	
	cla_logic_block_instancing:	-- Carry Lookahead Adder
	if carry_logic="CLA" generate
		--! Generar un bloque de cálculo de Carry, Carry Look Ahead. carry_logic = "CLA".
		cla_x: cla_logic_block
		generic map (w=>w)
		port map (
			p=>p,
			g=>g,
			cin=>ci,
			c=>sCarry
		);
	end generate cla_logic_block_instancing;

end adder_arch;

		
