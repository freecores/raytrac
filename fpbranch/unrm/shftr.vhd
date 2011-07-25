library ieee;
use ieee.std_logic_1164.all;



entity shftr is 
	port (
		sgndelta,signa,sgnb		: in std_logic;
		places	: in std_logic_vector (4 downto 0);
		data24a,data24b	: in std_logic_vector (22 downto 0);
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
	
	signal pha,phb : std_logic_vector(26 downto 0);
	signal sfactora,sfactorb,sfactor : std_logic_vector(8 downto 0);
	signal sma,smb,ssma,ssmb,ssm : std_logic_vector(24 downto 0);
	signal slaba,slabb : std_logic_vector(14 downto 0);
	signal shiftslab : std_logic_vector(23 downto 0);
	signal xplaces,splaces : std_logic_vector (4 downto 0);

begin 

	--! Decodificar la magnitud del corrimiento
	process (sgndelta,places,signa,signb)
	begin
		for i in 4 downto 0 loop
			xplaces(i) <= places(i) xor sgndelta;
		end loop;
		splaces  <= xplaces+("0000"&sgndelta);
		if sgndelta='1' then
			shiftslab <= signa;
		else
			shiftslab <= signb;
		end if;
	end process;
	--! Decodificar el factor de corrimiento
	process (shftslab,splaces)
	begin
		case splaces(2 downto 0) is
			when x"0" => sfactor(8 downto 0) <= shiftslab(0 downto 0) & "10000000"; 
			when x"1" => sfactor(8 downto 0) <= shiftslab(1 downto 0) & "1000000";
			when x"2" => sfactor(8 downto 0) <= shiftslab(2 downto 0) & "100000";
			when x"3" => sfactor(8 downto 0) <= shiftslab(3 downto 0) & "10000";
			when x"4" => sfactor(8 downto 0) <= shiftslab(4 downto 0) & "1000";
			when x"5" => sfactor(8 downto 0) <= shiftslab(5 downto 0) & "100";
			when x"6" => sfactor(8 downto 0) <= shiftslab(6 downto 0) & "10";
			when others => sfactor(8 downto 0) <=shiftslab(7 downto 0) &"1";
		end case;
	end process;
	--! Asignar el factor de corrimiento  las mantissas
	process (sgndelta,signa,signb)
	begin
		
		
	
		case sgndelta is 
			when '1' => -- Negativo b>a : se corre a delta espacios a la derecha y b se queda quieto
				sfactorb <= signb&"10000000";
				sfactora <= sfactor;
			when others => -- Positivo a>=b : se corre a delta espacios a la derecha y a se queda quieto
				sfactorb <= sfactor;
				sfactora <= signa&"10000000";
		end case;
		
		slaba <= (others => signa);
		slabb <= (others => signb);
		
		
	end process
	

	
	--! Correr las mantissas y calcularlas.

	hmulta: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","SIGNED","LPM_MULT",9,18,27)
	port	map (sfactora,signa&'1'&data24a(22 downto 0),pha);
	lmulta: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","SIGNED","LPM_MULT",9,9,27)
	port	map (sfactora,signa&'1'&data24a(6 downto 0),pla);
	hmultb: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","SIGNED","LPM_MULT",9,18,27)
	port	map (sfactorb,signb&'1'&data24b(22 downto 0),phb);
	lmultb: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","SIGNED","LPM_MULT",9,9,27)
	port	map (sfactorb,signb&'1'&data24b(6 downto 0),plb);
	
	sma <= pha(24 downto 0) + (slaba&pla(17 downto 8));
	smb <= phb(24 downto 0) + (slabb&plb(17 downto 8));
	
	--! Sumar las mantissas signadas y colocar los 0's que hagan falta 
	process (sgndelta,sma,smb,splaces(4 downto 3))
	begin
		splaces <= places+sgndelta;
		
		case sgndelta is
			when '1' => -- Negativo b>a : se corre a delta espacios a la derecha y b se queda quieto 
				ssmb <= smb;
				case splaces(4 downto 3) is
					when x"3" => ssma <= (sma(24)&shiftslab(23 downto 0));
					when x"2" => ssma <= (sma(24)&shiftslab(15 downto 0)&sma(23 downto 16));
					when x"1" => ssma <= (sma(24)&shiftslab(7 downto 0)&sma(23 downto 8));
					when others => ssma <= sma;
				end case;
			when others => -- Positivo a>=b : se corre a delta espacios a la derecha y a se queda quieto
				case splaces(4 downto 3) is
					when x"3" => ssmb <= (smb(24)&shiftslab(23 downto 0));
					when x"2" => ssmb <= (smb(24)&shiftslab(15 downto 0)&smb(23 downto 16));
					when x"1" => ssmb <= (smb(24)&shiftslab(7 downto 0)&smb(23 downto 8));
					when others => ssmb <= smb;
				end case;
		end case;
		ssm <= ssma+ssmb;			  
	
	end process;
	
	--! Mantissas sumadas, denormalizar
	
		 	  
	

end shftr_arch;







