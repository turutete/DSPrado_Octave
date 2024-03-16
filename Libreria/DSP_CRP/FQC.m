##
##  FQC.m  (Conjugate_Quadrature_filters)
##
##  Prototype:  [h0;h1;g0;g1]=FQC(h)
##
##  Esta función calcula los filtros conjugados en cuadratura del filtro LP 
##  de entrada FIR H0(z), cuyos coeficientes son el parámetro de entrada.
##
##  Los fitros FQC de salida son
##  h0=h
##  h1= (-1)^(N-1-n) h0(N-1-n)
##  g0 = 2 h0(N-1-n)
##  g1 = 2 (-1)^n h0(n)
##
## Copyright (C) 2024 Dr. Carlos Romero
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
## Author: Dr. Carlos Romero Pérez
## Created: 2024-03-03

function retval = FQC (h)
  
  if (isvector(h)==false || isnumeric(h)==false)
    error('El parámetro de entrada debe ser un vector de coeficientes de un filtro FIR');
  endif
  
 [fil, col]=size(h);
 
 if (fil>col)
   h0=h';
 else
   h0=h;
 endif
 
  L=length(h0);
  
  for l=1:L
    h1(l)= (-1)^(L-1-(l-1))* h(L+1-l);
    g0(l) = 2* h(L+1-l);
    g1(l) = 2*(-1)^(l-1)* h(l);
  endfor
  
  retval=[h0;h1;g0;g1];

endfunction
