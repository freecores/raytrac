--! @file sqrtdiv.vhd
--! @brief Unidad aritm'etica para calcular la potencia de un n'umero entero elevado a la -1 (INVERSION) o a la 0.5 (SQUARE_ROOT).
--! @author Juli&acute;n Andr&eacute;s Guar&iacute;n Reyes.
-- RAYTRAC
-- Author Julian Andres Guarin
-- sqrtdiv.vhd
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


library ieee
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

use work.arithpack.all;


entity sqrtdiv is
	generic (
		reginput: string	:= "YES";
		c3width	: integer	:= 18;
		functype: string	:= "SQUARE_ROOT"; 
		iwidth	: integer	:= 32;
		owidth	: integer	:= 16;
		awidth	: integer	:= 9
	);
	port (
		clk,rst	: in std_logic;
		value	: in std_logic_vector (iwidth-1 downto 0);
		zero	: out std_logic;
		result	: out std_logic_vector (owidth-1 downto 0)
	);
end sqrtdiv;

architecture sqrtdiv_arch of sqrtdiv is

	--! expomantis::Primera etapa: Calculo parcial de la mantissa y el exponente.
	signal expomantisvalue	: std_logic_vector (iwidth-1 downto 0);
	
	signal expomantisexp	: std_logic_vector (2*integer(ceil(log(real(iwidth),2.0)))-1 downto 0);
	signal expomantisadd	: std_logic_vector (2*awidth-1 downto 0);
	signal expomantiszero	: std_logic;
	
	--! funky::Segunda etapa: Calculo del valor de la funcion evaluada en f.
	signal funkyadd			: std_logic_vector (2*awidth-1 downto 0);
	signal funkyexp			: std_logic_vector (2*integer(ceil(log(real(iwidth),2.0)))-1 downto 0);
	signal funkyzero		: std_logic;
	
	signal funkyq			: std_logic_vector (2*c3width-1 downto 0);
	signal funkyselector	: std_logic;
	
	--! cumpa::Tercera etapa: Selecci'on de valores de acuerdo al exp escogido.
	signal cumpaexp			: std_logic_vector (2*integer(ceil(log(real(iwidth),2.0)))-1 downto 0);
	signal cumpaq			: std_logic_vector (2*c3width-1 downto 0);
	signal cumpaselector	: std_logic;
	signal cumpazero		: std_logic;
		
	signal cumpaN			: std_logic_vector (2*integer(ceil(log(real(iwidth),2.0)))-1 downto 0);
	signal cumpaF			: std_logic_vector (c3width-1 downto 0);
	
	--! chief::Cuarta etapa: Corrimiento a la izquierda o derecha, para el caso de la ra'iz cuadrada o la inversi'on respectivamente. 
	
	signal chiefN			: std_logic_vector (2*integer(ceil(log(real(iwidth),2.0)))-1 downto 0);
	signal chiefF			: std_logic_vector (c3width-1 downto 0);
	
	
begin
	
	!-- expomantis.
	expomantisreg:
	if reginput="YES" generate
		expomantisProc:
		process (clk,rst)
		begin
			if rst=rstMasterValue then
				expomantisvalue <= (others =>'0');
			elsif clk'event and clk='1' then
				expomantisvalue <= vale;
			end if;
		end process expomantisProc;
	end generate expomantisreg;
	expomantisnoreg;
	if reginput ="NO" generate
		expomantisvalue<=value;
	end generate expomantisnoreg;
	expomantisshifter2x:shifter2xstage
	generic map(awidth,iwidth)
	port map(expomantisvalue,expomantisexp,expomantisadd,expomantiszero);
	
	--! funky.
	funkyProc:
	process (clk,rst)
	begin
		if rst=rstMasterValue then
			funkyexp <= (others => '0');
			
			funkyzero <= '0';
		else
			funkyexp <= expomantisexp;
			funkyzero <= expomantiszero;
		end if;
	end process funkyProc;
	funkyadd <= expomantisadd;
	funkyget:
	process (funkyexp)
	begin
		if (funkyexp(integer(ceil(log(real(iwidth),2.0)))-1 downto 0)>funkyexp(2*integer(ceil(log(real(iwidth),2.0)))-1 downto integer(ceil(log(real(iwidth),2.0))))) then
			funkyselector<='0';
		else
			funkyselector<='1';
		end if;
	end process funkyget;
	funkyinversion:
	if functype="INVERSION" generate
		meminvr:func
		generic map ("X:/Tesis/Workspace/hw/rt_lib/arith/src/trunk/sqrtdiv/meminvr.mif")
		port map(
			funkyadd(integer(ceil(log(real(iwidth),2.0)))-1 downto 0),
			funkyadd(2*integer(ceil(log(real(iwidth),2.0)))-1 downto integer(ceil(log(real(iwidth),2.0)))),
			clk,
			funkyq(c3width-1 downto 0),
			funkyq(2*c3width-1 downto c3width));
	end generate funkyinversion;
	funkysquare_root:
	if functype="SQUARE_ROOT" generate
		sqrt: func
		generic map ("X:/Tesis/Workspace/hw/rt_lib/arith/src/trunk/sqrtdiv/memsqrt.mif")
		port map(
			funkyadd(integer(ceil(log(real(iwidth),2.0)))-1 downto 0),
			ad1 => (others => '0'),
			clk,
			funkyq(c3width-1 downto 0),
			open);
	
		sqrt2x: func
		generic map ("X:/Tesis/Workspace/hw/rt_lib/arith/src/trunk/sqrtdiv/memsqrt2f.mif")
		port map(
			ad0 => (others => '0'),
			funkyadd(2*integer(ceil(log(real(iwidth),2.0)))-1 downto integer(ceil(log(real(iwidth),2.0)))),
			clk,
			open,
			funkyq(2*c3width-1 downto c3width));
	end generate funkysquare_root;
	
	
	--! cumpa.
	cumpaProc:
	process (clk,rst)
	begin
		if rst=rstMasterValue then
			cumpaselector <= (others => '0');
			cumpazero <= (others => '0');
			cumpaexp <= (others => '0');
			cumpaq <= (others => '0');
		elsif clk'event and clk='1' then
			cumpaselector <= funkyselector;
			cumpazero <= funkyzero;
			cumpaexp <= funkyexp;
			cumpaq <= funkyq;
		end if;
	end process cumpaProc;
	cumpaMux:
	process (cumpaq,cumpaexp,cumpaselector)
	begin
		if cumpaselector='0' then
			cumpaN<=cumpaexp(integer(ceil(log(real(iwidth),2.0)))-1 downto 0);
			cumpaF<=cumpaq(c3width-1 downto 0);
		else
			cumpaN<=cumpaexp(2*integer(ceil(log(real(iwidth),2.0)))-1 downto integer(ceil(log(real(iwidth),2.0))));					 		
			cumpaF<=cumpaq(2*c3width-1 downto c3width);
		end if;
	end process cumpaMux;
	
	--! chief.
	chiefProc:
	process (clk,rst)
	begin 
		if rst=rstMasterValue then
			chiefF <= (others => '0');
			chiefN <= (others => '0');
		elsif clk'event and clk='1' then
			chiefF <= cumpaF;
			chiefN <= cumpaN;
			zero <= cumpazero;
		end if;
	end process chiefProc;
	cumpaShifter: RLshifter
	generic map(functype,c3width,owidth)
	port map(chiefN,chiefF,result);
	
end sqrtdiv_arch;
		
		

	



