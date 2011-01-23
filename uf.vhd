-- RAYTRAC
-- Author Julian Andres Guarin
-- uf.vhd
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
--     along with raytrac.  If not, see <http://www.gnu.org/licenses/>.

library ieee;
use ieee.std_logic_1164.all;
use work.arithpack.all;

entity uf is 
	port (
		opcode		: in std_logic;
		m0f0,m0f1,m1f0,m1f1,m2f0,m2f1,m3f0,m3f1,m4f0,m4f1,m5f0,m5f1 : in std_logic_vector(17 downto 0);
		cpx,cpy,cpz,dp0,dp1 : out std_logic_vector(31 downto 0);
		clk,rst		: in std_logic
	);
end uf;

architecture uf_arch of uf is 

	-- Stage 0 signals
	
	signal s0mf00,s0mf01,s0mf10,s0mf11,s0mf20,s0mf21,s0mf30,s0mf31,s0mf40,s0mf41,s0mf50,s0mf51 : std_logic_vector(17 downto 0); 
	signal s0p0,s0p1, s0p2, s0p3, s0p4, s0p5 : std_logic_vector(31 downto 0);
	signal s0opcode : std_logic;
	
	--Stage 1 signals 
	
	signal s1p0, s1p1, s1p2, s1p3, s1p4, s1p5 : std_logic_vector (31 downto 0);
	signal s1a0, s1a1, s1a2 : std_logic_vector (31 downto 0);
	signal s1opcode : std_logic;
	
	-- Some support signals
	signal s1_internalCarry	: std_logic_vector(2 downto 0);
	signal s2_internalCarry : std_logic_vector(1 downto 0);
	
	--Stage 2 signals
	
	signal s2a0, s2a2, s2a3, s2a4, s2p2, s2p3 : std_logic_vector (31 downto 0);
	
	  	
	
