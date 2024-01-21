## abg_filter.m
##
##  Filtro alfa-beta-gamma
##
##  Sintaxis: yf = abg_filter (xin,fsampling, alfa, beta, gamma, xinit, vinit, ainit)
##
##  xin=señal de entrada
##  fsampling=frecuencia de muestro
##  alfa= parámetro alfa del filtro [0 1]
##  beta= parámetro beta del filtro [0 1]
##  gamma= parámetro gamma del filtro [0 1]
##  xinit=valor estimado inicial de x
##  vinit= valor estimado inicial de la velocidad de cambio de x
##  ainit= valor estimado inicial de la aceleración de cambio de x
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
## Author: Dr. Carlos Romero
## Created: 2024-01-14

function yf = abg_filter (xin,fsampling, alfa, beta, gamma, xinit, vinit, ainit)
  
  % Validaciones
  if (nargin < 8 || nargin > 8)
  print_usage ("El número de argumentos de entrada es erróneo");
  endif
  
  if(isreal(xin) && isreal(fsampling) && isreal(xinit)&& isreal(vinit)&&isreal(ainit) && isreal(alfa) && isreal(beta)&& isreal(gamma))
    if(isvector(xin) && isscalar(fsampling)&& isscalar(xinit)&& isscalar(vinit) && isscalar(ainit)&& isscalar(alfa) && isscalar(beta)&& isscalar(gamma))
      if(alfa>=0 && alfa<=1 && beta>=0 && beta<=1 && gamma>=0 && gamma<=1)
        display("Filtrado Kalman en Progreso");
      else
        print_usage("Error. alfa, beta y gamma deben estar en el rango [0 1]");
      end
    else
      print_usage("Error. Dimensión de los parámetros de entrada incorrectos");
    end
  else
    print_usage("Error. Los parámetros de entrada deben ser eales");
  end
  
  % Algoritmo
  
  %Inicialización
  N=length(xin);
  xn1_n1=xinit;
  vn1_n1=vinit;
  an1_n1=ainit;
  dt=1/fsampling;
  dt2=dt^2;
  
  yf=[];
  
  % Iteraciones
  
  for i=1:N
    % Predicción con la dinámica del sistema
    xn_n1=xn1_n1+vn1_n1*dt+0.5*an1_n1*dt2;
    vn_n1=vn1_n1+an1_n1*dt;
    an_n1=an1_n1;
    
    % Actualización de estados
    xn_n=xn_n1+alfa*(xin(i)-xn_n1);
    vn_n=vn_n1+beta*(xin(i)-xn_n1)*fsampling;
    an_n=an_n1+gamma*(xin(i)-xn_n1)*2*fsampling^2;
    
    %Salida filtrada
    yf=[yf xn_n];
    
    % Nuevo estado anterior
    xn1_n1=xn_n;
    vn1_n1=vn_n;
    an1_n1=an_n;
    
  end
  plot(1:N,xin,1:N,yf);

endfunction
