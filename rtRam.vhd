

library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.all;

entity rtRam is
	port
	(
		aclr		: in STD_LOGIC  := '0';
		address_a		: in STD_LOGIC_VECTOR (4 downto 0);
		address_b		: in STD_LOGIC_VECTOR (4 downto 0);
		clock		: in STD_LOGIC  := '1';
		data_a		: in STD_LOGIC_VECTOR (17 downto 0);
		data_b		: in STD_LOGIC_VECTOR (17 downto 0);
		wren_a		: in STD_LOGIC  := '0';
		wren_b		: in STD_LOGIC  := '0';
		q_a		: out STD_LOGIC_VECTOR (17 downto 0);
		q_b		: out STD_LOGIC_VECTOR (17 downto 0)
	);
end rtRam;


architecture rtRam_arch of rtRam is

	signal sub_wire0	: STD_LOGIC_VECTOR (17 downto 0);
	signal sub_wire1	: STD_LOGIC_VECTOR (17 downto 0);



	component altsyncram
	generic (
		address_reg_b		: STRING;
		clock_enable_input_a		: STRING;
		clock_enable_input_b		: STRING;
		clock_enable_output_a		: STRING;
		clock_enable_output_b		: STRING;
		indata_reg_b		: STRING;
		intended_device_family		: STRING;
		lpm_type		: STRING;
		numwords_a		: NATURAL;
		numwords_b		: NATURAL;
		operation_mode		: STRING;
		outdata_aclr_a		: STRING;
		outdata_aclr_b		: STRING;
		outdata_reg_a		: STRING;
		outdata_reg_b		: STRING;
		power_up_uninitialized		: STRING;
		ram_block_type		: STRING;
		read_during_write_mode_mixed_ports		: STRING;
		read_during_write_mode_port_a		: STRING;
		read_during_write_mode_port_b		: STRING;
		widthad_a		: NATURAL;
		widthad_b		: NATURAL;
		width_a		: NATURAL;
		width_b		: NATURAL;
		width_byteena_a		: NATURAL;
		width_byteena_b		: NATURAL;
		wrcontrol_wraddress_reg_b		: STRING
	);
	port (
			clock0	: in STD_LOGIC ;
			wren_a	: in STD_LOGIC ;
			address_b	: in STD_LOGIC_VECTOR (4 downto 0);
			data_b	: in STD_LOGIC_VECTOR (17 downto 0);
			q_a	: out STD_LOGIC_VECTOR (17 downto 0);
			wren_b	: in STD_LOGIC ;
			aclr0	: in STD_LOGIC ;
			address_a	: in STD_LOGIC_VECTOR (4 downto 0);
			data_a	: in STD_LOGIC_VECTOR (17 downto 0);
			q_b	: out STD_LOGIC_VECTOR (17 downto 0)
	);
	end component;

begin
	q_a    <= sub_wire0(17 downto 0);
	q_b    <= sub_wire1(17 downto 0);

	altsyncram_component : altsyncram
	generic map (
		address_reg_b => "CLOCK0",
		clock_enable_input_a => "BYPASS",
		clock_enable_input_b => "BYPASS",
		clock_enable_output_a => "BYPASS",
		clock_enable_output_b => "BYPASS",
		indata_reg_b => "CLOCK0",
		intended_device_family => "Cyclone III",
		lpm_type => "altsyncram",
		numwords_a => 32,
		numwords_b => 32,
		operation_mode => "BIDIR_DUAL_PORT",
		outdata_aclr_a => "CLEAR0",
		outdata_aclr_b => "CLEAR0",
		outdata_reg_a => "CLOCK0",
		outdata_reg_b => "CLOCK0",
		power_up_uninitialized => "FALSE",
		ram_block_type => "M9K",
		read_during_write_mode_mixed_ports => "DONT_CARE",
		read_during_write_mode_port_a => "NEW_DATA_NO_NBE_READ",
		read_during_write_mode_port_b => "NEW_DATA_NO_NBE_READ",
		widthad_a => 5,
		widthad_b => 5,
		width_a => 18,
		width_b => 18,
		width_byteena_a => 1,
		width_byteena_b => 1,
		wrcontrol_wraddress_reg_b => "CLOCK0"
	)
	port map (
		clock0 => clock,
		wren_a => wren_a,
		address_b => address_b,
		data_b => data_b,
		wren_b => wren_b,
		aclr0 => aclr,
		address_a => address_a,
		data_a => data_a,
		q_a => sub_wire0,
		q_b => sub_wire1
	);



end rtRam_arch;

