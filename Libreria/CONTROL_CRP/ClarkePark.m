##
##  ClarkePark.m
##
##  Prototipo:  Mout=ClarkePark(Va,Vb,Vc,costeta,sinteta)
##
##  Mout=[Vd Vq V0]'
##
##  Descripción
## -------------
##
##  Esta función realiza las transformaciones de Clarke y después de Park
##  de las muestras de las señales trifásicas Va(n), Vb(n), Vc(n).
##  
##  |Vd |   | costeta   sinteta 0 |      | 1  cos(2pi/3)  cos(4pi/3)| |Va|
##  |Vq | = | -sinteta  costeta 0 |* K1* | 0  sin(2pi/3)  sin(4pi/3)|*|Vb|
##  |V0 |   | 0         0       1 |      | K2 K2          K2        | |Vc|
##
## K1=sqrt(2/3). K2=2^(-1/2)
##  
## Copyright (C) 2022 Dr. Carlos Romero
## 
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see
## <https://www.gnu.org/licenses/>.
## Author: Dr. Carlos Romero
## Created: 2022-03-12

function Mout = ClarkePark (Va,Vb,Vc,costeta,sinteta)
  
  Malbet= sqrt(2/3)*[1 cos(2*pi/3) cos(4*pi/3);0 sin(2*pi/3) sin(4*pi/3);1/sqrt(2) 1/sqrt(2) 1/sqrt(2)]*...
  [Va;Vb;Vc];
  Mout=[costeta sinteta 0;-sinteta costeta 0;0 0 1]*Malbet;
  
endfunction
