library ieee;
use ieee.std_logic_1164.all;
use work.arithpack.all;
entity adder is 
	generic (
		w : integer := 9;
		carry_logic : string := "CLA";
		substractor_selector : string := "YES"
	);

	port (
		a,b	: in std_logic_vector(w-1 downto 0);
		s,ci	: in std_logic;
		result	: out std_logic_vector(w-1 downto 0);
		cout	: out std_logic	
	);
end adder;


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

		
