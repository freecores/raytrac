--! Operar la mantissa y normalizar a ieee 754, float32
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;

entity add3 is
	port (
		clk,dpc		: in std_logic;
		exp 		: in std_logic_vector(7 downto 0);
		sma,smb,smc	: in std_logic_vector (24 downto 0);
		res32		: out std_logic_vector(31 downto 0)
	);
end add3;

architecture add3_arch of add3 is
	signal s0exp,s1exp,s2exp,s2expnrmr,s2expnrml,s3expnrmr,s3expnrml,s3exp 	: std_logic_vector(7 downto 0);
	signal s0sma,s0smb,s0smc,s1res,s2res,s2resnrmr,s2resnrml				: std_logic_vector(26 downto 0);
	signal s3resnrml,s3resnrmr,s3smant,s3umant								: std_logic_vector(22 downto 0);
	signal s3sign,s1rsl,s2rsl,s3rsl											: std_logic;
	signal s1rshift,s2rshift												: std_logic_vector(1 downto 0);
	signal s1lshift,s2lshift												: std_logic_vector(4 downto 0);	
	
	
begin
	--! formato ieee 754
	res32(31) <= s3sign;
	res32(30 downto 23) <= s3exp;
	res32(22 downto 0) <= s3umant+s3sign;
			
	
	process (clk)
	begin
	
		if clk'event and clk='1' then
			--! etapa de registro de entradas
			s0sma(24 downto 0) <= sma;
			s0smb(24 downto 0) <= smb;
			s0smc(24 downto 0) <= smc;
			s0exp <= exp;
			
			--! etapa 0 suma
			if dpc='0' then
				s1res <= s0sma+s0smb+s0smc;
			else
				s1res <= s0sma-s0smb;
			end if;
			s1exp <= s0exp;
			
			--! etapa 1 codficar el corrimeinto
			s2exp <= s1exp;
			s2rshift <= s1rshift;
			s2lshift <= s1lshift; 		
			s2rsl <= s1rsl;
			s2res <= s1res;
			
			--! etapa 2 normalizar la mantissa y el exponente
			s3sign <= s2res(26);
			s3rsl <= s2rsl;
			s3resnrmr <= s2resnrmr(22 downto 0);
			s3resnrml <= s2resnrml(22 downto 0);
			s3expnrml <= s2expnrml;
			s3expnrmr <= s2expnrmr;
			
		
			
			
		end if;
	
	end process;
	
	s0sma(26 downto 25) <= s0sma(24)&s0sma(24);
	s0smb(26 downto 25) <= s0smb(24)&s0smb(24);
	s0smc(26 downto 25) <= s0smc(24)&s0smc(24);
	
	
	
	process (s1res(26 downto 23))
	begin
		s1rsl <= (s1res(26) xor s1res(25)) or (s1res(26) xor s1res(24)) or (s1res(26) xor s1res(23));
	end process;
	
	process (s1res)
		variable rshift : integer range 2 downto 0;
		variable lshift : integer range 23 downto 1; 
	begin
		lshift:=1;
		for i in 2 downto 0 loop
			rshift:=i; 
			exit when (s1res(26) xor s1res(23+i))='1';
		end loop;
		for i in 22 downto 0 loop
			exit when (s1res(26) xor s1res(i))='1';
			lshift:=lshift+1;
		end loop;
		
		s1rshift <= conv_std_logic_vector(rshift,2);
		s1lshift <= conv_std_logic_vector(lshift,5);
		
	end process;
	
	process(s2exp,s2res,s2rshift,s2lshift)
	begin
		
		s2resnrmr <= shr(s2res,s2rshift);
		s2resnrml <= shl(s2res,s2lshift);
		s2expnrml <= s2exp-s2lshift;
		s2expnrmr <= s2exp+s2rshift;
		 
	end process;
	
	process (s3rsl,s3resnrmr,s3resnrml,s3expnrmr,s3expnrml,s3sign,s3smant)
	begin 
		if s3rsl='1' then 
			s3smant <= s3resnrmr;
			s3exp <= s3expnrmr;
		else
			s3smant <= s3resnrml;
			s3exp <= s3expnrml;
		end if;		
	end process;
	umantissa:
	for i in 22 downto 0 generate
		s3umant(i) <= s3sign xor s3smant(i); 
	end generate;
	
	
end add3_arch;
	