begin

	-- Multiplicator Instantiation (StAgE 0)
	
	m0 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> s0mf00,
		datab	=> s0mf01,
		result	=> s0p0
	);
	m1 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> s0mf10,
		datab	=> s0mf11,
		result	=> s0p1
	);
	m2 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> s0mf20,
		datab	=> s0mf21,
		result	=> s0p2
	);
	m3 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> s0mf30,
		datab	=> s0mf31,
		result	=> s0p3
	);
	m4 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> s0mf40,
		datab	=> s0mf41,
		result	=> s0p4
	);
	m5 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> s0mf50,
		datab	=> s0mf51,
		result	=> s0p5
	);
	
	-- Adder Instantiation (sTaGe 1)
	
	--Adder 0, low adder 
	a0low : adder 
	generic map (
		16,"CLA","YES"	--Carry Look Ahead Logic (More Gates Used, But Less Time)
						--Yes instantiate Xor gates stage in the adder so we can substract on the opcode signal command.
	)
	port map	(
		a => s1p0(15 downto 0),
		b => s1p1(15 downto 0),
		s => s1opcode,
		ci => '0',
		result => s1a0(15 downto 0),
		cout =>	s1_internalCarry(0)
	);
	--Adder 0, high adder
	a0high : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "YES"	--Yes instantiate Xor gates stage in the adder so we can substract on the opcode signal command.
	)
	port map	(
		a => s1p0(31 downto 16),
		b => s1p1(31 downto 16),
		s => s1opcode,
		ci => s1_internalCarry(0),
		result => s1a0(31 downto 16),
		cout =>	open
	);
	--Adder 1, low adder 
	a1low : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "YES"	--Yes instantiate Xor gates stage in the adder so we can substract on the opcode signal command.
	)
	port map	(
		a => s1p2(15 downto 0),
		b => s1p3(15 downto 0),
		s => s1opcode,
		ci => '0',
		result => s1a1(15 downto 0),
		cout =>	s1_internalCarry(1)
	);
	--Adder 1, high adder
	a1high : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "YES"	--Yes instantiate Xor gates stage in the adder so we can substract on the opcode signal command.
	)
	port map	(
		a => s1p2(31 downto 16),
		b => s1p3(31 downto 16),
		s => s1opcode,
		ci => s1_internalCarry(1),
		result => s1a1(31 downto 16),
		cout =>	open
	);	
	--Adder 2, low adder 
	a2low : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "YES"	--Yes instantiate Xor gates stage in the adder so we can substract on the opcode signal command.
	)
	port map	(
		a => s1p4(15 downto 0),
		b => s1p5(15 downto 0),
		s => s1opcode,
		ci => '0',
		result => s1a2(15 downto 0),
		cout =>	s1_internalCarry(2)
	);
	--Adder 2, high adder
	a2high : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "YES"	--Yes instantiate Xor gates stage in the adder so we can substract on the opcode signal command.
	)
	port map	(
		a => s1p4(31 downto 16),
		b => s1p5(31 downto 16),
		s => s1opcode,
		ci => s1_internalCarry(2),
		result => s1a2(31 downto 16),
		cout =>	open
	);
	
	
	-- Adder Instantiation (Stage 2)
	--Adder 3, low adder 
	a3low : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "NO"		--No Just Add.
	)
	port map	(
		a => s2a0(15 downto 0),
		b => s2p2(15 downto 0),
		s => '0',
		ci => '0',
		result => s2a3(15 downto 0),
		cout =>	s2_internalCarry(0)
	);
	--Adder 3, high adder
	a3high : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "NO"		--No Just Add.
	)
	port map	(
		a => s2a0(31 downto 16),
		b => s2p2(31 downto 16),
		s => '0',
		ci => s2_internalCarry(0),
		result => s2a3(31 downto 16),
		cout =>	open
	);
	--Adder 4, low adder 
	a4low : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "NO"		--No Just Add.
	)
	port map	(
		a => s2p3(15 downto 0),
		b => s2a2(15 downto 0),
		s => '0',
		ci => '0',
		result => s2a4(15 downto 0),
		cout =>	s2_internalCarry(1)
	);
	--Adder 4, high adder
	a4high : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "NO"		--No Just Add.
	)
	port map	(
		a => s2p3(31 downto 16),
		b => s2a2(31 downto 16),
		s => '0',
		ci => s2_internalCarry(1),
		result => s2a4(31 downto 16),
		cout =>	open
	);	
					
	-- Incoming from opcoder.vhd signals into pipeline's stage 0.
	s0mf00 <= m0f0;
	s0mf01 <= m0f1;
	s0mf10 <= m1f0;
	s0mf11 <= m1f1;
	s0mf20 <= m2f0;
	s0mf21 <= m2f1;
	s0mf30 <= m3f0;
	s0mf31 <= m3f1;
	s0mf40 <= m4f0;
	s0mf41 <= m4f1;
	s0mf50 <= m5f0;
	s0mf51 <= m5f1;
	
	-- Signal sequencing: as the multipliers use registered output and registered input is not necessary to write the sequence of stage 0 signals to stage 1 signals.
	-- so the simplistic path is taken: simply connect stage 0 to stage 1 lines. However this would not apply for the opcode signal
	s1p0 <= s0p0;
	s1p1 <= s0p1;
	s1p2 <= s0p2;
	s1p3 <= s0p3;
	s1p4 <= s0p4;
	s1p5 <= s0p5;
	 
	
	--Outcoming to the rest of the system (by the time i wrote this i dont know where this leads to... jeje)
	cpx <= s1a0;
	cpy <= s1a1;
	cpz <= s1a2;
	dp0 <= s2a3;
	dp1 <= s2a4;
	
	-- Looking into the design the stage 1 to stage 2 are the sequences pipe stages that must be controlled in this particular HDL.
	uf_seq: process (clk,rst)
	begin
		
		if rst=rstMasterValue then 
			s0opcode	<= '0';
			s1opcode 	<= '0';
			
			s2a2 <= (others => '0');
			s2p3 <= (others => '0');
			s2p2 <= (others => '0');
			s2a0 <= (others => '0');
		
		elsif clk'event and clk = '1' then 
		
			s2a2 <= s1a2;
			s2p3 <= s1p3;
			s2p2 <= s1p2;
			s2a0 <= s1a0;
			
			-- Opcode control sequence
			s0opcode <= opcode;
			s1opcode <= s0opcode;
					
		end if;
	end process uf_seq;
end uf_arch;
