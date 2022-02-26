##
##  M= Roots2polyord2(R)
##
##  R: Is a vector containing the roots of a polynomial
##  M: Is a matrix. Each row are the coefficients of an order 2 polynomial
##    created with either, the complex conjugated pairs or pairs of real roots.
##    In case of being an even number of roots, one of the polynomial is an
##    order 1 real polynomial.
##
##  Author: Dr. Carlos Romero Pérez
##  Date:   26/12/2020
##  Status: Verified
## Copyright (C)
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




function M = Roots2polyord2 (R)
  
  ## Checking input correctness
  M=0;
  
  if (isnumeric(R)==false)
    disp("Input must be numeric");
    return;
  endif
  
  if (isvector(R)==false)
    disp("Input must be a vector");
    return;
  endif
  
  if (iscolumn(R)==true)
    R=R';   # Using row vectors
  endif
  
  ## Creating proper M sizing
   L=length(R);
   
   if (rem(L,2)==0)
     M=zeros(L/2,3);
   else
     M=zeros((L-1)/2+1,3);
   endif
  
  ## Algorithm
  Rused=zeros(size(R)); ## 0: not used, 1:used
  
  flag_done=false;
  flag_complex=false;
  
  ## First phase is to find the complex conjugated pairs and computes the
  ## order 2 polynomials
  
  index=1;
  mindex=1;
  
  while (flag_done== false)
    if (flag_complex==false)
      if (Rused(index)==0)
        ## Looking for a non used complex roots
        if (iscomplex(R(index))==true)
          pair1=R(index);
          Rused(index)=1;
          flag_complex=true;
        endif
        index=index+1;
        if (index>L)
          if (flag_complex==false)
            flag_done=true; ## There aren't more complex roots
          else
            ## There is a non paired complex roots
            disp("Error. There is one unpaired complex root");
            return;
          endif
        endif
        
      else
        index=index+1;
        if (index>L)
          ## There aren't more non used complex roots
          flag_done=true;
        endif
      endif
    else
      ## Looking for the complex conjugated pair
      if (Rused(index)==0)
        if (R(index)==conj(pair1))
          pair2=R(index);
          Rused(index)=1;
          flag_complex=false;
          M(mindex,:)=conv([1 -pair1],[1 -pair2]);
          mindex=mindex+1;
          index=0;  ## Start from beginning looking for a complex root
        endif
      endif
      
      index=index+1;
        if (index>L)
          if (flag_complex==true)
            ## There is a non paired complex root
            disp("Error. There is one unpaired complex root");
            return;
          else
            ## There are not more complex roots
            flag_done=true;
          endif
        endif 
    endif
    
  endwhile
  
  ## Checking how many real roots remains
  
  totused=L-Rused*Rused';
  index=1;
  flag_real=false;  ## false=looking for a real root. true= looking for second real root
  
  while (totused>0)
    if (flag_real==false)
      if (Rused(index)==0)
        pair1=R(index);
        flag_real=true;
        Rused(index)=1;
        totused=totused-1;
        if (totused==0)
          ## No more real roots pending. The latest is a one order poly
          M(mindex,:)=[0 1 -pair1];
        endif
      endif
    else
      if (Rused(index)==0)
        pair2=R(index);
        flag_real=false;
        Rused(index)=1;
        totused=totused-1;
        M(mindex,:)=conv([1 -pair1],[1 -pair2]);
      endif
    endif
    index=index+1;
    if (index>L)
      index=1;
    endif
    
  endwhile
 
  

endfunction
