## -*- texinfo -*-
##
## Arco_D_break.m
##
## @deftypefn {} {@var{dbreak} =} Arco_D_break (@var{vbreak}, @var{p},@var{A},@var{B},@var{gamma})
##
## Esta función calcula la distancia de breakdown a la que se iniciaría
## un arco eléctrico en un medio gaseoso, habiendo una diferencia de potencial
## entre dos condutores de Vbreak.
##
## Se utiliza la ley de Paschen:
##
## Vbreak= (B*p*d)/(ln(A*p*d)-ln(ln(1+1/gamma)))
##
## siendo A, B, gamma constantes experimentales
## características del gas, p la presión y d la distancia entre conductores.
##
## Los parámetros de entrada de la función son:
##
## vbreak: Diferencia de potencial entre conductores, a la que se quiere calcular
##        la distancia de ruptura en [v]
## p: presión atmosférico en [atm]
## A: coeficiente A de Pashen en [1/m 1/mT]
## B: coeficiente B de Pashen en [V/(m mT)]
## gamma: coeficiente de ionización secundario (Towsend)
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
    error("Los parámetros de entrada deben ser escalares");
  endif

  if (p<=0 || A<=0 || B<=0 || gamma<=0)
    error("Los parámetros deben ser positivos");
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
      error("Resultado no es número real");
    endif
    if(D==0)
      error("División por cero");
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

%  disp("Nº Iteraciones="); disp(trials);

%  plot(err_vect);xlabel("Iteración");ylabel("error")

endfunction
