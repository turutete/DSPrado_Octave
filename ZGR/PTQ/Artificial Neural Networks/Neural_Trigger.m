## -*- texinfo -*-
##
## Neural_Trigger.m
##
## Esta funci�n ejecuta la l�gica de disparo de redes neuronales.
##
## Los par�metros de entrada son:
##
## X: Vector de N entradas X [Na x 1].
## P: Matriz de pesos  P=[Nb X Na].
## B: Bias de las neuronas B=[Nb 1].
## D: Cadena de caracteres de selecci�n de la funci�n de disparo:
##
##    "sigm"
##    "tanh"
##    "relu"
##    "leak"
##    "soft"
##    "step"
##
## La funci�n retorna el valor resultante de aplicar la funci�n de disparo a
## yout=F(P*X+B)
##
## Author: Dr. Carlos Romero P�rez
## Created: 2025-04-08
## Copyright (C) 2025 Zigor R&D AIE
##
## @deftypefn {} {@var{yout} =} Neural_Trigger (@var{X}, @var{P}, @var{B},@var{strfuncion})
##
## @end deftypefn


function yout = Neural_Trigger (X,P,B,strfuncion)

  if (isnumeric(X)==false || isnumeric(P)==false || isnumeric(B)==false)
    error("Los par�metros de entrada X, P y B deben ser num�ricos");
  endif

  if (ischar(strfuncion)==false)
    error("El par�metro de entrada strfuncion debe ser una de las cadenas soportadas");
  endif

  if (length(strfuncion)!=4)
    error("Nombre de la funci�n incorrecta");
  endif

  if (isvector(X)==false || isvector(B)==false)
    error("Los par�metros de entrada X y B deben ser vectores");
  endif

  [fil1,col1]=size(X);
  [fil2,col2]=size(P);
  [fil3,col3]=size(B);

  if (col1!=1 || col3!=1)
    error(" Los par�metros de entrada X y B deben vectores filas ");
  endif

  if (col2!=fil1 || fil3!= fil2)
    error("Las dimensiones de X, P y B son incorrectas");
  endif


  yin=P*X+B;

  if (strfuncion=="step")
    yout=double(yin);
  elseif (strfuncion=="soft")
    yout=log(1.+ exp(yin));
  elseif (strfuncion=="leak")
    yout=max(yin, 0.01.*yin);
  elseif (strfuncion=="relu")
    yout=max(0,yin);
  elseif (strfuncion=="tanh")
    yout=tanh(yin);
  elseif (strfuncion=="sigm")
    yout=1.0./(1.0+exp(-yin));
  else
    error("Funci�n no soportada");
  endif

endfunction
