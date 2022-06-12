##
##  Esperanza.m
##
##  Prototipo: E=Esperanza(x)
##
##  x: vector de L muesras de una variable aleatoria 
##  E: Esperanza
##                L
##     E(x)= 1/L sum (xi)
##                i=1
## 
## Copyright (C) 2022 Carlos Romero
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
## Created: 2022-05-22

function E = Esperanza (x)
  
  %Control de entrada
  if (isnumeric(x)==false)
    error("La entrada no es numérica");
  endif
  
  if (isvector(x)==false)
    error("La entada debe ser un vector");
  endif
  
  [fil,col]=size(x);
  if (fil>col)
    L=fil;
    x=x';     % Trabajamos con vectores 1 X L
  else
    L=col;
  endif
    
  suma=ones(L,1);
  
  E=(x*suma)/L;

endfunction
