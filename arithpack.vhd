library ieee;
use ieee.std_logic_1164.all;




package arithpack is
	
	constant rstMasterValue : std_logic := '0';

	component uf
	port (
		opcode		: in std_logic;
		m0f0,m0f1,m1f0m1f1,m2f0,m2f1,m3f0,m3f1,m4f0,m4f1,m5f0,m5f1 : in std_logic_vector(17 downto 0);
		cpx,cpy,cpz,dp0,dp1 : out std_logic_vector(31 downto 0)
		clk,rst		: in std_logic
	);
	end component;
		
	component opcoder 
	port (
		Ax,Bx,Cx,Dx,Ay,By,Cy,Dy,Az,Bz,Cz,Dz : in std_logic_vector (17 downto 0);
		m0f0,m0f1,m1f0m1f1,m2f0,m2f1,m3f0,m3f1,m4f0,m4f1,m5f0,m5f1 : out std_logic_vector (17 downto 0);
		opcode,addcode : in std_logic
	);
	end component;

	
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
		w : integer := 4;
		carry_logic := "CLA";
		substractor_selector := "YES";
	);
	port (
		a,b		:	in std_logic_vector (w-1 downto 0);
		s,ci	:	in	std_logic;
		result	:	out std_logic_vector (w-1 downto 0);
		cout	:	out std_logic
	);	 		
	end component;
		
end package; 
