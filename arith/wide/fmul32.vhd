------------------------------------------------
--! @file fmul32.vhd
--! @brief RayTrac Mantissa Multiplier  
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------


-- RAYTRAC (FP BRANCH)
-- Author Julian Andres Guarin
-- fmul32.vhd
-- This file is part of raytrac.
-- 
--     raytrac is free software: you can redistribute it and/or modify
--     it under the terms of the GNU General Public License as published by
--     the Free Software Foundation, either version 3 of the License, or
--     (at your option) any later version.
-- 
--     raytrac is distributed in the hope that it will be useful,
--     but WITHOUT ANY WARRANTY; without even the implied warranty of
--     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--     GNU General Public License for more details.
-- 
--     You should have received a copy of the GNU General Public License
--     along with raytrac.  If not, see <http://www.gnu.org/licenses/>
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use work.arithpack.all;


entity fmul32 is
	
	port (
		clk 		: in std_logic;
		
		factor0 : in std_logic_vector(31 downto 0);
		factor1 : in std_logic_vector(31 downto 0);
		factor2 : in std_logic_vector(31 downto 0);
		factor3 : in std_logic_vector(31 downto 0);
		factor4 : in std_logic_vector(31 downto 0);
		factor5 : in std_logic_vector(31 downto 0);
		factor6 : in std_logic_vector(31 downto 0);
		factor7 : in std_logic_vector(31 downto 0);
		factor8 : in std_logic_vector(31 downto 0);
		factor9 : in std_logic_vector(31 downto 0);
		factor10: in std_logic_vector(31 downto 0);
		factor11: in std_logic_vector(31 downto 0);
		p0: out std_logic_vector(31 downto 0);
		p1: out std_logic_vector(31 downto 0);
		p2: out std_logic_vector(31 downto 0);
		p3: out std_logic_vector(31 downto 0);
		p4: out std_logic_vector(31 downto 0);
		p5: out std_logic_vector(31 downto 0)
		
		
	);
