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
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;
--use work.arithpack.all;



entity RLshifter is
	generic (
		shiftFunction	: string  := "SQUARE_ROOT"; 
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
			variable expi : integer;
		begin
			expi := conv_integer(exp);
			lupe:
			for i in width-1 downto 0 loop
				if i>expi then 
					result(i)<='0';
				else
					result(i)<=mantis(mantissa_width-1-expi+i);
				end if;
			end loop lupe;
		end process sqroot;
	end generate leftShift;
	rightShift:
	if shiftFunction="INVERSION" generate
		inverse:
		process (mantis,exp)
			variable expi : integer ;
		begin
			expi:= conv_integer(exp);
			
			for i in width-1 downto 0 loop
				if i<=width-1-expi and i>=width-expi-mantissa_width then
					result(i)
					<=mantis(mantissa_width-width+expi+i);
				else
					result(i)<='0';
				end if;
			end loop;
		end process inverse;
	end generate rightShift;
end RLshifter_arch; 