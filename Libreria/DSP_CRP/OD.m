##
##  Prototipo: W = OD(N)
##
##  Esta función ejecuta la transformación de ordenación de diezmado
##  del número entero N en el entero W de acuerdo al siguiente algoritmo:
##          L-1
##  Sea N= Sum nk 2^k
##          k=0
##
##  siendo nk=0 ó 1
##
##  Es decir, (nL-1, nL-2, ...,n1,n0) es la representación binaria de N
##
##  W es también un entero
##      L-1
##  W= Sum wk 2^k
##      k=0
##
##  wL-1=nL-1
##  wk=XOR(nk+1,nk)  k=L-2:0
##
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
## Created: 2022-02-10

function W = OD(N)
  
  % Control del parámetro de entrada
  if (isscalar(N)==false || isnumeric(N)==false || N<0)
    error("El parámetro de entrada N debe ser un entero positivo)");
  endif
  
  Nbin=dec2bin(floor(N));
    
  L=length(Nbin);
  ind=1;
  nprev=uint8(0);
  
  while ind<=L
    n=uint8(bin2dec((Nbin(ind))));
    if (nprev==n)
      wk=uint8(0);
    else
      wk=uint8(1);
    endif
    
    nprev=n;
    
    if (wk==0)
      Wbin(ind)="0";
    else
      Wbin(ind)="1";
    endif
       
    ind=ind+1;
  endwhile
   
   W=bin2dec(Wbin);

endfunction
