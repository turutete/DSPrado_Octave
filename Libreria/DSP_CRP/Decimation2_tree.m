##
## Prototype: Y=Decimation2_tree(H,L,x)
##
##  Descripci�n
##
##  Esta funci�n descompone la se�al de entrada x(n) en 2^L se�ales 
## Y=[y1(m) y2(m) ... yL(m)]'
##  muestreadas a una tasa de muestreo 1/L respecto a la se�al de entrada.
##
## Se utiliza una estructura en �rbol de L niveles para efectuar la
## descomposici�n y diezmado por 2 en cada nivel.
##
## El filtro FIR H(z) de entrada debe ser un filtro LP que elimine
## frecuencias superiores a pi/2. Internamente, se genera un filtro
##  paso de alto Hhp(z)=H(-z).
##
##  Esta funci�n puede ser utilizada tambi�n para DWT, si los coeficientes
##  de H(z) corresponden a la funci�n de escalado.
##  
##  Si el tama�o de la se�al de entrada es Nx, la longitud de los vectores
##  de salida yl(m) (l=1:L) ser� Ny=2^(floor(log2(Nx))).
##
##  Si la longitud de la se�al de entrada es inferior a 2^L, la se�al de
##  entrada se completa hasta esta longitud con ceros.
##
## Copyright (C) 2022 Carlos Romero P�rez
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
##
## Author: Dr. Carlos Romero
## Created: 2022-02-04

function Y = Decimation2_tree (h,L,x)
  
  pkg load signal;
  
  % Control de par�metros de entrada
  if (isvector(h)==false || isnumeric(h)==false)
    error("El par�metro de entrada H(z) debe ser un vector num�rico");
  endif
  
  if (isnumeric(L)==false || isscalar(L)==false || L<=0)
    error("El par�metro L debe ser un escalar positivo");
  endif
  
  if (isvector(x)==false || isnumeric(x)==false)
    error("El par�metro x(n) debe ser un vector num�rico");
  endif
  
  % Comprobaci�n de la longitud del vector de entrada
  Nx=length(x);
  
  if (Nx<2^L)
    xin=zeros(1,2^L);
    xin(1:Nx)=x(1:Nx);
  else
    Nmax=2^(floor(log2(Nx)));
    xin(1:Nmax)=x(1:Nmax);
  endif
  
  % Generaci�n filtro HP
  for q=1:length(h)
    hhp(q)=(-1)^(q-1)*h(q);
  endfor
  
  
  % Iteraci�n de diezmados
  itera=1;
  Y=xin;
  Nitera=length(xin);
   
  while itera<=L
    rama=1;
    nramas=2^(itera-1);
    Nitera=Nitera/2;
    Yaux=[];
    
    while rama<=nramas
      xaux=Y(rama,:);
      ylp=filter(h,1,xaux);
      yhp=filter(hhp,1,xaux);
            
      q=1:Nitera;
      Yaux(2*rama-1,q)=ylp(2*q-1);
      Yaux(2*rama,q)=yhp(2*q-1);
      
      rama=rama+1;
    endwhile
    
    Y=Yaux;
    itera=itera+1;
  endwhile
     
endfunction
