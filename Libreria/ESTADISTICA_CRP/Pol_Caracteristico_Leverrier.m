##
##  Pol_Caracteristico_Leverrier.m
##
##  Prototipo: P=Pol_Caracteristico_Leverrier(M)
##
##  M: Matriz cuadrada mxm
##  P= Vector mx1 de coeficientes del polinomio característico
##
##  Esta función calcula los coeficientes mediante el método de
##  Leverrier.
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

function P = Pol_Caracteristico_Leverrier (M)
  
  % Control de entrada
  if (isnumeric(M)==false)
    error("El parámetro de entrada debe ser una matriz numérica");
  endif
  
  [fil,col]=size(M);
  if (fil!=col)
    error("La matriz debe ser cuadrada");
  endif
  
  % Cálculo del vector de trazas
  for (i=1:fil)
    S(i)=trace(M^i);
  endfor
  % Algoritmo iterativo
  P(1)=1;
  P(2)=-S(1);
  for i=2:fil
    P(i+1)=-S(i)/i;
    for j=1:(i-1)
      P(i+1)=P(i+1)-S(i-j)*P(j+1)/i;
    endfor
  endfor

endfunction
