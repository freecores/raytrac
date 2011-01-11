library ieee;
use ieee.std_logic_1164.all;
use work.arithpack.all;

entity fastmux is 
	generic ( w : integer := 32 );
	port (
		s : in std_logic;
		mux0,mux1	: in std_logic_vector(w-1 downto 0);
		muxS		: out std_logic_vector(w-1 downto 0)
	);
end fastmux;

architecture fastmux_arch of fastmux is
begin

	muxS <= (mux0 and s) or (mux1 and s);

end fastmux_arch;


	