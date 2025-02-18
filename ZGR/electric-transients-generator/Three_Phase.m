## -*- texinfo -*-
##
##  Three_Phase.m 
##
##  Funci�n que genera una se�al trif�sica de amplitud, frecuencia y fase
##  configurable mediante par�metros de entrada.
##
##  El n�mero de muestras de la se�al digital de salida es tambi�n configurable,
##  as� como la frecuencia de muestreo.
##
##  A: Amplitud
##  freq: frecuencia de la se�al en Hz
##  phase: Fase inicial de la se�al en radianes. Si vale 'aleatorio' se generar�
##        aleatoriamente
##  Nsamples: N�mero de muestras de la se�al de salida
##  fasmpling: Frecuencia de muestreo
##
##  Este c�digo es propiedad de ZGR R&D AIE.
##  Su uso est� permitido a cualquier trabajador de ZGR R&D AIE, ZGR Corporaci�n
##  o cualquier filial de la empresa matriz.
##
##  El uso del c�digo por cualquier persona ajena a ZGR debe ser consentida por
##  ZGR R&D AIE.
##
## @deftypefn {} {@var{output_vector} =} Three_Phase (@var{A}, @var{freq}, @var{phase},@var{Nsamples},@var{fsampling})
##
## Author: Dr. Carlos Romero P�rez <cromero@@zigor.com>
## Created: 2024-10-05
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function output_vector = Three_Phase (A, freq, phase, Nsamples, fsampling)
  
  % Validaci�n de par�metros de entrada
  
  if(isnumeric(phase)==false)
    if(phase!='aleatorio')
      error('El valor de este par�metro debe estar acotado entre [-2pi 2pi] o ser la cadena "aleatorio"');
    else
      phase=2*pi*(rand(1,1)*2-1);
    endif
  endif
  
  if(isnumeric(A)==false || isnumeric(freq)==false || isnumeric(Nsamples)==false || isnumeric(fsampling)==false)
    error('Los par�mtros de entrada deben ser num�ricos');
  elseif(A<0|| freq<0 || Nsamples<1 || fsampling<0)
    error('Los par�metros de entrada deben ser positivos');
  endif
  
  if(freq*2>fsampling)
    error('La freuencia de red es mayor que la frecuencia de Nyquist');
  endif
  
  Nsamples=round(Nsamples);
  
  % Generador trif�sico
  l=1:Nsamples;
  
  xr=A*sin(2*pi*freq*(l-1)/fsampling+phase);
  xs=A*sin(2*pi*freq*(l-1)/fsampling+phase-2*pi/3);
  xt=A*sin(2*pi*freq*(l-1)/fsampling+phase+2*pi/3);
  
  output_vector=[xr;xs;xt];
  


endfunction
