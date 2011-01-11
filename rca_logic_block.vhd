library ieee;
use ieee.std_logic_1164.all;

entity rca_logic_block is
	generic (
		w : integer := 8
	);
	port (
		p,g: in std_logic_vector(w-1 downto 0);
		cin : in std_logic;
		
		c : out std_logic_vector(w downto 1)
	);
end rca_logic_block;


architecture rca_logic_block_arch of rca_logic_block is

	

begin

	rcaProc:		-- rcaProc instancia funciones combinatorias en sCarry(i) haciendo uso de los resultados intermedios obtenidos
				-- en sCarry(i-1), por lo que se crea un delay path en el calculo del Cout del circuito
	process (p,g,cin)
		variable i:			integer range 0 to 2*w;
		variable sCarry:	std_logic_vector(w downto 1);
	begin
		
		sCarry(w downto 1) := g(w-1 downto 0);
		sCarry(1) := sCarry(1) or (p(0) and cin);
		 
		for i in 1 to w-1 loop
			sCarry(i+1) := sCarry(i+1) or (p(i) and sCarry(i));
		end loop;

		c <= sCarry;  
		

	end process rcaProc;
end rca_logic_block_arch;
