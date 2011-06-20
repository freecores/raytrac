library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;


entity ema2 is 
	port (
		clk			: in std_logic;
		a32,b32		: in std_logic_vector (31 downto 0);
		exp			: out std_logic_vector (7 downto 0);
		sma,smb		: out std_logic_vector (24 downto 0)
		
						
	
	);
end ema2;

architecture ema2_arch of ema2 is
	signal sa,sb,ssa,ssb,sssa,sssb,s4a		: std_logic_vector(31 downto 0);
	signal s4umb							: std_logic_vector(23 downto 0);
	signal s4sma,s4smb						: std_logic_vector(24 downto 0);								
	signal s4sgb							: std_logic; 
begin

	process (clk)
	begin
		if clk'event and clk='1' then 
		
			--!Registro de entrada
			sa <= a32;
			sb <= b32;

			--!Primera etapa a vs. b
			if sa(30 downto 23) >= sb (30 downto 23) then
				--!signo,exponente,mantissa
				ssb(31) <= sb(31);
				ssb(30 downto 23) <= sa(30 downto 23)-sb(30 downto 23);
				ssb(22 downto 0) <= sb(22 downto 0);
				--!clasifica a
				ssa <= sa;
			else
				--!signo,exponente,mantissa
				ssb(31) <= sa(31);
				ssb(30 downto 23) <= sb(30 downto 23)-sa(30 downto 23);
				ssb(22 downto 0) <= sa(22 downto 0);
				--!clasifica b
				ssa <= sb;
			end if;
			
			--! Tercera etapa corrimiento y normalizaci&oacute;n de mantissas  
			s4a <= ssa;
			s4sgb <= ssb(31);
			s4umb <= shr('1'&ssb(22 downto 0),ssb(30 downto 23));
			
			--! Cuarta etapa signar la mantissa y entregar el exponente.
			sma <= s4sma + s4a(31);
			smb <= s4smb + s4sgb;
			exp <= s4a(30 downto 23);
		end if;
	end process;
	--! Combinatorial Gremlin
	
	--!Signar b y c
	signbc:
	for i in 23 downto 0 generate
		s4smb(i) <= s4sgb xor s4umb(i);
	end generate;
	s4smb(24) <= s4sgb;
	
	--!Signar a
	signa:
	for i in 22 downto 0 generate
		s4sma(i) <= s4a(31) xor s4a(i);
	end generate;
	s4sma(23) <= not(s4a(31));
	s4sma(24) <= s4a(31);	
	
	
end ema2_arch;

		