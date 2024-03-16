##
## Factorizacion_espectral.m
##
##  Prototipo: [h0;h1]=Factorizacion_espectral(t)
##
##  Esta función realiza la factorización espectral del filtro de banda media
##  T(z), cuyos coeficientes  se pasan como parámetro de entrada t.
##
##  La función devuelve los coeficientes de los filtros H(z) y H(1/z), que son
##  h0 (H(z)) y h1 (H(1/z)) respectivamente.
##
##  h0 es de fase mínima, ya que todos  los ceros están dentro del círculo
##  unidad. h1 es de fase máxima.
##
## Copyright (C) 2024 Dr. Carlos Romero
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
## Author: Dr. Carlos Romero Pérez
## Created: 2024-03-03

function retval = Factorizacion_espectral (t)

if ( isvector(t)==false || isnumeric(t)==false)
  error('El parámetro de entrada t debe ser un vector de coeficientes de un filtro de banda media T(z)'); 
endif

[fil,col]=size(t);

if(fil>col)
  h=t';
else
  h=t;
endif

if (rem(length(h),2)==0)
  error('El número de coeficientes de los filtros de banda media debe ser impar');
endif

L=length(h);

mitad=floor(L/2)+1;

if(h(mitad)!=0.5)
error('El filtro introducido no es un banda media');
endif


# Cálculo de los ceros del polinomio

ceros=roots(h);

Z=length(ceros);

cerop=[];
ceron=[];

# Divide zeros con parte real positiva y negativa.
for z=1:Z
  if (real(ceros(z))<0)
    ceron=[ceron ceros(z)];
  else
    cerop=[cerop ceros(z)];
  endif
  
endfor

P=length(cerop);
N=length(ceron);

zh0=[];
zh1=[];

z=1:floor(N/2);

zh0(z)=ceron(z);
zh1(z)=ceron(z+round(N/2));

for z=1:P
  
  if(abs(cerop(z))<1)
    zh0=[zh0 cerop(z)];
  else
    zh1=[zh1 cerop(z)];
  endif
endfor

# Construcción de los coeficientes de los filtros H0(z) y H1(z)

L=length(zh0);
h0=[1 -zh0(1)];
h1=[1 -zh1(1)];

for l=2:L
  h0=conv(h0,[1 -zh0(l)]);
  h1=conv(h1,[1 -zh1(l)]);
endfor

# Normaliza amplitudes

K=max(t)/max(conv(real(h0),real(h1)));

K0=sqrt(K*max(real(h1))/max(real(h0)));
K1=K/K0;
h0=real(h0)*K0;
h1=real(h1)*K1;

retval=[h0;h1];

  

endfunction
