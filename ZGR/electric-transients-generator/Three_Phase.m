## -*- texinfo -*-
##
##  Three_Phase.m 
##
##  Función que genera una señal trifásica de amplitud, frecuencia y fase
##  configurable mediante parámetros de entrada.
##
##  El número de muestras de la señal digital de salida es también configurable,
##  así como la frecuencia de muestreo.
##
##  A: Amplitud
##  freq: frecuencia de la señal en Hz
##  phase: Fase inicial de la señal en radianes. Si vale 'aleatorio' se generará
##        aleatoriamente
##  Nsamples: Número de muestras de la señal de salida
##  fasmpling: Frecuencia de muestreo
##
##  Este código es propiedad de ZGR R&D AIE.
##  Su uso está permitido a cualquier trabajador de ZGR R&D AIE, ZGR Corporación
##  o cualquier filial de la empresa matriz.
##
##  El uso del código por cualquier persona ajena a ZGR debe ser consentida por
##  ZGR R&D AIE.
##
## @deftypefn {} {@var{output_vector} =} Three_Phase (@var{A}, @var{freq}, @var{phase},@var{Nsamples},@var{fsampling})
##
## Author: Dr. Carlos Romero Pérez <cromero@@zigor.com>
## Created: 2024-10-05
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function output_vector = Three_Phase (A, freq, phase, Nsamples, fsampling)
  
  % Validación de parámetros de entrada
  
  if(isnumeric(phase)==false)
    if(phase!='aleatorio')
      error('El valor de este parámetro debe estar acotado entre [-2pi 2pi] o ser la cadena "aleatorio"');
    else
      phase=2*pi*(rand(1,1)*2-1);
    endif
  endif
  
  if(isnumeric(A)==false || isnumeric(freq)==false || isnumeric(Nsamples)==false || isnumeric(fsampling)==false)
    error('Los parámtros de entrada deben ser numéricos');
  elseif(A<0|| freq<0 || Nsamples<1 || fsampling<0)
    error('Los parámetros de entrada deben ser positivos');
  endif
  
  if(freq*2>fsampling)
    error('La freuencia de red es mayor que la frecuencia de Nyquist');
  endif
  
  Nsamples=round(Nsamples);
  
  % Generador trifásico
  l=1:Nsamples;
  
  xr=A*sin(2*pi*freq*(l-1)/fsampling+phase);
  xs=A*sin(2*pi*freq*(l-1)/fsampling+phase-2*pi/3);
  xt=A*sin(2*pi*freq*(l-1)/fsampling+phase+2*pi/3);
  
  output_vector=[xr;xs;xt];
  


endfunction
