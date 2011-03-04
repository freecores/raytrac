

library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.all;

entity tb is
	port
	(
		address		: in STD_LOGIC_VECTOR (3 downto 0);
		clock		: in STD_LOGIC  := '1';
		q		: out STD_LOGIC_VECTOR (17 downto 0)
	);
end mema;


ARCHITECTURE SYN OF mema IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (17 DOWNTO 0);



	COMPONENT altsyncram
	GENERIC (
		address_aclr_a		: STRING;
		clock_enable_input_a		: STRING;
		clock_enable_output_a		: STRING;
		init_file		: STRING;
		intended_device_family		: STRING;
		lpm_hint		: STRING;
		lpm_type		: STRING;
		numwords_a		: NATURAL;
		operation_mode		: STRING;
		outdata_aclr_a		: STRING;
		outdata_reg_a		: STRING;
		ram_block_type		: STRING;
		widthad_a		: NATURAL;
		width_a		: NATURAL;
		width_byteena_a		: NATURAL
	);
	PORT (
			clock0	: IN STD_LOGIC ;
			address_a	: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
			q_a	: OUT STD_LOGIC_VECTOR (17 DOWNTO 0)
	);
	END COMPONENT;

BEGIN
	q    <= sub_wire0(17 DOWNTO 0);

	altsyncram_component : altsyncram
	GENERIC MAP (
		address_aclr_a => "NONE",
		clock_enable_input_a => "BYPASS",
		clock_enable_output_a => "BYPASS",
		init_file => "../../../MinGW/msys/1.0/home/julian/code/memoryMaker/trunk/mema.mif",
		intended_device_family => "Cyclone III",
		lpm_hint => "ENABLE_RUNTIME_MOD=NO",
		lpm_type => "altsyncram",
		numwords_a => 16,
		operation_mode => "ROM",
		outdata_aclr_a => "NONE",
		outdata_reg_a => "CLOCK0",
		ram_block_type => "M9K",
		widthad_a => 4,
		width_a => 18,
		width_byteena_a => 1
	)
	PORT MAP (
		clock0 => clock,
		address_a => address,
		q_a => sub_wire0
	);



END SYN;

