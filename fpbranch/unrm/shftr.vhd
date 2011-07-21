library ieee;
use ieee.std_logic_1164.all;



entity shftr is 
	port (
		dir		: in std_logic;
		places	: in std_logic_vector (3 downto 0);
		data24	: in std_logic_vector (23 downto 0);
		data40	: out std_logic_vector (39 downto 0)
	);
end shftr;


architecture shftr_arch of shftr is

	component lpm_mult 
	generic (
		lpm_hint			: string;
		lpm_representation	: string;
		lpm_type			: string;
		lpm_widtha			: natural;
		lpm_widthb			: natural;
		lpm_widthp			: natural
	);
	port (
		dataa	: in std_logic_vector ( lpm_widtha-1 downto 0 );
		datab	: in std_logic_vector ( lpm_widthb-1 downto 0 );
		result	: out std_logic_vector( lpm_widthp-1 downto 0 )
	);
	end component;
	
	signal splaces	: std_logic_vector (8 downto 0);
	signal sdata24	: std_logic_vector (26 downto 0);
	signal sdata32	: std_logic_vector (31 downto 0);
	signal sresult	: std_logic_vector (53 downto 0);	

begin 

	process (places(2 downto 0))
	begin
		case places(2 downto 0) is
			when "000" => splaces <= "000000001";
			when "001" => splaces <= "000000010";
			when "010" => splaces <= "000000100";
			when "011" => splaces <= "000001000";
			when "100" => splaces <= "000010000";
			when "101" => splaces <= "000100000";
			when "110" => splaces <= "001000000";
			when others => splaces <="010000000";
		end case;
	end process;
	sdata24(26 downto 24) <= (others => '0');
	process (dir,data24,sdata32)
		variable offset : integer;
	begin
		
		if places(3) ='1' then
			offset:=8;
		else
			offset:=0;
		end if;
		
		data40 <= (others => '0');
		
		if dir='1' then --! Corrimiento a la derecha
			for i in 23 downto 0 loop
				sdata24(i) <= data24(23-i);
			end loop;
			for i in 31 downto 0 loop
				data40(i+8-offset)  <= sdata32(31-i);
			end loop;
		else
			sdata24(23 downto 0)	<= data24;
			for i in 31 downto 0 loop  
				data40(i+offset) 	<= sdata32(i);
			end loop;
		end if;			
	end process;
	
	the_shifter: 
	for i in 2 downto 0 generate
		shiftermultiplier: lpm_mult
		generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
		port	map (splaces,sdata24(i*9+8 downto i*9),sresult(i*18+17 downto i*18));
	end generate;
	
	sdata32(31 downto 27) <= sresult(49 downto 45);
	sdata32(26 downto 18) <= sresult(44 downto 36) or sresult(35 downto 27);
	sdata32(17 downto 09) <= sresult(26 downto 18) or sresult(17 downto 09);
	sdata32(08 downto 00) <= sresult(08 downto 00);
	 	  
	

end shftr_arch;







