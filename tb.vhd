------------------------------------------------
--! @file tb.vhd
--! @brief RayTrac TestBench
--! @author Julián Andrés Guarín Reyes
--------------------------------------------------


-- RAYTRAC
-- Author Julian Andres Guarin
-- tb.vhd
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


entity tb is
	
end tb;


ARCHITECTURE tb_arch OF tb IS

	signal qa	: std_logic_vector (53 downto 0);
	signal qb	: std_logic_vector (53 downto 0);
	signal qc	: std_logic_vector (53 downto 0);
	signal qd	: std_logic_vector (53 downto 0);
	signal clock,rst,ena: std_logic;
	signal opcode,addcode:std_logic;
	signal dp0,dp1,cpx,cpy,cpz : std_logic_vector(31 downto 0);
	signal address: std_logic_vector (8 downto 0)
	
BEGIN
	--! Generador de clock.
	clk: clock_gen
	port map (clock,rst); -- Instanciacion simple.

	--! Device Under Test
	dude: raytrac
	generic map ("YES"); -- Entrada registrada, pues la ROM no tiene salida registrada.
	generic port(qa,qb,qc,qd,opcode,addcode,clk,rst,ena,cpx,cpy,cpz,dp0,dp1);
	
	--! Descripcion del test: 512 x (2/clock) productos punto y 1024 x (1/clock) productos cruz.
	thetest:
	process (clk,rst)
		variable addressCounter : integer := 0;
		variable tbs : tbState;
	begin

		if rst=rstMasterValue then
			addressCounter := 0;
			opcode  <= '0';
			addcode <= '1';
			tbs := abcd;
			ena <= '1';
		elsif clk'event and clk = '1' then
			-- Register States when clock went up ...
			
			case tbs is
				when abcd  => 
					address <= address + 1;
					if address = X"000" then
						tbs := axb;
						opcode <= '1';
						addcode <= not(addcode);
					end if;
				when axb => 
					tbs := cxd;
					addcode <= not(addcode);
				when cxd => 
					address  <= address + 1;
					addcode <= not(addcode);
					if address X"000" then 
						wait;
					end if;
				when others =>
			end case;		  
					
		end if;
	end process thetest;
	
	--! 512x18 rom con los componentes ax.
	AX : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\memax.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qa (17 downto 0)
	);

	--! 512x18 rom con los componentes ay.
	AY : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\memay.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qa (35 downto 18) 
	);

	--! 512x18 rom con los componentes az.
	AZ : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\memaz.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qa (53 downto 36) 
	);
	
	--! 512x18 rom con los componentes bx.
	BX : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\membx.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qb (17 downto 0)
	);

	--! 512x18 rom con los componentes by.
	BY : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\memby.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qb (35 downto 18) 
	);

	--! 512x18 rom con los componentes bz.
	BZ : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\membz.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qb (53 downto 36) 
	);	

	--! 512x18 rom con los componentes cx.
	CX : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\memcx.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qc (17 downto 0)
	);

	--! 512x18 rom con los componentes cy.
	CY : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\memcy.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qc (35 downto 18) 
	);

	--! 512x18 rom con los componentes cz.
	CZ : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\memcz.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qc (53 downto 36) 
	);
	
	--! 512x18 rom con los componentes dx.
	DX : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\memdx.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qd (17 downto 0)
	);

	--! 512x18 rom con los componentes dy.
	DY : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\memdy.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qd (35 downto 18) 
	);

	--! 512x18 rom con los componentes dz.
	DZ : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "c:\Mingw\msys\1.0\home\julian\code\testbench\binm\memdz.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 512,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 9,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => qd (53 downto 36) 
	);	

END tb_arch;

