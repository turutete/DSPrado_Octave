##
##  [MN,MD]=Make_biquads(B,A)
##
##  B,A: Numerator and denominator vector, resectively, of the digital filter
##  MN,MD: Matrix of biquads numerators and denominators, respectively
## 
## Author: Dr. Carlos Romero Pérez
## Created: 2020-12-24
##
## Description
## -----------
## Given a digital filter H(z) defined by the numerator coefficients B and
## denominator coefficients A, H(z)=B(z)/A(z), being B=[b0 b1 ...bn] and 
## A=[a0 a1 ...an], this function computes decomposes this function as a product
## of M=N/2 (case N even) or M=(N-1)/2 +1 (case N odd) biquads:
##          M
## H(z) = Prod Hbk(z)
##         k=1
##                 z^-2 + n1k z^-1 + n0k 
## being Hbk(z) = -----------------------
##                  z^-2+d1k z^-1 + d0k
##
## The computed coefficientes are returned as two matrix, MN and MD
##
## MN=[1 n11 n01;1 n12 n02;...;1 n1M n0M]
## MD=[1 d11 d01;1 d12 d02;...;1 d1M d0M]
##
## Copyright (C) 2020 anabe_000
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.

function [MN MD] = Make_biquads (B,A)

## Checking inputs correctness
if (isvector(B)!=TRUE || isvector(A)!=TRUE)
   disp("Inputs must be vector of coeffcients");
   return;
endif

if (isnumeric(B)!=TRUE || isnumeric(A)!=TRUE)
  disp("Inputs must be numeric coefficients");
  return;
endif

## Formatting of B and A as row vectors
if (isrow(B)==FALSE)
  B=B';
endif

if (isrow(A)==FALSE)
  A=A';
endif

## Formatting lengths
LB=length(B);
LA=length(A);

if (LB!=LA)
  NZEROS=abs(LB-LA);
  if (LB>LA)
    A=[A zeros(1,NZEROS)];
  else
    B=[B zeros(1,NZEROS)];
  endif
  
endif

## Computing number of biquads
N=length(B)-1;  ## Both vectors are the same length

if (rem(N,2)==0)
  M=N/2;
else
  M=(N-1)/2+1;
endif



## Computing roots
Z=roots(B);
P=roots(A);

## Generating output matrix 

MB=Roots2polyord2(Z);
MA=Roots2polyord2(P);

endfunction

