library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity fadd32 is 
	port (
		a32,b32: in std_logic_vector(31 downto 0);
		dpc:in std_logic;
		c32:out std_logic_vector(31 downto 0);
	);
end fadd32;


architecture fadd32_arch of fadd32 is

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
	signal sdelta,expunrm,expnrm: std_logic_vector(7 downto 0);
	signal pha,phb : std_logic_vector(26 downto 0);
	signal sfactora,sfactorb,sfactor : std_logic_vector(8 downto 0);
	signal sma,smb,ssma,ssmb,usm,uxm: std_logic_vector(24 downto 0);
	signal ssm: std_logic_vector(25 downto 0);
	
	signal slaba,slabb : std_logic_vector(14 downto 0);
	signal shiftslab : std_logic_vector(23 downto 0);
	signal xplaces,splaces : std_logic_vector (4 downto 0);
	signal sign : std_logic;
	

begin 

	--! Manejo del cero
	i3e754zero:
	process (ea,eb)
	begin
		
		if ea="00" then
			signa <= '0';
		else
			signa <= signa;
		end if;
		if eb="00" then
			signb <= '0';
			expunrm <= ea;
		else
			signb <= signb;
			expunrm <= eb;
		end if;
		if ea=x"00" or eb=x"00" then
			zero='1';
			sdelta <= x"00";
		else
			zero='0';
			sdelta <= ea-eb;
		end if;
		
			
	end process;
	
	--! Manejo del Exponente, sumar el delta
	unrmexpo:
	process(expunrm,sdelta)
	begin
		expunrm <= expunrm+sdelta;
	end process;	
	

	--! Decodificar la magnitud del corrimiento
	denormshiftmagnitude:
	process (sdelta(7),sdelta(4 downto 0),signa,signb)
	begin
		for i in 4 downto 0 loop
			xplaces(i) <= sdelta(i) xor sdelta(7);
		end loop;
		splaces  <= xplaces+("0000"&sdelta(7));
		if sdelta(7)='1' then 
			shiftslab <= signa;--!b>a
			
		else 
			shiftslab <= signb;--!a>=b
		end if;
	end process;
	--! Decodificar el factor de corrimiento
	denormfactor:
	process (shiftslab,splaces)
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
	denomrselectmantissa2shift:
	process (sdelta(7),signa,signb)
	begin
		case sdelta(7) is 
			when '1' => -- Negativo b>a : se corre a delta espacios a la derecha y b se queda quieto
				sfactorb <= signb&"10000000";
				sfactora <= sfactor;
			when others => -- Positivo a>=b : se corre a delta espacios a la derecha y a se queda quieto
				sfactorb <= sfactor;
				sfactora <= signa&"10000000";
		end case;
		slaba <= (others => signa);
		slabb <= (others => signb);
	end process;
	

	
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
	mantissadenorm:
	process(pha,phb,slaba,slabb)
	begin
		sma <= pha(24 downto 0) + (slaba&pla(17 downto 8));
		smb <= phb(24 downto 0) + (slabb&plb(17 downto 8));
	end process;
	
	--! Sumar las mantissas signadas y colocar los 0's que hagan falta 
	mantissaadding:
	process (sdelta(7),sma,smb,splaces(4 downto 3),zero)
	begin
		
		case sdelta(7) is
			when '1' => -- Negativo b>a : se corre a delta espacios a la derecha y b se queda quieto 
				ssmb <= smb;
				case splaces(4 downto 3) is
					when x"3" => ssma <= (sma(24)&shiftslab(23 downto 0));
					when x"2" => ssma <= (sma(24)&shiftslab(15 downto 0)&sma(23 downto 16));
					when x"1" => ssma <= (sma(24)&shiftslab(7 downto 0)&sma(23 downto 8));
					when others => ssma <= sma;
				end case;
			when others => -- Positivo a>=b : se corre a delta espacios a la derecha y a se queda quieto
				ssma <= sma;
				case splaces(4 downto 3) is
					when x"3" => ssmb <= (smb(24)&shiftslab(23 downto 0));
					when x"2" => ssmb <= (smb(24)&shiftslab(15 downto 0)&smb(23 downto 16));
					when x"1" => ssmb <= (smb(24)&shiftslab(7 downto 0)&smb(23 downto 8));
					when others => ssmb <= smb;
				end case;
		end case;
		if zero='0' then
			ssm <= (ssma(24)&ssma)+(ssmb(24)&ssmb);			  
		else
			ssm <= (ssma(24)&ssma)or(ssmb(24)&ssmb);
		end if;
	end process;
	
	--! Mantissas sumadas, designar
	unsignmantissa:
	process(ssm)
	begin
		for i in 24 downto 0 loop
			usm(i) <= ssm(25) xor ssm(i);
		end loop;
		sign <= ssm(25);
		uxm <= usm+(x"000000"&sign); 		
	end process;
	
	--!Normalizar Mantissa y exponente
	process (uxm,expunrm)
		variable xshift : integer range 24 downto 0;
	begin
		for i in 24 downto 0 loop
			if uxm(i)='1' then
				xshift:=24-i;
			end of;
		end loop;			
		nplaces <= conv_std_logic_vector(xshift,5);
		expnrm <= expunrm-(("000"&nplaces)+x"ff");
	end process;	
	
	
		 	  
	

end fadd32_arch;







	