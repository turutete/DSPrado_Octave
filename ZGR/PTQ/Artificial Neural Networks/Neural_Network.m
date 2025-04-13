# -*- texinfo -*-
##
## Neural_Network.m
##
## Esta funci�n procesa N se�ales de entrada mediante una red neuronal
## aribitraria, formada por L capas, cada una de ellas formadas por
## Nl neuronas, m�s el nivel inicial l=0 que son las N0 se�ales de entrada
##
## Los pesos y bias entre niveles de neuronas se introducen mediante las matrices Ml
## de la forma
##
##  Ml=[Pl Bl]
##
## siendo Pl la submatriz de pesos dedes en nivel l-1 al nivel l y Bl la matriz
## de bias de las neuronas del nivel l, de dimensi�n [NlX1].
##
## Cada matriz Pl ser� de dimensi�n Nl X N(l-1), siendo Nl el n�mero
## de neuronas del nivel l y N(l-1) es el n� neuronas del nivel l-1.
##
## Por ejemplo. Una red con 2 se�ales de entrada, 3 capas de neuronas intermedias
## de 4, 3 y 1 neuronas respectivamente, las dimensiones de las matrices de
## pesos ser�n P1 [4 X 2] , P2 [3 X 4], P3 [1 X 3]
##
## Las matrices M1 [4 X 3], M2 [3 X 5] y M3 [1 X 4]
##
## Los par�metros de entrada de la funci�n es la matriz X [N0 X K], que son las N0
## se�ales de entrada, de longitud K cada una de ellas, y las matrices  Ml de
## cada nivel M1, M2, ...ML.
##
## Esta funci�n devuelve la matriz R [NL X K], siendo cada fila f de la matriz
## la salida de la neurona f de la �ltima capa, y resultado de la l�gica.
##
## Author: Dr. Carlos Romero P�rez
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
        error("Las matrices de pesos deben ser num�ricas");
      endif
      dimension(ind,:)=size(varargin{ind});
    endfor
  else
    error("Debe introducirse al menos la matriz de pesos del nivel de salida");
  endif

  if (isnumeric(X)==false)
    error("El par�metro de entrada X debe ser num�rico");
  endif

  if (ismatrix(X)==false)
    error("El par�metro de entrada X debe ser una matriz");
  endif

  [fil,col]=size(dimension);

  for ind=1:fil-1
    if (dimension(ind,1)!=(dimension(ind+1,2)-1))
      error("La dimensi�n de las matrices no es correcta");
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
    % Calcula las se�ales resultantes de la red del nivel l
    for k=1:K
      Xin=Xaux(:,k);
      Yaux=Neural_Trigger(Xin,P,B,trigger);
      R(:,k)=Yaux;
    endfor
    Xaux=R;
  endfor

endfunction


