library ieee;
use ieee.std_logic_1164.all;

entity cla_logic_block is
	generic (
		w : integer := 4
	);

	port (
		p,g : in std_logic_vector(w-1 downto 0);
		cin : in std_logic;
		
		c : out std_logic_vector(w downto 1)
	);
end cla_logic_block;


architecture cla_logic_block_arch of cla_logic_block is

	

begin

	claProc:	-- claProc instancia funciones combinatorias en las variables iCarry,
			-- pero notese que los valores de iCarry(i) no dependen jamas de iCarry(i-1) a diferencia de rcaProc
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

