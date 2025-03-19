## Copyright (C) 2023 Usuario
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
##
## Author: Dr. Carlos Romero
## Created: 2023-04-03

function retval = goertzel (x, N, K)

## Control de argumentos de entrada
if (isnumeric(x) ==0 || isnumeric(N)==0 || isnumeric(K)==0)
  error("Los parámetros de entrada deben ser numéricos");
endif

if(isvector(x)==0)
error("El parámetros x de entrada debe ser un vector");
endif

if(isscalar(N)==0 || N<=0)
error("El parámetro N debe ser un entero positivo)");
endif

if(isscalar(K)==0 || K<0 || K>=N)
error("El parámetro K debe estar en el rano [0 N-1]");
endif

if(isfloat(K)==1)
K=round(K);
endif


[fil,col]=size(x);
if(fil>1)
  xtmp=x';
else
  xtmp=x;
endif

## zero padding
if(N>length(x))
L=N-length(x);
xtmp=[xtmp zeros(1,L)];
endif

## Vector de entrada
xin(1:N)=xtmp(1:N);

xin=[xin 0];

## Fase 1: Filtrado H1(z)=1/(1 - 2cosw0 z^-1 + z^-2)
w0=2*pi*K/N;
alfa=2*cos(w0);

Num=1;
Den=[1 -alfa 1];

s=filter(Num,Den,xin);

## Fase 2: y(N)=s(N)-e^(-jw0) s(N-1)
beta=cos(w0)-j*sin(w0);

retval=(s(N+1)-beta*s(N))*2/N;


endfunction
