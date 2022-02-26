##
## DWT.m
##
## Prototipo: [alfai; betai; betaim1;betaim2;...;beta1]=DWT(h0,Nbands,x)
##
## h0: Coeficientes de la función de escalado
## Nbands: Número de bandas descompuestas
## x: Señal de entrada
##
## Descripción
## -------------
##
## Esta función calcula la DWT de la señal de entrada x(n)
## utilizando la función de escalado definido por los coeficientes h0(n)
## y wavelet h1(n)=(-1)^(N-1-n)*h0(N-1-n) [1]
##
## El parámetro Nbands define el número de subbandas de frecuenca en las
## que se analiza la señal.
##
## Dado un valor de Nbands, el espectro en frecuencias se analiza en
## Nbands+1 bandas:
##
## W0=[0 Fs/2^(Nbands+1)]
## W1=[Fs/2^(Nbands+1) Fs/2^(Nbands)]
## W2=[Fs/2^(Nbands) Fs/2^(Nbands1)]
## ...
## WNbands=[Fs/4 F2/2]
##
## La salida de la función es un vector de Nbands+1 señales
## [x0 x1 x2 ... xNbands]
##
## Cada señal a una tasa de muestreo:
## fsi=fs/2^(Nbands-i+1) (i=1 : Nbands)
## 
## y fs0=fs/2^Nbands
##
## y número de muestras
## 
## Li=L/2^(Nbands-i+1) (i=1: Nbands)
##
## L0=L/2^Nbands
##
## Referencias:
## [1] Multirate Digital Signal Processing. N.J. Fliege. John Wiley & Sons 1993
## Copyright (C) 2021 anabe
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
## Created: 2021-12-12

function retval = DWT (h0, Nbands,x)
  
% Gestión de fallos de datos de entrada
if(isnumeric(h0)==false || isvector(h0)==false)
  error("El parámetro h0 debe ser un vector de coeficientes");
endif

if(isnumeric(Nbands)==false || isscalar(Nbands)==false || Nbands<=0)
  error("El parámetro Nbands debe ser un entero positivo");
endif

if(isnumeric(x)==false || isvector(x)==false)
  error("El parámetro x debe ser un vector numérico");
endif

itera=int8(floor(Nbands));


% Generación de h1(n)
N=length(h0);
n=0:N-1;

h1(n+1)=(-1).^(N-1-n)*h0(N-n);

% Iteración de filtrados. Estructura Octave filter banks

retval=[];
veces=int8(1);

xi=x;

while veces<=itera
  y1=filter(h1,1,xi);
  y0=filter(h0,1,xi);
  L=length(y0);
  L2=floor(L/2);
  q=1:L2;
  betai(q)=y1(2*q-1);   % Diezmado 2
  xi=[];
  xi(q)=y0(2*q-1);      % Diezmado 2
  retval(itera-veces+2,:)=betai(:);
  if(veces==itera)
    retval(1,:)=xi(:);
  endif
  veces=veces+1
endwhile

  
endfunction
