library ieee;
use ieee.std_logic_1164.all;

entity opcoder is 
	port map (
		Ax,Bx,Cx,Dx,Ay,By,Cy,Dy,Az,Bz,Cz,Dz : in std_logic_vector (17 downto 0);
		m0f0,m0f1,m1f0m1f1,m2f0,m2f1,m3f0,m3f1,m4f0,m4f1,m5f0,m5f1 : out std_logic_vector (17 downto 0);
		opcode,addcode : in std_logic
	);
end entity;

architecture opcoder_arch of opcoder is 
	

begin
	
	opcoder_:
	process (Ax,Bx,Cx,Dx,Ay,By,Cy,Dy,Az,Bz,Cz,Dz,opcode,addcode)
		variable scoder : std_logic_vector (1 downto 0);
	begin 
		scoder := opcode & addcode;
		case (scoder) is
			when "0x" =>
				m0f0 <= Ax;
				m0f1 <= Bx;
				m1f0 <= Ay;
				m1f1 <= By;
				m2f0 <= Az;
				m2f1 <= Bz;
				m3f0 <= Cx;
				m3f1 <= Dx;
				m4f0 <= Cy;
				m4f1 <= Dy;
				m5f0 <= Cz;
				m5f1 <= Dz;
			when "10" =>
				m0f0 <= Ay;
				m0f1 <= Bz;
				m1f0 <= Az;
				m1f1 <= By;
				m2f0 <= Az;
				m2f1 <= Bx;
				m3f0 <= Ax;
				m3f1 <= Bz;
				m4f0 <= Ax;
				m4f1 <= By;
				m5f0 <= Ay;
				m5f1 <= Bx;
			when "11" =>
				m0f0 <= Cy;
				m0f1 <= Dz;
				m1f0 <= Cz;
				m1f1 <= Dy;
				m2f0 <= Cz;
				m2f1 <= Dx;
				m3f0 <= Cx;
				m3f1 <= Dz;
				m4f0 <= Cx;
				m4f1 <= Dy;
				m5f0 <= Cy;
				m5f1 <= Dx;
			when others => 
				m0f0 <= ( others => '0');
		end case;
				
				 
		
		
	
	end process opcoder_;
	

end opcoder_arch;
