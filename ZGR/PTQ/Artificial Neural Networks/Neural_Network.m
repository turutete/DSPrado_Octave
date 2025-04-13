# -*- texinfo -*-
##
## Neural_Network.m
##
## Esta función procesa N señales de entrada mediante una red neuronal
## aribitraria, formada por L capas, cada una de ellas formadas por
## Nl neuronas, más el nivel inicial l=0 que son las N0 señales de entrada
##
## Los pesos y bias entre niveles de neuronas se introducen mediante las matrices Ml
## de la forma
##
##  Ml=[Pl Bl]
##
## siendo Pl la submatriz de pesos dedes en nivel l-1 al nivel l y Bl la matriz
## de bias de las neuronas del nivel l, de dimensión [NlX1].
##
## Cada matriz Pl será de dimensión Nl X N(l-1), siendo Nl el número
## de neuronas del nivel l y N(l-1) es el nº neuronas del nivel l-1.
##
## Por ejemplo. Una red con 2 señales de entrada, 3 capas de neuronas intermedias
## de 4, 3 y 1 neuronas respectivamente, las dimensiones de las matrices de
## pesos serán P1 [4 X 2] , P2 [3 X 4], P3 [1 X 3]
##
## Las matrices M1 [4 X 3], M2 [3 X 5] y M3 [1 X 4]
##
## Los parámetros de entrada de la función es la matriz X [N0 X K], que son las N0
## señales de entrada, de longitud K cada una de ellas, y las matrices  Ml de
## cada nivel M1, M2, ...ML.
##
## Esta función devuelve la matriz R [NL X K], siendo cada fila f de la matriz
## la salida de la neurona f de la última capa, y resultado de la lógica.
##
## Author: Dr. Carlos Romero Pérez
## Created: 2025-04-08
## Copyright (C) 2025  Zigor R&D AIE
##
## @deftypefn {} {@var{R} =} Neural_Network (@var{X}, @var{M1}, @var{M2}, ...)
##
## @end deftypefn



function R = Neural_Network (X,varargin)

  trigger="sigm";

  if (isempty(varargin)==false)
    L=length(varargin);
    for ind=1:L
      if (isnumeric(varargin{ind})==false)
        error("Las matrices de pesos deben ser numéricas");
      endif
      dimension(ind,:)=size(varargin{ind});
    endfor
  else
    error("Debe introducirse al menos la matriz de pesos del nivel de salida");
  endif

  if (isnumeric(X)==false)
    error("El parámetro de entrada X debe ser numérico");
  endif

  if (ismatrix(X)==false)
    error("El parámetro de entrada X debe ser una matriz");
  endif

  [fil,col]=size(dimension);

  for ind=1:fil-1
    if (dimension(ind,1)!=(dimension(ind+1,2)-1))
      error("La dimensión de las matrices no es correcta");
    endif
  endfor

  [S,K]=size(X);

  Xaux=X;


  for l=1:L
    % Se efectua este bucle para cada nivel de la red
    Maux=varargin{l};
    [fil,col]=size(Maux);
    P=Maux(1:fil,1:(col-1));
    B=Maux(:,col);
    R=[];
    % Calcula las señales resultantes de la red del nivel l
    for k=1:K
      Xin=Xaux(:,k);
      Yaux=Neural_Trigger(Xin,P,B,trigger);
      R(:,k)=Yaux;
    endfor
    Xaux=R;
  endfor

endfunction


