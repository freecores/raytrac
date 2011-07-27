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
	signal xplaces,s1udelta : std_logic_vector (4 downto 0);
	signal sign : std_logic;
	

begin 
	--! Pipeline
	pipeline:
	process(clk)
	begin
	
		if clk='1' and clk'event then
		
			--! Registro de entrada
		
			s0ea		<=	a32(30 downto 23);
			s0uma		<=	a32(22 downto 0);
			s0signa	<=	a32(31);
			s0eb		<=	b32(30 downto 23);
			s0umb		<=	b32(22 downto 0);
			s0signb	<=	a32(31) xor dpc;

			--! Etapa 0
			--! I3E754ZERO y calculo del delta entre exponentes	
			if s0ea="00" then
				s1signa <= '0';
			else
				s1signa <= s0signa;
			end if;
			if s0eb="00" then
				s1signb <= '0';
				s1expunrm <= s0ea;
			else
				s1signb <= s0signb;
				s1expunrm <= s0eb;
			end if;
			if s0ea=x"00" or s0eb=x"00" then
				s1zero='1';
				s1sdelta <= x"00";
			else
				s1zero='0';
				s1sdelta <= s0ea-s0eb;
			end if;
			--! Buffers
			s1uma		<=	s0uma;
			s1umb		<=	s0umb;
			
			
			--! Etapa 1
			--! Manejo de exponente, previo a la denormalizacion
			--! Calulo del Factor de corrimiento 
			s2expunrm	<= s1expunrm+s1sdelta;
			s2factor		<= s1factor;		
			
			--! Otras se&ntilde;ales de soporte
			s2signa		<= s1signa;
			s2signb		<= s1signb;
			s2bgta			<= s1sdelta(7);
			s2uma			<= s1uma;
			s2umb			<= s1umb;
			s2udelta		<= s1udelta(4 downto 3);
			s2zero			<= s1zero;
			
			
			--! Etapa 2 Realizar los corrimientos, denormalizacion parcial
			s3sma 			<= s2pha(24 downto 0) + (s2slaba&s2pla(17 downto 8));
			s3smb 			<= s2phb(24 downto 0) + (s2slabb&s2plb(17 downto 8));
			s3expnurm 	<= s2expnurm;
			s3zero			<= s2zero;
			s3bgta 		<= s2bgta;
			s3udelta 		<= s2udelta;
			
			--! Etapa 3, finalizar la denormalizacion y realizar la suma
			s4ssm			<= s3ssm;
			s4expnurm	<= s3expnurm;
			
			
			 
			
						
		end if;
	
	end process;
	
	
	--! Etapa 1
	--! Decodificar la magnitud del corrimiento
	denormshiftmagnitude:
	process (s1sdelta(7),s1sdelta(4 downto 0),s1signa,s1signb)
	begin
		for i in 4 downto 0 loop
			s1xdelta(i) <= s1sdelta(i) xor s1sdelta(7);
		end loop;
		s1udelta  <= s1xdelta+("0000"&s1sdelta(7));
		if s1sdelta(7) = '1' then 
			s1shiftslab	<=	(others=> s1signa);--!b>a
		else 
			s1shiftslab	<=	(others=> s1signb);--!a>=b
		end if;
	end process;
	--! Decodificar el factor de corrimiento
	denormfactor:
	process (s1shiftslab,s1udelta)
	begin
		case s1udelta(2 downto 0) is
			when x"0" => s1factor(8 downto 0) <= s1shiftslab(0 downto 0) & "10000000"; 
			when x"1" => s1factor(8 downto 0) <= s1shiftslab(1 downto 0) & "1000000";
			when x"2" => s1factor(8 downto 0) <= s1shiftslab(2 downto 0) & "100000";
			when x"3" => s1factor(8 downto 0) <= s1shiftslab(3 downto 0) & "10000";
			when x"4" => s1factor(8 downto 0) <= s1shiftslab(4 downto 0) & "1000";
			when x"5" => s1factor(8 downto 0) <= s1shiftslab(5 downto 0) & "100";
			when x"6" => s1factor(8 downto 0) <= s1shiftslab(6 downto 0) & "10";
			when others => s1factor(8 downto 0) <=s1shiftslab(7 downto 0) &"1";
		end case;
	end process;
	
	--! Etapa2
	--! Asignar el factor de corrimiento  las mantissas
	denomrselectmantissa2shift:
	process (s2bgta,s2signa,s2signb,s2factor)
	begin
		case s2bgta is 
			when '1' => -- Negativo b>a : se corre a delta espacios a la derecha y b se queda quieto
				s2factorb <= s2signb&"10000000";
				s2factora <= s2factor;
			when others => -- Positivo a>=b : se corre a delta espacios a la derecha y a se queda quieto
				s2factorb <= s2factor;
				s2factora <= s2signa&"10000000";
		end case;
		
	end process;
	

	
	--! Correr las mantissas y calcularlas.
	hmulta: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","SIGNED","LPM_MULT",9,18,27)
	port	map (s2factora,s2signa&'1'&s2data24a(22 downto 0),s2pha);
	lmulta: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","SIGNED","LPM_MULT",9,9,27)
	port	map (s2factora,s2signa&'1'&s2dataa(6 downto 0),s2pla);
	hmultb: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","SIGNED","LPM_MULT",9,18,27)
	port	map (s2factorb,s2signb&'1'&s2datab(22 downto 0),s2phb);
	lmultb: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","SIGNED","LPM_MULT",9,9,27)
	port	map (s2factorb,s2signb&'1'&s2datab(6 downto 0),s2plb);
	mantissadenormslabcalc:
	process(s2signa,s2signb)
	begin
		s2slaba <= (others => s2signa);
		s2slabb <= (others => s2signb);
	end process;
	
	--! Sumar las mantissas signadas y colocar los 0's que hagan falta 
	mantissaadding:
	process (s3bgta,s3sma,s3smb,s3udelta,zero)
	begin
		
		case s3bgta is
			when '1' => -- Negativo b>a : se corre a delta espacios a la derecha y b se queda quieto 
				s3ssmb <= s3smb;
				s3shiftslab(23 downto 0)<=(others=>s3sma(24));
				case s3udelta is
					when x"3" => s3ssma <= (s3sma(24)&s3shiftslab(23 downto 0));
					when x"2" => s3ssma <= (s3sma(24)&s3shiftslab(15 downto 0)&s3sma(23 downto 16));
					when x"1" => s3ssma <= (s3sma(24)&s3shiftslab(7 downto 0)&s3sma(23 downto 8));
					when others => s3ssma <= s3sma;
				end case;
			when others => -- Positivo a>=b : se corre a delta espacios a la derecha y a se queda quieto
				s3ssma <= s3sma;
				shiftslab(23 downto 0)<=(others=>s3smb(24));
				case s3udelta is
					when x"3" => s3ssmb <= (s3smb(24)&s3shiftslab(23 downto 0));
					when x"2" => s3ssmb <= (s3smb(24)&s3shiftslab(15 downto 0)&s3smb(23 downto 16));
					when x"1" => s3ssmb <= (s3smb(24)&s3shiftslab(7 downto 0)&s3smb(23 downto 8));
					when others => s3ssmb <= s3smb;
				end case;
		end case;
		if s3zero='0' then
			s3ssm <= (s3ssma(24)&s3ssma)+(s3ssmb(24)&s3ssmb);			  
		else
			s3ssm <= (s3ssma(24)&s3ssma)or(s3ssmb(24)&s3ssmb);
		end if;
	end process;
	
	--! Mantissas sumadas, designar
	unsignmantissa:
	process(s4ssm)
	begin
		for i in 24 downto 0 loop
			s4usm(i) <= s4ssm(25) xor s4ssm(i);
		end loop;
		s4sign <=s4ssm(25);
		s4uxm <= s4usm+(x"000000"&s4ssm(25)); 		
	end process;
	
	--!Normalizar el  exponente y calcular el factor de corrimiento para la normalizaci&oacute;n de la mantissa
	process (s4uxm,expunrm)
		variable xshift : integer range 24 downto 0;
	begin
		for i in 24 downto 0 loop
			if s4uxm(i)='1' then
				xshift:=24-i;
			end of;
		end loop;			
		s4expnrm <= s4expunrm-((  "000"&conv_std_logic_vector(xshift,5) )+x"ff");
	end process;	
	
	normantissafactor:
	process (s4expnrm)
	begin
		s4factor(0)<=s4expnrm(7);
		case s4expnrm(7) is
			when '1' => s4factor(8 downto 1)<=(others=>'0');
			when others =>
				case s4expnrm(3 downto 1) is
					when "000" => s4factor(8 downto 1)<="'00000001";
					when "001" => s4factor(8 downto 1)<="'00000010";
					when "010" => s4factor(8 downto 1)<="'00000100";
					when "011" => s4factor(8 downto 1)<="'00001000";
					when "100" => s4factor(8 downto 1)<="'00010000";
					when "101" => s4factor(8 downto 1)<="'00100000";
					when "110" => s4factor(8 downto 1)<="'01000000";
					when others  => s4factor(8 downto 1)<="'10000000";
				end case;
		end case;	 
	end process;
	
		 	  
	

end fadd32_arch;







	