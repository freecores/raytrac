
























library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;




entity fadd32 is 
	port (
		a32,b32: in std_logic_vector(31 downto 0);
		dpc,clk:in std_logic;
		c32:out std_logic_vector(31 downto 0)
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
	
	signal s0signa,s0signb : std_logic;
	signal s0ea,s0eb: std_logic_vector(7 downto 0);
	signal s0uma,s0umb:std_logic_vector(22 downto 0);
	
	signal s1signa, s1signb: std_logic;
	signal s1sdelta,s1expunrm: std_logic_vector(7 downto 0);
	signal s1udelta,s1xorslab: std_logic_vector(4 downto 0);
	signal s1uma,s1umb:std_logic_vector(22 downto 0);
	signal s1factor: std_logic_vector(8 downto 0);
	
	signal s2signa,s2signb,s2bgta : std_logic;
	signal s2exp : std_logic_vector(7 downto 0);
	signal s2udelta : std_logic_vector (1 downto 0);
	signal s2um0,s2uma,s2umb,s2smshift : std_logic_vector(22 downto 0);
	signal s2xorslab : std_logic_vector(23 downto 0);	
	signal s2factor : std_logic_vector(8 downto 0);
	signal s2psh:std_logic_vector(26 downto 0);
	signal s2psl:std_logic_vector(17 downto 0);
	
	signal s2asign,s2azero,s2abgta:std_logic;
	signal s2asm0,s2asm1 : std_logic_vector(24 downto 0);
	signal s2asm : std_logic_vector(25 downto 0);
	signal s2aum1 : std_logic_vector(23 downto 0);
	signal s2aexp : std_logic_vector(7 downto 0);
	signal s2audelta : std_logic_vector (1 downto 0);
	signal s2axorslab: std_logic_vector(23 downto 0);
	
	signal s3sign: std_logic;
	signal s3um,s3xorslab: std_logic_vector(24 downto 0);
	signal s3sm: std_logic_vector(25 downto 0);
	signal s3exp:std_logic_vector(7 downto 0);
	
	signal s3asign:std_logic;
	signal s3ashift:std_logic_vector(7 downto 0);
	signal s3afactor,s3aexp: std_logic_vector(7 downto 0);
	signal s3aum,s3afactorhot:std_logic_vector(24 downto 0);
	
	signal s4sign: std_logic;
	signal s4shift: std_logic_vector(7 downto 0); 
	signal s4exp: std_logic_vector(7 downto 0);
	signal s4factorhot9: std_logic_vector(8 downto 0);
	signal s4pl: std_logic_vector(17 downto 0);
	signal s4postshift: std_logic_vector(22 downto 0); 
	signal s4um,s4factorhot: std_logic_vector(24 downto 0);
	signal s4ph: std_logic_vector(26 downto 0);
		
begin 

--! ******************************************************************************************************************************
	--! Pipeline
	pipeline:
	process(clk)
	begin
	
		if clk='1' and clk'event then
		
			--! Registro de entrada

			s0ea	<=	a32(30 downto 23);
			s0uma	<=	a32(22 downto 0);
			s0signa	<=	a32(31);
			s0eb	<=	b32(30 downto 23);
			s0umb	<=	b32(22 downto 0);
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
				s1sdelta <= x"00";
			else
				s1sdelta <= s0ea-s0eb;
			end if;
			--! Buffers
			s1uma		<=	s0uma;
			s1umb		<=	s0umb;
			
			--! Etapa 1
			--! Manejo de exponente, previo a la denormalizacion
			--! Calulo del Factor de corrimiento 
			s2exp	<= s1expunrm+s1sdelta;
			s2factor	<= s1factor;		
			
			--! Otras se&ntilde;ales de soporte
			s2signa		<= s1signa;
			s2signb		<= s1signb;
			s2bgta		<= s1sdelta(7);
			s2uma		<= s1uma;
			s2umb		<= s1umb;
			s2udelta	<= s1udelta(4 downto 3);
			
			--! Etapa 2 Realizar los corrimientos, denormalizacion parcial y signar la mantissa que se queda fija
			--! Mantissa Fija
			s2asm0		<= (s2xorslab(23)&(('1'&s2um0(22 downto 0))xor(s2xorslab)))+(x"000000"&s2xorslab(23));
			--! Mantissa Corrida no signada
			case s2udelta is
				when "00" => 
					s2aum1(23 downto 06) 	<= s2psh(25 downto 08);
					s2aum1(05 downto 00)	<= s2psh(07 downto 02) or (s2psl(16 downto 11));
				when "01" => 
					s2aum1(23 downto 06) 	<= x"00"&s2psh(25 downto 16);
					s2aum1(05 downto 00)	<= s2psh(15 downto 10);
				when "10" =>
					s2aum1(23 downto 06) 	<= x"0000"&s2psh(25 downto 24);
					s2aum1(05 downto 00)	<= s2psh(23 downto 18);
				when others => 
					s2aum1 					<= (others => '0');
			end case; 	
			s2asign		<= (s2bgta and s2signa) or (not(s2bgta) and s2signb); 
			--! Exponente normalizado
			s2aexp 		<= s2exp;
			--! Uno de los sumandos es 0.
			s2azero		<= (not(s2signb)) or (not(s2signa));
			
			
			--! Etapa 2a signar la mantissa corrida y sumarlas con la no corrida
			s3sm <= s2asm;
			s3exp <= s2aexp;
			
			
			--! Etapa 3 quitar el signo a la mantissa.
			s3asign <= s3sign;
			s3aum <= s3um;
			s3aexp <= s3exp;
			
			
			--! Eatapa 3a calcular el factor de corrimiento para la normalizacion y el delta del exponente.
			s4sign <= s3asign;
			s4exp  <= s3aexp;
			s4shift<= s3ashift;
			s4factorhot <= s3afactorhot;
			s4um <= s3aum;
			
			--! Etapa 4 Normalizar la mantissa resultado y renormalizar el exponente. Entregar el resultado!
			c32(31) <= s4sign;
			c32(30 downto 23) <= s4exp-s4shift;
			case s4shift(4 downto 3) is
				when "01"  =>  c32(22 downto 0) <= x"00"&s4postshift(22 downto 8);
				when "10"  =>  c32(22 downto 0) <= x"0000"&s4postshift(22 downto 16);
				when others => c32(22 downto 0) <= s4postshift(22 downto 0);
			end case;	
		
		end if;
	end process;
	
--! ******************************************************************************************************************************
	
	--! Etapa 1
	--! Decodificar la magnitud del corrimiento
	decodermag:
	process (s1udelta(7), s1udelta(4 downto 0))
	begin
		s1xorslab	<= (others => s1sdelta(7));
		s1udelta 	<= (s1sdelta(4 downto 0) xor s1xorslab)+(x"0"&s1sdelta(7));	
	end process;
	
	--! Decodificar el factor de corrimiento
	denormfactor:
	process (s1udelta(2 downto 0),s1sdelta(7))
	begin
		s1factor(8 downto 0) <= (others => s1sdelta(7));
		case s1udelta(2 downto 0) is
			when "000" => s1factor(8 downto 0) 	<= "100000000"; 
			when "001" => s1factor(8 downto 0) 	<= "010000000";
			when "010" => s1factor(8 downto 0) 	<= "001000000";
			when "011" => s1factor(8 downto 0) 	<= "000100000";
			when "100" => s1factor(8 downto 0) 	<= "000010000";
			when "101" => s1factor(8 downto 0) 	<= "000001000";
			when "110" => s1factor(8 downto 0) 	<= "000000100";
			when others => s1factor(8 downto 0) <= "000000010";
		end case;
 	end process;
--! ******************************************************************************************************************************
	--! Etapa2
	--! Correr las mantissas
	denomrselectmantissa2shift:
	process (s2bgta,s2signa,s2signb,s2uma,s2umb)
	begin
		
		case s2bgta is 
			when '1' => -- Negativo b>a : se corre a delta espacios a la derecha y b se queda quieto
				s2um0			<= s2umb;
				s2xorslab		<= (others => s2signb);

				s2smshift		<= s2uma;

			when others => -- Positivo a>=b : se corre a delta espacios a la derecha y a se queda quieto
				s2um0			<= s2uma;
				s2xorslab		<= (others => s2signa);

				s2smshift		<= s2umb;

		end case;
	end process;
		
	
	--! Correr las mantissas y calcularlas.
	hshiftdenorm: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,18,27)
	port	map (s2factor,'1'&s2smshift(22 downto 06),s2psh);
	lshiftdenorm: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port	map (s2factor,s2smshift(05 downto 00)&"000",s2psl);
	
		
