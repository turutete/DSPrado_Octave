##
##  Varianza.m
##
##  Prototipo: C=Covarianza(x1,x2)
##
##  x1, x2: Son 2 variables aleatorias de L muestras cada una.
##
##  C= Si x1 != x2, es la covarianza de x1 y x2.
##        Si x1=x2, es la varianza.
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

function C = Covarianza (x1, x2)
  
  % Comprbación de entradas
  if (isnumeric(x1)==false || isnumeric(x2)==false) 
    error("Las enradas no son numéricas");
   endif
   
   if (isvector(x1)==false || isvector(x2)==false)
     error("Las entradas deben ser vectores");
   endif
   
   % Homogeneizamos a dimensión 1 X L
   [fil1, col1]=size(x1);
   if (fil1>1)
     x1=x1';
   endif
   
 
   [fil2, col2]=size(x2);
   if (fil2>1)
     x2=x2';
   endif
   
   
   if (length(x1)!=length(x2))
     L=min(length(x1),length(x2));
   else
     L=length(x1);
   endif
   
   n=1:L;
   xin1(n)=x1(n);
   xin2(n)=x2(n);
   
   E1=Esperanza(xin1);
   E2=Esperanza(xin2);
   E12=Esperanza(xin1.*xin2);
   C=E12-E1*E2; 
   
endfunction
