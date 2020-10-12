##
##  iirtobiquads.m
##
##  Author: Dr.Carlos Romero Pérez
##
##  [Nbiquad,Bvector,Avector]=iirtobiquads(B,A)
##
##  Description
##  ===========
##
##  This function decomposes the IIR input filter defined by the coeffcient
##  vectors [B,A] into a set of biquad filters. In case that the order of the
##  input filter is even, all biquads are order two. If the filter order is
##  odd, the first biquad is actually a first order IIR fiter.
##  
##  Function returns the number of biquads Nbiquad, and two matrix NbiquadX3,
##  Bvector and Avector, being each row the coefficients of a biquad of the
##  numerator (Bvector), and denominator (Avector).
##  
##  Therefore, if the input filter is order 2N, Nbiquad=N. If the filter is 
##  order 2N+1, the number of biquads is Nbiquad=N+1.
##
##  Logger
##  ======
##  13/09/2020: Initial version
##
## Copyright (C) 2020 anabe
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
function [Nbiquad,Bvector,Avector]=iirtobiquads(B,A)

pkg load signal;

# Inputs checking

if (!isnumeric(B) || !isnumeric(A))
  error("B and A must be numeric vectors");
endif

if (!isvector(B) || !isvector(A))
  error("B and A must be vectors");
endif

# Normalizing inputs to 1 X N vectors (row vectors)
[r,c]=size(B);
if r>1
  B=B';
endif

[r,c]=size(A);
if r>1
  A=A';
endif

# Decomposing B and A in zeros and poles
Z=roots(B);
P=roots(A);

# Normalizing size of Z and P vectors
LZ=length(Z);
LP=length(P);

if LZ!=LP
  DLZP=abs(LZ-LP);
  zeropadd=zeros(1,DLZP);
  if LZ>LP
    P=[P' zeropadd]';
  else
    Z=[Z' zeropadd]';
  endif
endif


#Computing the number of biquads
Nmax=length(Z);

remainder=rem(Nmax,2);
Nbiquad=(int16)(Nmax2);

if remainder!=0
  Nbiquad=Nbiquad+1;
endif

# Searching for complex conjugated pairs of zeros and poles and real ones
pused=zeros(size(B)); #pused and zused are flags to mark already used poles
zused=zeros(size(A)); # or zeros. 0=not used, 1=used

ind=1;
indout=1;
xa=Z(ind);

if iscomplex(xa)
  flag_complex=1;
else
  flag_complex=0;
endif


zused(ind)=1;
ind=ind+1;
flag_xa=1;
flag_done=0;

while flag_done==0
  if flag_xa==0
    flag_xa=1;
    xa=Z(ind);
    zused(ind)=1;
  else
    if zused(ind)==0
      xb=Z(ind);
      if (iscomplex(xb) && flag_complex==1)
        if (xb==conj(xa))
          zused(ind)=1;
          Bvector(indout,:)=conv([1 -xa],[1 -xb]);
          indout=indout+1;
          flag_xa=0;
        endif
      endif
    
      if (isreal(xb) && flag_complex==0)
        zused(ind)=1;
        Bvector(indout,:)=conv([1 -xa],[1 -xb]);
        indout=indout+1;
        flag_xa=0;
      endif
        
    ind=ind+1;
    if ind>Nmax
      # If not found the partner and being real, is an alone real zero
      if (isreal(xa))
        zused(ind-1)=1;
        Bvector(indout,:)=[0 1 -xa];
        indout=indout+1;
        flag_xa=0;
      endif
    # Start index searching    
      ind=1;
      if indout>Nbiquad
        flag_done=1;
      endif
    endif
  endif
endwhile

  
    
    
  


endfunction
