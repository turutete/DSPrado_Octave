## -*- texinfo -*-
##
## Flicker_Transient.m
##
## Esta función modela un evento transitorio de flicker en una línea trifásica,
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los parámatros de entrada a la función son:
##
##  v_input: Es una matriz 3XN donde la fila 1 es la señal vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las señales tienen N muestras
##
##  fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
#
##  fflicker: Esta parámetro es la frecuencia de la moduladora en Hz [0.5 30]
##
##  aflicker: Este parámetro es la amplitud de la moduladora [0.01 0.03]
##
##  tinit: Instante temporal de inicio del evento
##
##  tend: Instante temporal de fin del evento
##
##  La señal de salida v_out es una matriz 3XN, siendo las filas 1, 2, 3 las
##  señales vr, vs, vt con la perturbación sag añadida en el instante temporal
##  configurado.
##
##  Si el instante temporal configurado está fuera de la ventana mostrada en la
##  señal de entrada, o no puede ser mostrada en su totalidad, la función 
##  devuelve v_out acorde a la configuración, pero indica en la ventana de comando
##  este hecho.
##  
##  La función calcula la frecuencia fundamental de la señal trifásica x, y 
##  calcula los armónicos a partir de esta información.
##  
## @deftypefn {} {@var{v_out} =} Flicker_Transient(@var{v_input}, @var{fsampling}, @var{fflicker}, @var{aflicker}, @var{tinit}, @var{tend})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero Pérez <cromero@@zigor.com>
## Created: 2024-10-08
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Flicker_Transient (v_input, fsampling, fflicker, aflicker, tinit, tend)
  
  % Validación de entradas
  [filas,columnas]=size(v_input);
  
  if(filas!=3 || columnas<1)
    error('La señal de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false ||isnumeric(fflicker)==false || isnumeric(aflicker)==false ||isnumeric(tinit)==false||isnumeric(tend)==false)
    error('Los parámetros de entrada a la función deben ser numéricos');
  endif
  
  if(fsampling<=0 || fflicker<0 || aflicker<0 || tinit <0 || tend<=0)
    error('Parámetros de entrada negativos');
  endif
  
  if(tend<=tinit)
    error('tend debe ser mayor que tind');
  endif
  
  if(fflicker <0.5 || fflicker>30)
    error('La frecuencia de la moduladora del flicker debe estar en el rango Hz [0.5 30]');
  endif
  
  if(aflicker <0.01 || aflicker>0.03)
    error('La amplitud de la moduladora del flicker debe estar en el rango  [0.01 0.03]');
  endif
  
  % Detección de la amplitud de la señal trifásica
  Xmax=max([max(v_input(1,:)) max(v_input(2,:)) max(v_input(3,:))]);
  % Generación de moduladora
  theta=rand(1)*2*pi;
  l=1:columnas;
  t=(l-1)/fsampling;
  
  xflicker=aflicker*sin(2*pi*fflicker*t+theta);
  
 
  % Calcula ventana temporal del transitorio
  tultimo=columnas/fsampling;
  flag_evento=0;                % 0: El evento se puede representar entero
                                % 1: El evento se representa parcialmente
                                % -1: El evento no se puede representar
  if(tinit>tultimo)
    flag_evento=-1;
  elseif (tend>tultimo)
    flag_evento=1;
  endif
  
  %Calcula índices de inicio y fin de evento
  if(flag_evento!=-1)
    indini=floor(tinit*fsampling);
    if indini==0
      indini=1;
    endif
    if(flag_evento==0)
      indend=floor(tend*fsampling);
    else
      indend=columnas;
    endif
  endif
  
  % Genera transitorio
  transient=zeros(1,columnas);
  
  if(flag_evento!=-1)
    transient(indini:indend)=1;
  endif
  
  
  v_out(1,:)=v_input(1,:).*(1+xflicker.*transient);
  v_out(2,:)=v_input(2,:).*(1+xflicker.*transient);
  v_out(3,:)=v_input(3,:).*(1+xflicker.*transient);
    

endfunction
