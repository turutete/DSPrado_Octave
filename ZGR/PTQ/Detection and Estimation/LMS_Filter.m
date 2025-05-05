## -*- texinfo -*-
##
## LMS_Filter.m
##
## Esta funci�n implementa in filtro FIR adaptativo. La funci�n
## admite como par�metros de entrada la se�al x(n), que es la se�al de entrada al
## filtro LMS, la se�al de referencia que se desea que la salida del filtro
## minimice el error cuadr�tico medio, el valor del coeficiente de aprendizaje
## mu, y el n�mero de coeficientes del filtro N.
##
## La funci�n devuelve la se�al y(n) que minimiza el error cuadr�tico medio con
## la se�al de referencia.
##
## @deftypefn {} {@var{y} =} LMS_Filter (@var{x}, @var{d}, @var{mu}, @var{N})
## @end deftypefn
##
## Author: Dr. Carlos Romero P�rez
## Created: 2025-04-28
## Copyright (C) 2025 Zigor R&D AIE
##


function y= LMS_Filter (x,d,mu,N)

  if (isnumeric(x)==false || isnumeric(d)==false || isnumeric(mu)==false || isnumeric (N)==false)
    error("Los par�metros de entrada deben ser num�ricos");
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

  % Inicializaci�n de retrasos del filtro
  n=1:N-1;
  Z(N-n+1)=d(n);
  n=N;

  P=1/N*(Z*Z');
  muteo=0.1/(N*P);
  if (mu>muteo)
    disp("El valor de mu puede hacer que sea inestable el filtro");
    disp("El valor m�ximo aconsejable es"), disp(muteo);
  endif

  while (n<=L)
    %filtrado de nueva muestra de entrada
    Z(1)=d(n);
    dfil=W*Z';

    % Se�al de error
    e=x(n)-dfil;
    y(n)=e;

    % Actualizaci�n de coeficientes
    W=W+mu*e*Z;

    q=1:(N-1);
    Z(N-q+1)=Z(N-q);
    n=n+1;
  endwhile


endfunction
