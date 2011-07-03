library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;




entity sqrt32 is 
	port (
		
		clk : in std_logic;
		rd32: in std_logic_vector(31 downto 0);
		
		sq32: out std_logic_vector(31 downto 0)
	);
end sqrt32;

architecture sqrt32_arch of sqrt32 is 

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
		widthad_a		: natural;
		width_a		: natural;
		width_byteena_a		: natural
	);
	port (
			clock0	: in std_logic ;
			address_a	: in std_logic_vector (9 downto 0);
			q_a	: out std_logic_vector (17 downto 0)
	);
	end component;

	signal s0nexp,s0uexp,s0e129,s0e1292	: std_logic_vector(30 downto 23);
	signal s0q				: std_logic_vector(17 downto 0);
begin
	
	altsyncram_component : altsyncram
	generic map (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "../../../MinGW/msys/1.0/home/julian/code/testbench/trunk/fpbranch/sqrt/memsqrt.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 1024,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		widthad_a => 10,
		width_a => 18,
		width_byteena_a => 1
	)
	port map (
		clock0 => clk,
		address_a => s0uexp(0)&s0umr(22 downto 14),
		q_a => s0q
	);
		--! SNAN?
	process (clk)
	begin
		if clk'event and clk='1' then
			
			--!Carga de Operando.
			s0sgn<=rd(31);
			s0uexp<=rd(30 downto 23);
			s0umr<=rd(22 downto 0);
			
			--! Etapa 0: Calcular direcci&oacute;n a partir del exponente y el exponente.
			sq32(31)<=s0sgn;
			sq32(22 downto 0)<=s0q(16 downto 0) & "000000";
			
		
		end if;
	end process;
	
	--! Combinatorial Gremlin: Etapa 0, calculo del exponente. 
	s0e129<=s0uexp+129;
	s0e1292<=s0uexp(s0uexp'high)&s0uexp(7 downto 1);

end sqrt32_arch;