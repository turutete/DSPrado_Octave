function h = daubechies2_20 (n)
##
##  Prototipo: h=daubechies2_20(n)
##
##  Esta función retorna los coeficientes de la función de escalado de n
##  coeficientes (n par)[1].
##
##  Referencias:
##
##  [1] https://en.wikipedia.org/wiki/Daubechies_wavelet  
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
## Author: Dr. Carlos Romero
## Created: 2021-12-31


  % Tolerancia a fallos en la interfaz de usuario
  if nargin()!=1
    error("Error. La función necesita el parámetro n=número de coeficientes");
  endif
  
  if (isscalar(n)==false)
    error("Error. El parámetro número de coeficientes debe ser escalar");
  endif
  
  if (isnumeric(n)==false)
    error("Error. El parámetro número de coeficientes debe ser numérico");
  endif
  
   
  if (n<=0 || n>20)
    error("El número de coeficientes debe ser un entero par positivo [2 20]");
  endif
  
  if (rem(n,2)!=0)
    n=n-1;
    disp("El número de coeficientes debe ser par. Se ha modificado la entrada a n=");
    disp(n);
  endif
  
  switch (n)
    case 2
      h=[1 1];
    case 4
      h=[0.6830127 1.1830127 0.3169873 -0.1830127];
    case 6
      h=[0.47046721 1.14111692 0.650365 -0.19093442 -0.12083221 0.0498175];
    case 8
      h=[0.32580383 1.01094572 0.89220014 -0.03957503 -0.26450717 0.0436163 0.0465036 -0.01498699];
    case 10
      h=[0.22641898 0.85394354 1.02432694 0.19576696 -0.34265671 -0.04560113 0.10970265 -0.00882680 -0.01779187 4.71742793e-3];
    case 12
      h=[0.15774243 0.69950381 1.06226376 0.44583132 -0.31998660 -0.18351806 0.13788809 0.03892321 -0.04466375 7.83251152e-4 6.75606236e-3 -1.52353381e-3];
    case 14
      h=[0.11009943 0.56079128 1.03114849 0.66437248 -0.20351382 -0.31683501 0.1008467 0.11400345 -0.05378245 -0.02343994 0.01774979 6.07514995e-4 -2.54790472e-3 5.00226853e-4];
    case 16
      h=[0.07695562 0.44246725 0.95548615 0.82781653 -0.02238574 -0.40165863 6.68194092e-4 0.18207636 -0.02456390 -0.06235021 0.01977216 0.01236884 -6.88771926e-3 -5.54004549e-4 9.55229711e-4 -1.66137261e-4];
    case 18
      h=[0.05385035 0.34483430 0.85534906 0.92954571 0.18836955 -0.41475176 -0.13695355 0.21006834 0.043452675 -0.09564726 3.54892813e-4 0.03162417 -6.67962023e-3 -6.05496058e-3 2.61296728e-3 3.25814671e-4 -3.56329759e-4 5.5645514e-5];
    case 20
      h=[0.03771716 0.26612218 0.74557507 0.97362811 0.39763774 -0.35333620 -0.27710988 0.18012745 0.13160299 -0.10096657 -0.04165925 0.04696981 5.10043697e-3 -0.01517900 1.97332536e-3 2.81768659e-3 -9.69947840e-4 -1.64709006e-4 1.32354367e-4 -1.875841e-5];
      
  endswitch
  
  

endfunction
