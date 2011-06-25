library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;




entity sadd3 is
	port (
		a,b,c:in std_logic_vector(26 downto 0);
		dpc:in std_logic;
		res:out std_logic_vector(26 downto 0)
	);
end entity;
architecture sadd3_arch of sadd3 is
begin
	process(a,b,c,dpc)
	begin
		if dpc='0' then
			res <= a+b+c;
		else
			res <= a-b;
		end if;
	end process;
end sadd3_arch;