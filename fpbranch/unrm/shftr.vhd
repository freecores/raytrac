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

--! ******************************************************************************************************************************
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
			s2factor	<= s1factor;		
			
			--! Otras se&ntilde;ales de soporte
			s2signa		<= s1signa;
			s2signb		<= s1signb;
			s2bgta		<= s1sdelta(7);
			s2uma		<= s1uma;
			s2umb		<= s1umb;
			s2udelta	<= s1udelta(4 downto 3);
			s2zero		<= s1zero;
			
			
			--! Etapa 2 Realizar los corrimientos, denormalizacion parcial
			s2asm0		<= (s2xorslab(23)&(('1'&s2um0(22 downto 0))xor(s2xorslab)))+(x"000000"&s2xorslab(23));
			case s2udelta is
				when "00" => 
					s2aum1(23 downto 06) 	<= s2psh(25 downto 08);
					s2aum1(05 downto 00)	<= s2psh(07 downto 02) or (s2psl(16 downto 11));
				when "01" => 
					s2aum1(23 downto 06) 	<= x"00"&s2psh(25 downto 17);
					s2aum1(05 downto 00)	<= s2sph(16 downto 11);
				when "10" =>
					s2aum1(23 downto 06) 	<= x"0000"&s2psh(25);
					s2aum1(05 downto 00)	<= s2sph(24 downto 19);
				when others => 
					s2aum1 					<= (others => '0');
			end case; 	
			s2asign		<= (s2bgta and s2signa) or (not(s2bgta) and s2signb); 
				
				
			end case;				
			s2aexpnurm 	<= s2expnurm;
			s2azero		<= s2zero;
			s2abgta 	<= s2bgta;
			s2audelta 	<= s2udelta;
			--! Etapa 2 Realizar los corrimientos, denormalizacion parcial
			s3sma 		<= s2pha(24 downto 0) + (s2slaba&s2pla(17 downto 8));
			s3smb 		<= s2phb(24 downto 0) + (s2slabb&s2plb(17 downto 8));
			s3expnurm 	<= s2expnurm;
			s3zero		<= s2zero;
			s3bgta 		<= s2bgta;
			s3udelta 	<= s2udelta;
			
			--! Etapa 3, finalizar la denormalizacion y realizar la suma
			s4ssm		<= s3ssm;
			s4expnurm	<= s3expnurm;
		end if;
	end process;
	
--! ******************************************************************************************************************************
	
	--! Etapa 1
	--! Decodificar la magnitud del corrimiento
	unsigneddelta: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","SIGNED","LPM_MULT",9,9,27)
	port	map (s1sdelta(7)&x"80",s1sdelta(7)&s1sdelta,s1pudelta);
	s1udelta(4 downto 0) <= s1pudelta(11 downto 7);
	denormshiftmagnitude:
	--! Decodificar el factor de corrimiento
	denormfactor:
	process (s1shiftslab,s1udelta)
	begin
		s1factor(8 downto 0) <= (others => s1sdelta(7));
		case s1udelta(2 downto 0) is
			when x"0" => s1factor(8 downto 0) 	<= "100000000"; 
			when x"1" => s1factor(8 downto 0) 	<= "010000000";
			when x"2" => s1factor(8 downto 0) 	<= "001000000";
			when x"3" => s1factor(8 downto 0) 	<= "000100000";
			when x"4" => s1factor(8 downto 0) 	<= "000010000";
			when x"5" => s1factor(8 downto 0) 	<= "000001000";
			when x"6" => s1factor(8 downto 0) 	<= "000000100";
			when others => s1factor(0) 			<= "000000010";
		end case;
 	end process;
--! ******************************************************************************************************************************
	--! Etapa2
	--! Correr las mantissas
	denomrselectmantissa2shift:
	process (s2bgta,s2signa,s2signb,s2factor,s2sma,s2smb)
	begin
		
		case s2bgta is 
			when '1' => -- Negativo b>a : se corre a delta espacios a la derecha y b se queda quieto
				s2factorshift	<= s2factor;
				s2um0			<= s2umb;
				s2smshift		<= s2uma;
				s2xorslab		<= (others => s2signb);
			when others => -- Positivo a>=b : se corre a delta espacios a la derecha y a se queda quieto
				s2factorshift 	<= s2factor;
				s2smshift		<= s2umb;
				s2um0			<= s2uma;
				s2xorslab		<= (others => s2signa);
		end case;
	end process;
		
	
	--! Correr las mantissas y calcularlas.
	hshift: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,18,27)
	port	map (s2factorshift,"01"&s2smshift(22 downto 0),s2psh);
	lshift: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port	map (s2factorshift,"0"&s2smshift(06 downto 0)&'0,s2psl);
	
		
--! ******************************************************************************************************************************
	--! Etapa2a signar las mantissas y sumarlas.
	signmantissa:
	process(s2asign,s2aum1,s2asm0,s2azero)
	begin 
		s2axorslab	<= (others => s2asign);
		s2asm1		<= (s2axorslab(23)&((s2um1(23 downto 0))xor(s2axorslab)))+(x"000000"&s2axorslab(23));
		case s2azero is
			when '0'  	=> s2asm <= (s2asm1(s2asm1'high)&s2asm1) +  (s2asm0(s2asm0'high)&s2asm0);
			when others	=> s2asm <= (s2asm1(s2asm1'high)&s2asm1) or (s2asm0(s2asm0'high)&s2asm0);
		end case;
	end process;	
	
--! ******************************************************************************************************************************
	--! Etapa3 : Quitar el signo a las mantissas y  calcular el factor 
	unsignmantissa:
	process(s3sm)
	begin
		s3xorslab	<= ( others => s3sm(s3sm'high) );
		s3um(24 downto 0)	<= ( s3sm(24 downto 0) xor s3xorslab ) + (x"000000"&s3xorslab(24));
		s3sign <= s3sm(s3sm'high);	
		s3count <= "00000";
		for i in 24 downto 0 loop 
			if s3um(i)='1' then
				s3count <= conv_std_logic_vector(24-i,8)+x"ff";
				exit;
			end if;
		end loop;
	end process;
--! ******************************************************************************************************************************
	--! Etapa3a : Decodificar el factor de corrimiento y calcular el exponente normalizado. 
--! ******************************************************************************************************************************
	redentioform:
	process(s4count)
	begin
		s4exp <= s4expunrm + s4count;
		
		case s4count(4 downto 3) is
			when "11" => s4factor <= '0'&x"01";
			when others
				case s4count(2 downto 0) is
					when x"0" => s4factor <= '0'&x"02";
					when x"1" => s4factor <= '0'&x"04";
					when x"2" => s4factor <= '0'&x"08";
					when x"3" => s4factor <= '0'&x"10";
					when x"4" => s4factor <= '0'&x"20";
					when x"5" => s4factor <= '0'&x"40";
					when x"6" => s4factor <= '0'&x"80";
					when others  => s4factor <= '1'&x"00";
				end case;
		end case;
	end process;

	--! Etapa4 : Mantissas sumadas, designar y normalizar
	hshift: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,18,27)
	port	map (s4factor,"01"&s2smshift(22 downto 0),s2psh);
	lshift: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port	map (s2factorshift,"0"&s2smshift(06 downto 0)&'0,s2psl);			
				
			
		
	
	
	
		 	  
	

end fadd32_arch;







	