--! ******************************************************************************************************************************
	--! Etapa2a signar las mantissas y sumarlas.
	signmantissa:
	process(s2asign,s2aum1,s2asm0,s2azero)
	begin 
		s2axorslab	<= (others => s2asign);
		s2asm1		<= (s2axorslab(23)&(s2aum1 xor (s2axorslab)))+(x"000000"&s2axorslab(23));
		case s2azero is
			when '0'  	=> s2asm <= (s2asm1(s2asm1'high)&s2asm1) +  (s2asm0(s2asm0'high)&s2asm0);
			when others	=> s2asm <= (s2asm1(s2asm1'high)&s2asm1) or (s2asm0(s2asm0'high)&s2asm0);
		end case;
	end process;	
	
--! ******************************************************************************************************************************
	--! Etapa3 : Quitar el signo a las mantissa.
--! ******************************************************************************************************************************
	unsignmantissa:
	process(s3sm)
	begin
		s3xorslab	<= ( others => s3sm(s3sm'high) );
		s3um(24 downto 0)	<= ( s3sm(24 downto 0) xor s3xorslab ) + (x"000000"&s3xorslab(24));
		s3sign <= s3sm(s3sm'high);	
	end process;
--! ******************************************************************************************************************************
	--! Etapa3a : Decodificar el factor de corrimiento y calcular el exponente normalizado. 
--! ******************************************************************************************************************************
	redentioform:
	process(s3aum,s3asign)
	begin
		s3ashift <= s3aexp;
		s3afactorhot <= (others => '0');
		for i in 24 downto 0 loop
			if s3aum(i)='1' then 
				s3ashift <= conv_std_logic_vector(24-i,8)+x"ff";
				s3afactorhot(24-i) <= '1';
				exit;
			end if;
		end loop;
	end process;
--! ******************************************************************************************************************************
	--! Etapa4 : Normalizar la mantissa y calcular el exponente. Entregar el resultado 
--! ******************************************************************************************************************************
	--!Normalizacion mediante multiplicacion
	process (s4ph,s4pl,s4factorhot,s4um)
	begin 
		s4postshift(22 downto 15) <= s4ph(16 downto 9);
		s4postshift(14 downto 06) <= s4ph(08 downto 0) or s4pl(17 downto 9);
		s4postshift(05 downto 00) <= s4pl(08 downto 3);
		case s4shift(4 downto 3) is
			when "00"  => 
				s4factorhot9 <= s4factorhot(08 downto 01)&'0';
			when "01"  => 
				s4factorhot9 <= s4factorhot(16 downto 09)&'0';
			when "10"  => 
				s4factorhot9 <= s4factorhot(24 downto 17)&'0';
			when others => 
				s4factorhot9 <= s4factorhot(08 downto 00);
		end case;
	end process;
	hshiftnorm: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,18,27)
	port	map (s4factorhot9,s4um(24 downto 07),s4ph);
	lshiftnorm: lpm_mult
	generic	map ("DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9","UNSIGNED","LPM_MULT",9,9,18)
	port	map (s4factorhot9,s4um(06 downto 00)&"00",s4pl);
	
				
				
			
		
	
	
	
		 	  
	

end fadd32_arch;







	