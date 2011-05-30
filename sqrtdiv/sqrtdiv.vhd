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


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use ieee.math_real.all;

use work.arithpack.all;


entity sqrtdiv is
	generic (
		reginput: string	:= "YES";
		c3width	: integer	:= 18;
		functype: string	:= "INVERSION"; 
		iwidth	: integer	:= 32;
		owidth	: integer	:= 18;
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
	
	signal funkyq			: std_logic_vector (2*c3width+3 downto 0);
	signal funkyselector	: std_logic;
	
	--! cumpa::Tercera etapa: Selecci'on de valores de acuerdo al exp escogido.
	signal cumpaexp			: std_logic_vector (2*integer(ceil(log(real(iwidth),2.0)))-1 downto 0);
	signal cumpaq			: std_logic_vector (2*c3width+3 downto 0);
	signal cumpaselector	: std_logic;
	signal cumpazero		: std_logic;
		
	signal cumpaN			: std_logic_vector (integer(ceil(log(real(iwidth),2.0)))-1 downto 0);
	signal cumpaF			: std_logic_vector (c3width+1 downto 0);
	
	--! chief::Cuarta etapa: Corrimiento a la izquierda o derecha, para el caso de la ra'iz cuadrada o la inversi'on respectivamente. 
	
	signal chiefN			: std_logic_vector (integer(ceil(log(real(iwidth),2.0)))-1 downto 0);
	signal chiefF			: std_logic_vector (c3width+1 downto 0);
	
	
	--! Constantes para manejar el tama&ntilde;o de los vectores
	constant exp1H : integer := 2*integer(ceil(log(real(iwidth),2.0)))-1;
	constant exp1L : integer := integer(ceil(log(real(iwidth),2.0)));
	constant exp0H : integer := exp1L-1;
	constant exp0L : integer := 0;
	constant add1H : integer := 2*awidth-1;
	constant add1L : integer := awidth;
	constant add0H : integer := awidth-1;
	constant add0L : integer := 0;
	
	
	constant c3qHH : integer := 2*c3width+3;
	constant c3qHL : integer := c3width+2;
	constant c3qLH : integer := c3width+1;
	constant c3qLL : integer := 0;
	
begin
	
	--! expomantis.
	expomantisreg:
	if reginput="YES" generate
		expomantisProc:
		process (clk,rst)
		begin
			if rst=rstMasterValue then
				expomantisvalue <= (others =>'0');
			elsif clk'event and clk='1' then
				expomantisvalue <= value;
			end if;
		end process expomantisProc;
	end generate expomantisreg;
	
	expomantisnoreg:
	if reginput ="NO" generate
		expomantisvalue<=value;
	end generate expomantisnoreg;
	
	expomantisshifter2x:shifter2xstage
	generic map(awidth,iwidth)
	port map(expomantisvalue,expomantisexp,expomantisadd,expomantiszero);
	
	--! funky.
	funkyProc:
	process (clk,rst,expomantisexp, expomantiszero)
	begin
		if rst=rstMasterValue then
			funkyexp <= (others => '0');
			funkyzero <= '0';
			funkyadd <= (others => '0');

		elsif clk'event and clk='1' then
		
			funkyexp(exp1H downto 0) <= expomantisexp(exp1H downto 0);
			funkyzero <= expomantiszero;
			funkyadd <= expomantisadd;
			
		end if;
	end process funkyProc;
	
	funkyget:
	process (funkyexp)
	begin
		if (funkyexp(exp0H downto 0)>funkyexp(exp1H downto exp1L)) then
			funkyselector<='0';
		else
			funkyselector<='1';
		end if;
	end process funkyget;
	
	funkyinversion:
	if functype="INVERSION" generate
		meminvr:func
		generic map (memoryPath&"meminvr.mif")
		port map(
			expomantisadd(awidth-1 downto 0),
			expomantisadd(2*awidth-1 downto awidth),
			clk,
			funkyq(c3qLH-2 downto c3qLL),
			funkyq(c3qHH-2 downto c3qHL));
		funkynibbles:
		process(funkyadd)
		begin
		
			if funkyadd(awidth-1 downto 0) = conv_std_logic_vector(0,awidth) then
				funkyq(c3qLH downto c3qLH-1) <= "10";
			else
				funkyq(c3qLH downto c3qLH-1) <= "01";
			end if;
			if funkyadd(2*awidth-1 downto awidth) = conv_std_logic_vector(0,awidth) then
				funkyq(c3qHH downto c3qHH-1) <= "10";
			else
				funkyq(c3qHH downto c3qHH-1) <= "01";
			end if;
		end process funkynibbles;
		
	end generate funkyinversion;
	funkysquare_root:
	if functype="SQUARE_ROOT" generate
		sqrt: func
		generic map (memoryPath&"memsqrt.mif")
		port map(
			expomantisadd(awidth-1 downto 0),
			(others => '0'),
			clk,
			funkyq(c3qLH-2 downto c3qLL),
			open);
	
		sqrt2x: func
		generic map ("memsqrt2f.mif")
		port map(
			(others => '0'),
			expomantisadd(2*awidth-1 downto awidth),
			clk,
			open,
			funkyq(c3qHH-2 downto c3qHL));
		funkynibbles:
		process(funkyadd)
		begin
			--! Siempre ser'a 2 el nibble mas significativo cuando estemos calculando f**0.5. 
			funkyq(c3qLH downto c3qLH-1) <= "10";
			--! Siempre ser'a 1 el bit mas significativo cuando estemos calculando 2f**0.5.
			funkyq(c3qHH) <= '1';
			if funkyadd(2*awidth-1 downto awidth) >= conv_std_logic_vector(64,awidth) then
				funkyq(c3qHH-1) <= '1';
			else
				funkyq(c3qHH-1) <= '0';
			end if;
		end process funkynibbles;

	end generate funkysquare_root;
	
	--! cumpa.
	cumpaProc:
	process (clk,rst)
	begin
		if rst=rstMasterValue then
			cumpaselector <= '0';
			cumpazero <= '0';
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
			cumpaN<=cumpaexp(exp0H downto exp0L);
			cumpaF<=cumpaq(c3qLH downto c3qLL);
		else
			cumpaN<=cumpaexp(exp1H downto exp1L);					 		
			cumpaF<=cumpaq(c3qHH downto c3qHL);
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
	chiefShifter: RLshifter
	generic map(functype,c3width+2,iwidth,owidth)
	port map(
		chiefN,
		chiefF,
		result);
	
end sqrtdiv_arch;
		
		

	



