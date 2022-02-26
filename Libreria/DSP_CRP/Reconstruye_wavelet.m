## Copyright (C) 2021 Dr. Carlos Romero
## 
##  [h0,h1] = Reconstruye_wavelet(wm0, itera)
##
##  wm0: Coeficientes h0 de  la función de escalado
##  itera: Número de iteraciones para construir la wavelet (>=0)
##  h0: Funcion de escalado reconstruida
##  h1: Wavelet reconstruida
##
##
##  Descripción
##  ------------
##  Esta función calcula los coeficientes de los filtros LP (h0(z)) y
##  HP (h1(z)) para calcular la DWT utilizando una estructura en árbol
##  diádica  (Octave filter bank) [1].
##  
##  h0 y h1 son los coeficientes de la función de escalado y d la wavelet
##  respectivamente.
##
##  El orden de los filtros h0 y h1 resultante será:
##
##  M=(2^itera+1)*N
##
## siendo N el rden de la wavelet madre wm0
## 
##  Referencias:
##  [1]: Multirate Digital Signal Processing. N.J Fliege. John Wiley &Sons 1994.
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
## Created: 2021-12-08

function [h0,h1] = Reconstruye_wavelet(wm0, it)

itera=(int8)(it);

if(isnumeric(wm0)==false)
  error("El vector wm0 no es numérico");
endif

if (itera<0)
  error("La variable itera debe ser positiva o cero");
endif


h00=sqrt(2)*wm0;
veces=(int8)(1);

N=length(h00);
n=1:N;

h10(n)=(-1).^(N-n).*h00(N-n+1);

h0conv=h00;
h1conv=h10;
h0i=[];
h1i=[];

while (veces<=itera) 
  L=length(h0conv);
  k=1:L;
  figure(2*veces-1);plot(k-1,h0conv);
  figure(2*veces);plot(k-1,h1conv);
  h0conv*ones([L 1])
  h1conv*ones([L 1])
  
  h0i(2^veces *(n-1)+1)=h00(n);
  h1i(2^veces * (n-1)+1)=h10(n);
  
  h0conv=conv(h0conv,h0i);
  h1conv=conv(h1conv,h1i);
  
  h0i=[];
  h1i=[];
  
  veces=veces+1;
end

h0=h0conv;
h1=h1conv;

endfunction
