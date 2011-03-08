------------------------------------------------
--! @file
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
use work.arithpack.all;


entity tb is
	
end tb;


ARCHITECTURE tb_arch OF tb IS

	signal qa	: std_logic_vector (53 downto 0);
	signal qb	: std_logic_vector (53 downto 0);
	signal qc	: std_logic_vector (53 downto 0);
	signal qd	: std_logic_vector (53 downto 0);
	signal clock: std_logic;
	signal address: std_logic_vector (8 downto 0);
	
BEGIN
	

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

