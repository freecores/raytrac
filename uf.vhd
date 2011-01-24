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
	
	signal stage0mf00,stage0mf01,stage0mf10,stage0mf11,stage0mf20,stage0mf21,stage0mf30,stage0mf31,stage0mf40,stage0mf41,stage0mf50,stage0mf51 : std_logic_vector(17 downto 0); 
	signal stage0p0,stage0p1, stage0p2, stage0p3, stage0p4, stage0p5 : std_logic_vector(31 downto 0);
	signal stage0opcode : std_logic;
	
	--Stage 1 signals 
	
	signal stage1p0, stage1p1, stage1p2, stage1p3, stage1p4, stage1p5 : std_logic_vector (31 downto 0);
	signal stage1a0, stage1a1, stage1a2 : std_logic_vector (31 downto 0);
	signal stage1opcode : std_logic;
	
	-- Some support signals
	signal stage1_internalCarry	: std_logic_vector(2 downto 0);
	signal stage2_internalCarry : std_logic_vector(1 downto 0);
	
	--Stage 2 signals
	
	signal stage2a0, stage2a2, stage2a3, stage2a4, stage2p2, stage2p3 : std_logic_vector (31 downto 0);
	
	  	
	
begin

	-- Multiplicator Instantiation (StAgE 0)
	
	m0 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> stage0mf00,
		datab	=> stage0mf01,
		result	=> stage0p0
	);
	m1 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> stage0mf10,
		datab	=> stage0mf11,
		result	=> stage0p1
	);
	m2 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> stage0mf20,
		datab	=> stage0mf21,
		result	=> stage0p2
	);
	m3 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> stage0mf30,
		datab	=> stage0mf31,
		result	=> stage0p3
	);
	m4 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> stage0mf40,
		datab	=> stage0mf41,
		result	=> stage0p4
	);
	m5 : r_a18_b18_smul_c32_r 
	port map (
		aclr	=> rst,
		clock	=> clk,
		dataa	=> stage0mf50,
		datab	=> stage0mf51,
		result	=> stage0p5
	);
	
	-- Adder Instantiation (sTaGe 1)
	
	--Adder 0, low adder 
	a0low : adder 
	generic map (
		16,"CLA","YES"	--Carry Look Ahead Logic (More Gates Used, But Less Time)
						--Yes instantiate Xor gates stage in the adder so we can substract on the opcode signal command.
	)
	port map	(
		a => stage1p0(15 downto 0),
		b => stage1p1(15 downto 0),
		s => stage1opcode,
		ci => '0',
		result => stage1a0(15 downto 0),
		cout =>	stage1_internalCarry(0)
	);
	--Adder 0, high adder
	a0high : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "YES"	--Yes instantiate Xor gates stage in the adder so we can substract on the opcode signal command.
	)
	port map	(
		a => stage1p0(31 downto 16),
		b => stage1p1(31 downto 16),
		s => stage1opcode,
		ci => stage1_internalCarry(0),
		result => stage1a0(31 downto 16),
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
		a => stage1p2(15 downto 0),
		b => stage1p3(15 downto 0),
		s => stage1opcode,
		ci => '0',
		result => stage1a1(15 downto 0),
		cout =>	stage1_internalCarry(1)
	);
	--Adder 1, high adder
	a1high : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "YES"	--Yes instantiate Xor gates stage in the adder so we can substract on the opcode signal command.
	)
	port map	(
		a => stage1p2(31 downto 16),
		b => stage1p3(31 downto 16),
		s => stage1opcode,
		ci => stage1_internalCarry(1),
		result => stage1a1(31 downto 16),
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
		a => stage1p4(15 downto 0),
		b => stage1p5(15 downto 0),
		s => stage1opcode,
		ci => '0',
		result => stage1a2(15 downto 0),
		cout =>	stage1_internalCarry(2)
	);
	--Adder 2, high adder
	a2high : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "YES"	--Yes instantiate Xor gates stage in the adder so we can substract on the opcode signal command.
	)
	port map	(
		a => stage1p4(31 downto 16),
		b => stage1p5(31 downto 16),
		s => stage1opcode,
		ci => stage1_internalCarry(2),
		result => stage1a2(31 downto 16),
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
		a => stage2a0(15 downto 0),
		b => stage2p2(15 downto 0),
		s => '0',
		ci => '0',
		result => stage2a3(15 downto 0),
		cout =>	stage2_internalCarry(0)
	);
	--Adder 3, high adder
	a3high : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "NO"		--No Just Add.
	)
	port map	(
		a => stage2a0(31 downto 16),
		b => stage2p2(31 downto 16),
		s => '0',
		ci => stage2_internalCarry(0),
		result => stage2a3(31 downto 16),
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
		a => stage2p3(15 downto 0),
		b => stage2a2(15 downto 0),
		s => '0',
		ci => '0',
		result => stage2a4(15 downto 0),
		cout =>	stage2_internalCarry(1)
	);
	--Adder 4, high adder
	a4high : adder 
	generic map (
		w => 16,
		carry_logic 		=> "CLA",	--Carry Look Ahead Logic (More Gates Used, But Less Time)
		substractor_selector	=> "NO"		--No Just Add.
	)
	port map	(
		a => stage2p3(31 downto 16),
		b => stage2a2(31 downto 16),
		s => '0',
		ci => stage2_internalCarry(1),
		result => stage2a4(31 downto 16),
		cout =>	open
	);	
					
	-- Incoming from opcoder.vhd signals into pipeline's stage 0.
	stage0mf00 <= m0f0;
	stage0mf01 <= m0f1;
	stage0mf10 <= m1f0;
	stage0mf11 <= m1f1;
	stage0mf20 <= m2f0;
	stage0mf21 <= m2f1;
	stage0mf30 <= m3f0;
	stage0mf31 <= m3f1;
	stage0mf40 <= m4f0;
	stage0mf41 <= m4f1;
	stage0mf50 <= m5f0;
	stage0mf51 <= m5f1;
	
	-- Signal sequencing: as the multipliers use registered output and registered input is not necessary to write the sequence of stage 0 signals to stage 1 signals.
	-- so the simplistic path is taken: simply connect stage 0 to stage 1 lines. However this would not apply for the opcode signal
	stage1p0 <= stage0p0;
	stage1p1 <= stage0p1;
	stage1p2 <= stage0p2;
	stage1p3 <= stage0p3;
	stage1p4 <= stage0p4;
	stage1p5 <= stage0p5;
	 
	
	--Outcoming to the rest of the system (by the time i wrote this i dont know where this leads to... jeje)
	cpx <= stage1a0;
	cpy <= stage1a1;
	cpz <= stage1a2;
	dp0 <= stage2a3;
	dp1 <= stage2a4;
	
	-- Looking into the design the stage 1 to stage 2 are the sequences pipe stages that must be controlled in this particular HDL.
	uf_seq: process (clk,rst,opcode)
	begin
		
		if rst=rstMasterValue then 
			stage0opcode	<= '0';
			stage1opcode	<= '0';
			
			stage2a2 <= (others => '0');
			stage2p3 <= (others => '0');
			stage2p2 <= (others => '0');
			stage2a0 <= (others => '0');
		
		elsif clk'event and clk = '1' then 
		
			stage2a2 <= stage1a2;
			stage2p3 <= stage1p3;
			stage2p2 <= stage1p2;
			stage2a0 <= stage1a0;
			
			-- Opcode control sequence
			stage0opcode <= opcode;
			stage1opcode <= stage0opcode;
					
		end if;
	end process uf_seq;
	uf_seq2: process (clk,rst,stage0opcode)
	begin
		
		if rst=rstMasterValue then
		
		
		elsif clk'event and clk='1' then
			
		
		end if;
		
	end process uf_seq2;
	
	
	
end uf_arch;
