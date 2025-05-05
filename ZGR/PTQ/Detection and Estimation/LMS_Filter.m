## -*- texinfo -*-
##
## LMS_Filter.m
##
## Esta función implementa in filtro FIR adaptativo. La función
## admite como parámetros de entrada la señal x(n), que es la señal de entrada al
## filtro LMS, la señal de referencia que se desea que la salida del filtro
## minimice el error cuadrático medio, el valor del coeficiente de aprendizaje
## mu, y el número de coeficientes del filtro N.
##
## La función devuelve la señal y(n) que minimiza el error cuadrático medio con
## la señal de referencia.
##
## @deftypefn {} {@var{y} =} LMS_Filter (@var{x}, @var{d}, @var{mu}, @var{N})
## @end deftypefn
##
## Author: Dr. Carlos Romero Pérez
## Created: 2025-04-28
## Copyright (C) 2025 Zigor R&D AIE
##


function y= LMS_Filter (x,d,mu,N)

  if (isnumeric(x)==false || isnumeric(d)==false || isnumeric(mu)==false || isnumeric (N)==false)
    error("Los parámetros de entrada deben ser numéricos");
  endif

  if (isscalar(mu)==false || isscalar(N)==false)
    error("mu y N deben ser escalares");
  endif

  if (N<1)
    error("N debe ser mayor o igual que 1");
  endif

  N=round(N);

  if (isvector(x)==false || isvector(d)==false)
    error("x y d deben ser vectores");
  endif

  W=zeros(1,N);
  Z=zeros(1,N);
  y=zeros(1,N);

  L=min(length(x),length(d));

  % Inicialización de retrasos del filtro
  n=1:N-1;
  Z(N-n+1)=d(n);
  n=N;

  P=1/N*(Z*Z');
  muteo=0.1/(N*P);
  if (mu>muteo)
    disp("El valor de mu puede hacer que sea inestable el filtro");
    disp("El valor máximo aconsejable es"), disp(muteo);
  endif

  while (n<=L)
    %filtrado de nueva muestra de entrada
    Z(1)=d(n);
    dfil=W*Z';

    % Señal de error
    e=x(n)-dfil;
    y(n)=e;

    % Actualización de coeficientes
    W=W+mu*e*Z;

    q=1:(N-1);
    Z(N-q+1)=Z(N-q);
    n=n+1;
  endwhile


endfunction
