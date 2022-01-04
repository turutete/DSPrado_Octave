function W= DiscreteWT(h0,D,x)
##  
##  DiscreteWT.m
##
##  Prototipo: W= DiscreteWT(h0,D,x)
##
##  x: Se�al de entrada
##  h0: Coeficientes del filtro de transformaci�n H(z)
##  W: Transformada wavelet de la se�al de entrada
##  D: N�mero de dilataciones
##
##  Descripci�n
##
##  Esta funci�n calcula la DWT de la se�al de entrada x(n), utilizando
##  la funci�n wavelet h(n) y D dilataciones.
##
##  Para efectuar la DWT se utiliza el algoritmo piramidal de Mallat [1] 
##  
##  El tama�o del vector de entrada debe ser (2^L). De no ser as�
##  la funci�n utiliza �nicamente los 2^L primeros valores del vector,
##  descartando el resto. El tama�o m�ximo del vector de entrada se fija en
##  16384 (2^14), es decir Lmax=14.
##
##  La resoluci�n de la DWT se controla mediante el par�metro de dilataciones
##  D. En el caso de que D=0, W=x.
##
##  0<=D<=L.
##
##  En el caso de que la entrada D>L (L=floor(log2(length(x)))), la funci�n
##  satura el valor de D=L.
##
##  El vector de salida tiene la siguiente estructura:
##
##  W[ w1
##     w2
##     ...
##     wD
##     sD
##    ]si D>0
##
##  W=x  si D=0
##
##  wi (i=1:D) son las DW de x(n), mientras que sD es la funci�n de escalado.
##  Son vectores de dimensi�n [1 2^D], pero muestreadas a diferentes frecuencias
##  (Fsi=Fs/2^i), siendo Fs la frecuencia de muestro de la se�al original x(n).

##  Las se�ales wi y sD (i=2:D) tienen N/2^i muestras, situadas en los
##  �ndices j=2^i*n (n=1:N/2^i) de los vectores wi (o sD). Aunque el resto
##  de �ndices es cero, las se�ales wi no son interpoladas. Esos �ndices cero
##  no son muestras de la se�al.
##
##  Para visualizar el vector de salida, utilizar la funci�n ViewDWT.m de la
##  librer�a.
##
##  Para entender el significado del vector de salida, la DWT analiza la 
##  correlaci�n de la wavelet h0(n) en las siguientes bandas de frecuencia
##  [0 Fs/2^(D+2)][ Fs/2^(D+2) Fs/2^(D+1)] ... [Fs/8 Fs/4][Fs/4 Fs/2]
##       sD                 wD                    w2          w1
##  
##  Las diferentes wavelets que se encuentran en la literatura tienen
##  comportamientos distintos, que las convierten en m�s o menos �tiles
##  para las aplicaciones en las que se utilicen.
##
## Referencias:
##
## [1] S.G. Mallat. "Multifrequency Channel Decompositions of Images 
## and Wavelet Models" IEEE Transactions on Acoustics, Speech, and
## Signal Processing, Vol. 37, No12, pp. 2091-2110, December 1989.
##
## Copyright (C) 2021 cromero
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
## Created: 2021-12-26

pkg load signal;
  
  %Control de los argumentos de entrada
  if nargin()!=3
    error("Incorrecto n�mero de par�metros de entrada. Teclea help DWT para m�s informaci�n");
  elseif (isvector(h0)==false || isvector(x)==false)
    error("h(n) y x(n) deben ser vectores num�ricos");
  elseif (isscalar(D)==false)
    error("El par�metro de dilaci�n D debe ser un escalar");
  elseif (isnumeric(h0)==false || isnumeric(x)==false || isnumeric(D)==false)
    error("h(n), D y x(n) deben ser num�ricos");
  endif
  
  L=floor(log2(length(x)));
  if L>14
    L=14;                   % Tama�o m�ximo del vector de entrada
    disp("Longitud del vector de entrada mayor excede al permitido");
  endif
  N=2^L;                    % La longitud del vector de entradas es 2^L
  
  if D>L
    D=L;                    % M�ximo n�mero de dilataciones
    disp("Excesivo n�mero de dilataciones.");
  endif
  
  n=1:N;
  xin(n)=x(n);
  
  W=[];
  
  if D==0
    W=xin;
    disp("Al ser D=0, no se ha efectuado la transformada. W=x(n)");      
  elseif
    % Filtro h1(n)=(-1)^n h0(n)
    l=1:length(h0)
    h1(l)=(-1).^(l-1).*h0(l);
    
    y0aux=xin;
    
    dilation=1;
    while dilation <=D
      y0=filter(h0,1,y0aux);
      y1=filter(h1,1,y0aux);
      N=N/2;
      n=1:N;
      y1aux=[];
      y0aux=[];
      y1aux(n)=y1(2*n-1);
      y0aux(n)=y0(2*n-1);
      W(dilation,2^dilation * n)=y1aux(n);  % Son se�ales a distinta frecuencia
      dilation=dilation+1;  
    endwhile
    W(dilation,2^(dilation-1) * n)=y0aux(n);
  endif  
  
endfunction
