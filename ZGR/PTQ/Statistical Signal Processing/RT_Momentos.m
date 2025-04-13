## -*- texinfo -*-
##
## RT_Momentos
##
## Esta funci�n calcula los 4 momentos estad�sticos de la se�al de entrada x(n).
##
## El c�lculo se efectua muestra a muestra, en tiempo real, no mediante c�lculo
## mediante vectores.
##
## El n�mero de muestras para calcular los momentos estad�sticos N es un par�metro
## de entrada.
##
## La funci�n devuelve la matriz M [4 X N], siendo cada fila un momentos:
##
## M(1,:) mu: Valor medio
## M(2,:) sigma2: Varianza
## M(3,:) asim: As�metr�a
## M(4,:) cur: Curtosis
##
## Dado que las se�ales se computan muestra a muestra, mediante filtros digitales,
## hasta que no se procesan 2N muestras, necesarias para tener un valor correcto
## del valor medio mu, y de la desviaci�n (sqrt(sigma2)).
##
##
## @deftypefn {} {@var{M} =} RT_Momentos (@var{x}, @var{N})
##
## @end deftypefn
##
## Author: Dr. Carlos Romero P�rez
## Created: 2025-04-04
## Copyright (C) 2025 Zigor R&D AIE
##

function M = RT_Momentos (x, N)

  if (isnumeric(x)==false || isnumeric(N)==false)
    error("Los par�metros de entrada deben ser num�ricos");
  endif

  if (isvector(x)==false)
    error("El par�metro x debe ser un vector");
  endif

  if (isscalar(N)==false)
    error("El par�metro N debe ser un escalar");
  endif

  N=round(N);
  L=length(x);

  coef=ones(N,1)/N;

 % Primer momento: Valor medio mu=1/N*sum(x(n))
  mu=filter(coef,1,x);

  % Segundo momento: Varianza sigma2=1/N*sum((x-mu)^2)
  xaux=(x-mu);
  xaux2=xaux.^2;
  sigma2=filter(coef,1,xaux2);

  % Tercer momento: Asimetr�a asim=1/N*sum(((x-mu)/sigma)^3)
  sigma=sqrt(sigma2);
  xaux3=(xaux./sigma).^3;

  asim=filter(coef,1,xaux3);

  % Cuarto momento: Curtosis  cur=1/N * sum(((x-mu)/s)^4)
  xaux4=(xaux./sigma).^4;

  cur=filter(coef,1,xaux4);

  M= [mu; sigma2; asim; cur];


endfunction
