##
##  Matriz_Covarianza
##
##  Prototipo: R=Matriz_Covarianza(X)
##
##  X=[x1 x2 ... xn]'
##  xi: vectores, de longitud arbitraria L, pero todos de la misma longitud
##      i=1:n. Son variables aleatorias
##  
##  R: Matriz de covarianza n x n
##
##    |Var(x1) Cov(x1,x2) ...Cov(x1 xn) |
##    |Cov(x2,x1) Var(x2) ...Cov(x2,xn) |
##  R=|                                 |
##    |Cov(xn,x1) Cov(xn,x2)... Var(xn) |
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

function R = Matriz_Covarianza (X)
  
  % Comprobación de entradas
  if(isnumeric(X)==false)
    error("El parámetro de entrada no es numérico");
  endif
  % X es una matriz N x L, siendo N el nº de variables aleatorias
  % y L el número de muestras de cada vectores.

  [N,L]=size(X);
  
  % R es simétrica: Rij=Rji
  for fil= 1:N
    for col=fil:N
      R(fil,col)=Covarianza(X(fil,:),X(col,:));
      if (fil!=col)
        R(col,fil)=R(fil,col);
      endif
    endfor
  endfor
  
    
endfunction
