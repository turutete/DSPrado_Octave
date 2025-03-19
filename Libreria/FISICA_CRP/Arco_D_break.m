## -*- texinfo -*-
##
## Arco_D_break.m
##
## @deftypefn {} {@var{dbreak} =} Arco_D_break (@var{vbreak}, @var{p},@var{A},@var{B},@var{gamma})
##
## Esta funci�n calcula la distancia de breakdown a la que se iniciar�a
## un arco el�ctrico en un medio gaseoso, habiendo una diferencia de potencial
## entre dos condutores de Vbreak.
##
## Se utiliza la ley de Paschen:
##
## Vbreak= (B*p*d)/(ln(A*p*d)-ln(ln(1+1/gamma)))
##
## siendo A, B, gamma constantes experimentales
## caracter�sticas del gas, p la presi�n y d la distancia entre conductores.
##
## Los par�metros de entrada de la funci�n son:
##
## vbreak: Diferencia de potencial entre conductores, a la que se quiere calcular
##        la distancia de ruptura en [v]
## p: presi�n atmosf�rico en [atm]
## A: coeficiente A de Pashen en [1/m 1/mT]
## B: coeficiente B de Pashen en [V/(m mT)]
## gamma: coeficiente de ionizaci�n secundario (Towsend)
##
## Author: Dr. Carlos Romero
##
## Created: 2025-01-19
## Copyright (C) 2025 Zigor R&D AIE
##
##
## @end deftypefn



function dbreak = Arco_D_break (vbreak,p,A,B,gamma)

  MAX_ITERATIONS=1000;

  if (isscalar(vbreak)==false || isscalar(p)==false || isscalar(A)==false || isscalar(B)==false || isscalar(gamma)==false)
    error("Los par�metros de entrada deben ser escalares");
  endif

  if (p<=0 || A<=0 || B<=0 || gamma<=0)
    error("Los par�metros deben ser positivos");
  endif

  vbreak=abs(vbreak);
  error_max=10^-9;
  flag_loop=0;
  C=log(log(1+1/gamma));
  pt=p*760000;

  xn=0.001;
%  err_vect=[];

  trials=0;


  while(flag_loop==0)
    D=log(A*pt*xn)-C;
    if(iscomplex(D)==true)
      error("Resultado no es n�mero real");
    endif
    if(D==0)
      error("Divisi�n por cero");
    endif

    f=(B*pt*xn/D)-vbreak;
    df=B*pt*(D-1)/D^2;
    if(df==0)
      error("Derivada cero");
    endif

    xn1=xn-(f/df);
    errn=xn1-xn;
    if(abs(errn)<=error_max)
     flag_loop=1;
   else
     trials=trials+1;
     if (trials>MAX_ITERATIONS)
       error('No converge');
     endif
    endif
%    err_vect=[err_vect errn];
    xn=xn1;

  endwhile

  dbreak=xn;

%  disp("N� Iteraciones="); disp(trials);

%  plot(err_vect);xlabel("Iteraci�n");ylabel("error")

endfunction
