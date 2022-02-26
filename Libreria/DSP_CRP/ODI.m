##
##  Prototipo: N = ODI(M)
##
##  Esta función ejecuta la transformación de ordenación 
##  de diezmado inversa del número entero M enel entero N de acuerdo
##  al siguiente algoritmo:
##          L-1
##  Sea M= Sum mk 2^k
##          k=0
##
##  siendo mk=0 ó 1
##
##  Es decir, (mL-1, mL-2, ...,m1,m0) es la representación binaria de M
##
##  N es también un entero. M=OperadorDiferencial(N)
##      L-1
##  N= Sum nk 2^k
##      k=0
##
##  nL-1=mL-1
##  CL-1=0
##  Ck=XOR(Ck+1,mk+1)
##  nk=XOR(Ck,mk)  k=L-2:0
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
## Created: 2022-02-13

function N = ODI(M)
  
  % Control del parámetro de entrada
  if (isscalar(M)==false || isnumeric(M)==false || M<0)
    error("El parámetro de entrada M debe ser un entero positivo)");
  endif
  
  Mbin=dec2bin(floor(M));
    
  L=length(Mbin);
  Nbin(1)=Mbin(1);
  cprev=uint8(0);
  mprev=uint8(bin2dec((Mbin(1))));
  ind=2;
  
  while ind<=L
    if (cprev==mprev)
      c=uint8(0);
    else
      c=uint8(1);
    endif
    
    m=uint8(bin2dec((Mbin(ind))));
    
    if (c==m)
      n=uint8(0);
    else
      n=uint8(1);
    endif
    
    if (n==0)
      Nbin(ind)="0";
    else
      Nbin(ind)="1";
    endif
    
    cprev=c;
    mprev=m;
       
    ind=ind+1;
  endwhile
   
   N=bin2dec(Nbin);

endfunction
