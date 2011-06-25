library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;




entity sadd2 is
	port (
		a,b:in std_logic_vector(25 downto 0);
		dpc:in std_logic;
		res:out std_logic_vector(25 downto 0)
	);
end entity;
architecture sadd2_arch of sadd2 is
begin
	process(a,b,dpc)
	begin
		if dpc='0' then
			res <= a+b;
		else
			res <= a-b;
		end if;
	end process;
end sadd2_arch;
