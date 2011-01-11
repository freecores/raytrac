library ieee;
use ieee.std_logic_1164.all;
use work.arithpack.all;

-- 


entity uf is 
	port (
		opcode	: in std_logic;
		vectors	: in std_logic_vector (12*18-1 downto 0);
		clk,rst, ena : in std_logic
	);
end uf;

architecture uf_arch of uf is 

	s0_opcode : signal std_logic;
	
	s1_opcode: signal std_logic;
	
	s2_opcode : signal std_logic;
	s2_prod0,s2_prod1,s2_prod2,s2_prod3,s2_prod4,s2_prod5,s2_sum0,s2_sum1,s2_sum2 : signal std_logic_vector (31 downto 0); 
	
	s3_sum04,s3_sum25,s3_prod2,s3_prod3,s3_sum4,s3_sum5 : signal std_logic_vector ( 31 downto 0);
	
	
begin

	



end uf_arch;