end entity;
architecture fmul32_arch of fmul32 is 

	--! Altera Compiler Directive, to avoid m9k autoinferring thanks to the guys at http://www.alteraforum.com/forum/archive/index.php/t-30784.html .... 
	attribute altera_attribute : string; 
	attribute altera_attribute of fmul32_arch : architecture is "-name AUTO_SHIFT_REGISTER_RECOGNITION OFF";
	
	
	--Stage 0 signals
	signal s0dataa_alfa_p0,s0dataa_beta_p0,s0dataa_gama_p0,s0datab_p0 : std_logic_vector(17 downto 0);
	signal s0dataa_alfa_p1,s0dataa_beta_p1,s0dataa_gama_p1,s0datab_p1 : std_logic_vector(17 downto 0);
	signal s0dataa_alfa_p2,s0dataa_beta_p2,s0dataa_gama_p2,s0datab_p2 : std_logic_vector(17 downto 0);
	signal s0dataa_alfa_p3,s0dataa_beta_p3,s0dataa_gama_p3,s0datab_p3 : std_logic_vector(17 downto 0);
	signal s0dataa_alfa_p4,s0dataa_beta_p4,s0dataa_gama_p4,s0datab_p4 : std_logic_vector(17 downto 0);
	signal s0dataa_alfa_p5,s0dataa_beta_p5,s0dataa_gama_p5,s0datab_p5 : std_logic_vector(17 downto 0);
	--!TXBXSTART:MULT_STAGE0	
	signal s0sga_p0,s0sgb_p0,s0zrs_p0 : std_logic;
	signal s0sga_p1,s0sgb_p1,s0zrs_p1 : std_logic;
	signal s0sga_p2,s0sgb_p2,s0zrs_p2 : std_logic;
	signal s0sga_p3,s0sgb_p3,s0zrs_p3 : std_logic;
	signal s0sga_p4,s0sgb_p4,s0zrs_p4 : std_logic;
	signal s0sga_p5,s0sgb_p5,s0zrs_p5 : std_logic;
	signal s0exp_p0 : std_logic_vector(7 downto 0);
	signal s0exp_p1 : std_logic_vector(7 downto 0);
	signal s0exp_p2 : std_logic_vector(7 downto 0);
	signal s0exp_p3 : std_logic_vector(7 downto 0);
	signal s0exp_p4 : std_logic_vector(7 downto 0);
	signal s0exp_p5 : std_logic_vector(7 downto 0);
	signal s0uma_p0,s0umb_p0 : std_logic_vector(22 downto 0);
	signal s0uma_p1,s0umb_p1 : std_logic_vector(22 downto 0);
	signal s0uma_p2,s0umb_p2 : std_logic_vector(22 downto 0);
	signal s0uma_p3,s0umb_p3 : std_logic_vector(22 downto 0);
	signal s0uma_p4,s0umb_p4 : std_logic_vector(22 downto 0);
	signal s0uma_p5,s0umb_p5 : std_logic_vector(22 downto 0);
	signal s0ac_p0 : std_logic_vector(35 downto 0);
	signal s0ac_p1 : std_logic_vector(35 downto 0);
	signal s0ac_p2 : std_logic_vector(35 downto 0);
	signal s0ac_p3 : std_logic_vector(35 downto 0);
	signal s0ac_p4 : std_logic_vector(35 downto 0);
	signal s0ac_p5 : std_logic_vector(35 downto 0);
	--!TBXEND
	signal s1sgr_p0,s2sgr_p0:std_logic;
	signal s1sgr_p1,s2sgr_p1:std_logic;
	signal s1sgr_p2,s2sgr_p2:std_logic;
	signal s1sgr_p3,s2sgr_p3:std_logic;
	signal s1sgr_p4,s2sgr_p4:std_logic;
	signal s1sgr_p5,s2sgr_p5:std_logic;
	signal s0exa_p0,s0exb_p0,s1exp_p0,s2exp_p0:std_logic_vector(7 downto 0);
	signal s0exa_p1,s0exb_p1,s1exp_p1,s2exp_p1:std_logic_vector(7 downto 0);
	signal s0exa_p2,s0exb_p2,s1exp_p2,s2exp_p2:std_logic_vector(7 downto 0);
	signal s0exa_p3,s0exb_p3,s1exp_p3,s2exp_p3:std_logic_vector(7 downto 0);
	signal s0exa_p4,s0exb_p4,s1exp_p4,s2exp_p4:std_logic_vector(7 downto 0);
	signal s0exa_p5,s0exb_p5,s1exp_p5,s2exp_p5:std_logic_vector(7 downto 0);
	signal s0ad_p0,s0bc_p0,s1ad_p0,s1bc_p0:std_logic_vector(23 downto 0);
	signal s0ad_p1,s0bc_p1,s1ad_p1,s1bc_p1:std_logic_vector(23 downto 0);
	signal s0ad_p2,s0bc_p2,s1ad_p2,s1bc_p2:std_logic_vector(23 downto 0);
	signal s0ad_p3,s0bc_p3,s1ad_p3,s1bc_p3:std_logic_vector(23 downto 0);
	signal s0ad_p4,s0bc_p4,s1ad_p4,s1bc_p4:std_logic_vector(23 downto 0);
	signal s0ad_p5,s0bc_p5,s1ad_p5,s1bc_p5:std_logic_vector(23 downto 0);
	signal s1ac_p0,s1umu_p0:std_logic_vector(35 downto 0);
	signal s1ac_p1,s1umu_p1:std_logic_vector(35 downto 0);
	signal s1ac_p2,s1umu_p2:std_logic_vector(35 downto 0);
	signal s1ac_p3,s1umu_p3:std_logic_vector(35 downto 0);
	signal s1ac_p4,s1umu_p4:std_logic_vector(35 downto 0);
	signal s1ac_p5,s1umu_p5:std_logic_vector(35 downto 0);
	signal s2umu_p0:std_logic_vector(24 downto 0);
	signal s2umu_p1:std_logic_vector(24 downto 0);
	signal s2umu_p2:std_logic_vector(24 downto 0);
	signal s2umu_p3:std_logic_vector(24 downto 0);
	signal s2umu_p4:std_logic_vector(24 downto 0);
	signal s2umu_p5:std_logic_vector(24 downto 0);
	
	--! LPM_MULTIPLIER
	component lpm_mult 
	generic (
		lpm_hint			: string;
		lpm_pipeline		: natural;
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
	
	
begin
	
	
	process(clk)
	begin
	
		if clk'event and clk='1'  then
			--! Registro de entrada
			s0sga_p0 <= factor0(31);
			s0sga_p1 <= factor2(31);
			s0sga_p2 <= factor4(31);
			s0sga_p3 <= factor6(31);
			s0sga_p4 <= factor8(31);
			s0sga_p5 <= factor10(31);

			s0sgb_p0 <= factor1(31);
			s0sgb_p1 <= factor3(31);
			s0sgb_p2 <= factor5(31);
			s0sgb_p3 <= factor7(31);
			s0sgb_p4 <= factor9(31);
			s0sgb_p5 <= factor11(31);

			s0exa_p0 <= factor0(30 downto 23);
			s0exa_p1 <= factor2(30 downto 23);
			s0exa_p2 <= factor4(30 downto 23);
			s0exa_p3 <= factor6(30 downto 23);
			s0exa_p4 <= factor8(30 downto 23);
			s0exa_p5 <= factor10(30 downto 23);

			s0exb_p0 <= factor1(30 downto 23);
			s0exb_p1 <= factor3(30 downto 23);
			s0exb_p2 <= factor5(30 downto 23);
			s0exb_p3 <= factor7(30 downto 23);
			s0exb_p4 <= factor9(30 downto 23);
			s0exb_p5 <= factor11(30 downto 23);

			s0uma_p0 <= factor0(22 downto 0);
			s0uma_p1 <= factor2(22 downto 0);
			s0uma_p2 <= factor4(22 downto 0);
			s0uma_p3 <= factor6(22 downto 0);
			s0uma_p4 <= factor8(22 downto 0);
			s0uma_p5 <= factor10(22 downto 0);

			s0umb_p0 <= factor1(22 downto 0);
			s0umb_p1 <= factor3(22 downto 0);
			s0umb_p2 <= factor5(22 downto 0);
			s0umb_p3 <= factor7(22 downto 0);
			s0umb_p4 <= factor9(22 downto 0);
			s0umb_p5 <= factor11(22 downto 0);

			--! Etapa 0 multiplicacion de la mantissa, suma de los exponentes y multiplicaci&oacute;n de los signos.
			s1sgr_p0 <= s0sga_p0 xor s0sgb_p0;
			s1sgr_p1 <= s0sga_p1 xor s0sgb_p1;
			s1sgr_p2 <= s0sga_p2 xor s0sgb_p2;
			s1sgr_p3 <= s0sga_p3 xor s0sgb_p3;
			s1sgr_p4 <= s0sga_p4 xor s0sgb_p4;
			s1sgr_p5 <= s0sga_p5 xor s0sgb_p5;

			s1ad_p0 <= s0ad_p0;
			s1ad_p1 <= s0ad_p1;
			s1ad_p2 <= s0ad_p2;
			s1ad_p3 <= s0ad_p3;
			s1ad_p4 <= s0ad_p4;
			s1ad_p5 <= s0ad_p5;
			
			s1bc_p0 <= s0bc_p0;
			s1bc_p1 <= s0bc_p1;
			s1bc_p2 <= s0bc_p2;
			s1bc_p3 <= s0bc_p3;
			s1bc_p4 <= s0bc_p4;
			s1bc_p5 <= s0bc_p5;

			s1ac_p0 <= s0ac_p0;
			s1ac_p1 <= s0ac_p1;
			s1ac_p2 <= s0ac_p2;
			s1ac_p3 <= s0ac_p3;
			s1ac_p4 <= s0ac_p4;
			s1ac_p5 <= s0ac_p5;

			s1exp_p0 <= s0exp_p0;
			s1exp_p1 <= s0exp_p1;
			s1exp_p2 <= s0exp_p2;
			s1exp_p3 <= s0exp_p3;
			s1exp_p4 <= s0exp_p4;
			s1exp_p5 <= s0exp_p5;
			
			--! Etapa 1 Sumas parciales
			s2umu_p0 <= s1umu_p0(35 downto 11);
			s2umu_p1 <= s1umu_p1(35 downto 11);
			s2umu_p2 <= s1umu_p2(35 downto 11);
			s2umu_p3 <= s1umu_p3(35 downto 11);
			s2umu_p4 <= s1umu_p4(35 downto 11);
			s2umu_p5 <= s1umu_p5(35 downto 11);
			
			s2sgr_p0 <= s1sgr_p0;
			s2sgr_p1 <= s1sgr_p1;
			s2sgr_p2 <= s1sgr_p2;
			s2sgr_p3 <= s1sgr_p3;
			s2sgr_p4 <= s1sgr_p4;
			s2sgr_p5 <= s1sgr_p5;

			s2exp_p0 <= s1exp_p0;
			s2exp_p1 <= s1exp_p1;
			s2exp_p2 <= s1exp_p2;
			s2exp_p3 <= s1exp_p3;
			s2exp_p4 <= s1exp_p4;
			s2exp_p5 <= s1exp_p5;
			
			
		end if;
	end process;
	--! Etapa 2 entregar el resultado
	p0(31) <= s2sgr_p0;
	p1(31) <= s2sgr_p1;
	p2(31) <= s2sgr_p2;
	p3(31) <= s2sgr_p3;
	p4(31) <= s2sgr_p4;
	p5(31) <= s2sgr_p5;

	process (
		s2exp_p0,
		s2exp_p1,
		s2exp_p2,
		s2exp_p3,
		s2exp_p4,
		s2exp_p5,

		s2umu_p0,
		s2umu_p1,
		s2umu_p2,
		s2umu_p3,
		s2umu_p4,
		s2umu_p5
	)
	begin

		p0(30 downto 23) <= s2exp_p0+s2umu_p0(24);
		p1(30 downto 23) <= s2exp_p1+s2umu_p1(24);
		p2(30 downto 23) <= s2exp_p2+s2umu_p2(24);
		p3(30 downto 23) <= s2exp_p3+s2umu_p3(24);
		p4(30 downto 23) <= s2exp_p4+s2umu_p4(24);
		p5(30 downto 23) <= s2exp_p5+s2umu_p5(24);

		if s2umu_p0(24) ='1' then
			p0(22 downto 0) <= s2umu_p0(23 downto 1);
		else
			p0(22 downto 0) <= s2umu_p0(22 downto 0);
		end if;
		if s2umu_p1(24) ='1' then
			p1(22 downto 0) <= s2umu_p1(23 downto 1);
		else
			p1(22 downto 0) <= s2umu_p1(22 downto 0);
		end if;
		if s2umu_p2(24) ='1' then
			p2(22 downto 0) <= s2umu_p2(23 downto 1);
		else
			p2(22 downto 0) <= s2umu_p2(22 downto 0);
		end if;
		if s2umu_p3(24) ='1' then
			p3(22 downto 0) <= s2umu_p3(23 downto 1);
		else
			p3(22 downto 0) <= s2umu_p3(22 downto 0);
		end if;
		if s2umu_p4(24) ='1' then
			p4(22 downto 0) <= s2umu_p4(23 downto 1);
		else
			p4(22 downto 0) <= s2umu_p4(22 downto 0);
		end if;
		if s2umu_p5(24) ='1' then
			p5(22 downto 0) <= s2umu_p5(23 downto 1);
		else
			p5(22 downto 0) <= s2umu_p5(22 downto 0);
		end if;
	end process;	
	
	--! Combinatorial Gremlin Etapa 0 : multiplicacion de la mantissa, suma de los exponentes y multiplicaci&oacute;n de los signos.
	
	--! Multipliers
	s0dataa_alfa_p0 <= s0zrs_p0&s0uma_p0(22 downto 6);
	s0dataa_alfa_p1 <= s0zrs_p1&s0uma_p1(22 downto 6);
	s0dataa_alfa_p2 <= s0zrs_p2&s0uma_p2(22 downto 6);
	s0dataa_alfa_p3 <= s0zrs_p3&s0uma_p3(22 downto 6);
	s0dataa_alfa_p4 <= s0zrs_p4&s0uma_p4(22 downto 6);
	s0dataa_alfa_p5 <= s0zrs_p5&s0uma_p5(22 downto 6);

	s0datab_p0 <= s0zrs_p0&s0umb_p0(22 downto 6);
	s0datab_p1 <= s0zrs_p1&s0umb_p1(22 downto 6);
	s0datab_p2 <= s0zrs_p2&s0umb_p2(22 downto 6);
	s0datab_p3 <= s0zrs_p3&s0umb_p3(22 downto 6);
	s0datab_p4 <= s0zrs_p4&s0umb_p4(22 downto 6);
	s0datab_p5 <= s0zrs_p5&s0umb_p5(22 downto 6);

	mult18x18ac0:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 18,
		lpm_widthp => 36
	)
	port map (
		dataa => s0dataa_alfa_p0,
		datab => s0datab_p0,
		result => s0ac_p0
	);

	mult18x18ac1:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 18,
		lpm_widthp => 36
	)
	port map (
		dataa => s0dataa_alfa_p1,
		datab => s0datab_p1,
		result => s0ac_p1
	);

	mult18x18ac2:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 18,
		lpm_widthp => 36
	)
	port map (
		dataa => s0dataa_alfa_p2,
		datab => s0datab_p2,
		result => s0ac_p2
	);

	mult18x18ac3:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 18,
		lpm_widthp => 36
	)
	port map (
		dataa => s0dataa_alfa_p3,
		datab => s0datab_p3,
		result => s0ac_p3
	);

	mult18x18ac4:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 18,
		lpm_widthp => 36
	)
	port map (
		dataa => s0dataa_alfa_p4,
		datab => s0datab_p4,
		result => s0ac_p4
	);
	mult18x18ac5:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 18,
		lpm_widthp => 36
	)
	port map (
		dataa => s0dataa_alfa_p5,
		datab => s0datab_p5,
		result => s0ac_p5
	);

	s0dataa_beta_p0 <= s0zrs_p0&s0uma_p0(22 downto 6);
	s0dataa_beta_p1 <= s0zrs_p1&s0uma_p1(22 downto 6);
	s0dataa_beta_p2 <= s0zrs_p2&s0uma_p2(22 downto 6);
	s0dataa_beta_p3 <= s0zrs_p3&s0uma_p3(22 downto 6);
	s0dataa_beta_p4 <= s0zrs_p4&s0uma_p4(22 downto 6);
	s0dataa_beta_p5 <= s0zrs_p5&s0uma_p5(22 downto 6);

	mult18x6ad0:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_beta_p0,
		datab => s0umb_p0(5 downto 0),
		result => s0ad_p0
	);


	mult18x6ad1:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_beta_p1,
		datab => s0umb_p1(5 downto 0),
		result => s0ad_p1
	);

	mult18x6ad2:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_beta_p2,
		datab => s0umb_p2(5 downto 0),
		result => s0ad_p2
	);

	mult18x6ad3:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_beta_p3,
		datab => s0umb_p3(5 downto 0),
		result => s0ad_p3
	);

	mult18x6ad4:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_beta_p4,
		datab => s0umb_p4(5 downto 0),
		result => s0ad_p4
	);

	mult18x6ad5:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_beta_p5,
		datab => s0umb_p5(5 downto 0),
		result => s0ad_p5
	);


	s0dataa_gama_p0 <= s0zrs_p0&s0umb_p0(22 downto 6);
	s0dataa_gama_p1 <= s0zrs_p0&s0umb_p1(22 downto 6);
	s0dataa_gama_p2 <= s0zrs_p0&s0umb_p2(22 downto 6);
	s0dataa_gama_p3 <= s0zrs_p0&s0umb_p3(22 downto 6);
	s0dataa_gama_p4 <= s0zrs_p0&s0umb_p4(22 downto 6);
	s0dataa_gama_p5 <= s0zrs_p0&s0umb_p5(22 downto 6);

	mult18x6bc0:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_gama_p0,
		datab => s0uma_p0(5 downto 0),
		result => s0bc_p0
	);
	
	mult18x6bc1:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_gama_p1,
		datab => s0uma_p1(5 downto 0),
		result => s0bc_p1
	);
	
	mult18x6bc2:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_gama_p2,
		datab => s0uma_p2(5 downto 0),
		result => s0bc_p2
	);
	
	mult18x6bc3:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_gama_p4,
		datab => s0uma_p4(5 downto 0),
		result => s0bc_p4
	);
	
	mult18x6bc5:lpm_mult
	generic	map (
		lpm_hint => "DEDICATED_MULTIPLIER_CIRCUITRY=YES,MAXIMIZE_SPEED=9",
		lpm_pipeline => 0,
		lpm_representation => "UNSIGNED",
		lpm_type => "LPM_MULT",
		lpm_widtha => 18,
		lpm_widthb => 6,
		lpm_widthp => 24
	)
	port map (
		dataa => s0dataa_gama_p5,
		datab => s0uma_p5(5 downto 0),
		result => s0bc_p5
	);
	
	
	--! Exponent Addition 
	process (
		s0sga_p0,
		s0sga_p1,
		s0sga_p2,
		s0sga_p3,
		s0sga_p4,
		s0sga_p5,

		s0sgb_p0,
		s0sgb_p1,
		s0sgb_p2,
		s0sgb_p3,
		s0sgb_p4,
		s0sgb_p5,

		s0exa_p0,
		s0exa_p1,
		s0exa_p2,
		s0exa_p3,
		s0exa_p4,
		s0exa_p5,

		s0exb_p0,
		s0exb_p1,
		s0exb_p2,
		s0exb_p3,
		s0exb_p4,
		s0exb_p5
	)

	begin
	 
		if s0exa_p0=x"00" or s0exb_p0=x"00" then
			s0exp_p0 <= (others => '0');
			s0zrs_p0 <= '0';
		else 
			s0zrs_p0<='1';
			s0exp_p0 <= s0exa_p0+s0exb_p0+x"81";
		end if;
		if s0exa_p1=x"00" or s0exb_p1=x"00" then
			s0exp_p1 <= (others => '0');
			s0zrs_p1 <= '0';
		else 
			s0zrs_p1<='1';
			s0exp_p1 <= s0exa_p1+s0exb_p1+x"81";
		end if;
		if s0exa_p2=x"00" or s0exb_p2=x"00" then
			s0exp_p2 <= (others => '0');
			s0zrs_p2 <= '0';
		else 
			s0zrs_p2<='1';
			s0exp_p2 <= s0exa_p2+s0exb_p2+x"81";
		end if;
		if s0exa_p3=x"00" or s0exb_p3=x"00" then
			s0exp_p3 <= (others => '0');
			s0zrs_p3 <= '0';
		else 
			s0zrs_p3<='1';
			s0exp_p3 <= s0exa_p3+s0exb_p3+x"81";
		end if;
		if s0exa_p4=x"00" or s0exb_p4=x"00" then
			s0exp_p4 <= (others => '0');
			s0zrs_p4 <= '0';
		else 
			s0zrs_p4<='1';
			s0exp_p4 <= s0exa_p4+s0exb_p4+x"81";
		end if;
		if s0exa_p5=x"00" or s0exb_p5=x"00" then
			s0exp_p5 <= (others => '0');
			s0zrs_p5 <= '0';
		else 
			s0zrs_p5<='1';
			s0exp_p5 <= s0exa_p5+s0exb_p5+x"81";
		end if;
	end process;
	
	--! Etapa 1: Suma parcial de la multiplicacion. Suma del exponente	
	process(
		
		s1ac_p0,
		s1ac_p1,
		s1ac_p2,
		s1ac_p3,
		s1ac_p4,
		s1ac_p5,
		
		s1ad_p0,
		s1ad_p1,
		s1ad_p2,
		s1ad_p3,
		s1ad_p4,
		s1ad_p5,
		
		s1bc_p0,
		s1bc_p1,
		s1bc_p2,
		s1bc_p3,
		s1bc_p4,
		s1bc_p5
	)
	begin

		s1umu_p0 <= s1ac_p0+s1ad_p0(23 downto 6)+s1bc_p0(23 downto 6);
		s1umu_p1 <= s1ac_p1+s1ad_p1(23 downto 6)+s1bc_p1(23 downto 6);
		s1umu_p2 <= s1ac_p2+s1ad_p2(23 downto 6)+s1bc_p2(23 downto 6);
		s1umu_p3 <= s1ac_p3+s1ad_p3(23 downto 6)+s1bc_p3(23 downto 6);
		s1umu_p4 <= s1ac_p4+s1ad_p4(23 downto 6)+s1bc_p4(23 downto 6);
		s1umu_p5 <= s1ac_p5+s1ad_p5(23 downto 6)+s1bc_p5(23 downto 6);

	end process;
	
	
			
	
	
	
end architecture;