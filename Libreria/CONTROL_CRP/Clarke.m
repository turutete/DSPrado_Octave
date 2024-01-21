##
##  ClarkePark.m
##
##  Prototipo:  Mout=Clarke(Va,Vb,Vc)
##
##  Mout=[Valfa Vbeta Vhomo]'
##
##  Descripción
## -------------
##
##  Esta función realiza las transformaciones de Clarke de 3 señales
##  de entrada, que se suponen formar un sistema trifásico.
##
##                                       |1         -1/2        -1/2        |
##  Mout=[Valfa Vbeta Vhomo]'=sqrt(2/3) *|0         sqrt(3)/2  -sqrt(3)/2   | * [Va Vb Vc]'
##                                       |1/sqrt(2) 1/sqrt(2)   1/sqrt(2)   |
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

function retval = Clarke (xa,xb, xc)
  
  K=sqrt(2/3);
  
  
  if(isvector(xa)==0 || isvector(xb)==0 || isvector(xc)==0)
    error('Las entradas de la función no son vectores');
  endif
  
  if(isnumeric(xa)==0 || isnumeric(xb)==0 || isnumeric(xc)==0)
    error('Las entradas de la función no son numéricas');
  endif
  
    L=min([length(xa) length(xb) length(xc)]);
    n=1:L;
    
    xalfa(n)=K*(xa(n)+cos(2*pi/3)*xb(n)+cos(-2*pi/3)*xc(n));
    xbeta(n)=K*(sin(2*pi/3)*xb(n)+sin(-2*pi/3)*xc(n));
    xgamma(n)=K/sqrt(2)*(xa(n)+xb(n)+xc(n));

   retval=[xalfa; xbeta; xgamma];

endfunction
