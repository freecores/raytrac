------------------------------------------------
--! @file RLshifter.vhd
--! @brief RayTrac Arithmetic Shifter 
--! @author Juli&aacute;n Andr&eacute;s Guar&iacute;n Reyes
--------------------------------------------------


-- RAYTRAC
-- Author Julian Andres Guarin
-- RLshifter.vhd
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



entity RLshifter is
	generic (
		shiftFunction	: string  := "SQUARE_ROOT" 
		mantissa_width	: integer := 18;
		width			: integer := 32
		
	);
	port (
		exp		: in std_logic_vector (integer(ceil(log(real(width),2.0)))-1 downto 0);
		mantis	: in std_logic_vector (mantissa_width-1 downto 0);
		result	: out std_logic_vector (width-1 downto 0)
	);
end RLshifter;


architecture RLshifter_arch of RLshifter is
begin

	leftShift:
	if shiftFunction="SQUARE_ROOT" generate
	
		sqroot:
		process (mantis, exp)
			variable expi : integer := conv_integer(exp);
		begin
			result(width-1 downto expi+1)	<= (others=>'0');
			result(expi	downto 0)			<= mantissa(mantissa_width-1 downto mantissa_width-1-exp);
		end sqroot;
	
	end generate leftShift;
	
	rightShift:
	if shiftFunction="INVERSION" generate
	
		inverse:
		process (mantis,exp)
			variable expi : integer := conv_integer(exp);
		begin
			if expi>0 then
				result (width-1 downto width-expi) <= (others =>'0');
				if expi+mantissa_width<width then 
					result (width-expi-1 downto width-expi-mantissa_width) <= mantis(mantissa_width-1 downto 0);
					result (width-expi-mantissa_width-1 downto 0) <= (others=>'0');
				else
					result (width-expi-1 downto 0) <= mantis(mantissa_width-1 downto mantissa_width+expi-width);
				end if; 
			else
				result (width-1 downto width-mantissa_width) <= mantis(mantissa_width-1 downto 0);
				
		end inverse;

end RLshifter_arch; 