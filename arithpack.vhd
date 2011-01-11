library ieee;
use ieee.std_logic_1164.all;

package arithpack is
	component fastmux
	generic ( w : integer := 32 );
	port ( 
		s : in std_logic;
		mux0,mux1 : in std_logic_vector (w-1 downto 0);
		muxS : out std_logic_vector (w-1 downto 0)
	);
	
	component r_a18_b18_smul_c32_r
	port (
		aclr,clock:in std_logic;
		dataa,datab:in std_logic_vector (17 downto 0);
		result: out std_logic_vector(31 downto 0)
	);
	end component;
	component cla_logic_block 
	generic ( w: integer:=4);
	port (
		p,g:in std_logic_vector(w-1 downto 0);
		cin:in std_logic;
		c:out std_logic_vector(w downto 1)
	);
	end component;
	component rca_logic_block
	generic ( w : integer := 4);
	port (
		p,g: in std_logic_vector(w-1 downto 0);
		cin: in std_logic;
		c: out std_logic_vector(w downto 1)
	);
	end component;
	component adder
	generic ( 
		w : ingeter := 4;
		carry_logic := "CLA";
		subtractor_selector := "YES";
	);
	port (
		a,b		:	in std_logic_vector (w-1 downto 0);
		s,ci	:	in	std_logic;
		result	:	out std_logic_vector (w-1 downto 0);
		cout	:	out std_logic
	);	 		
	end component;
		
end package; 
