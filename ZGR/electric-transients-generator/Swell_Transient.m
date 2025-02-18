## -*- texinfo -*-
##
## Swell_Transient.m
##
## Esta función modela un evento transitorio swell en una línea trifásica,
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los parámatros de entrada a la función son:
##
##  v_input: Es una matriz 3XN donde la fila 1 es la señal vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las señales tienen N muestras.
##
##  fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
##
##  overv: Esta parámetro define el sobrevoltaje, en valor por unidad [1.1 1.8]
##          Si el parámetro es un escalar, la sobretensión es igual en las 3 fases.
##          Si es un vector 1X3, cada elementor del vector indica la sobretensión
##          de cada fase
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
## @deftypefn {} {@var{v_out} =} Swell_Transient(@var{v_input}, @var{fsampling}, @var{overv}, @var{tinit}, @var{tend})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero Pérez <cromero@@zigor.com>
## Created: 2024-10-08
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Swell_Transient (v_input, fsampling, overv, tinit, tend)
  
  % Validación de entradas
  [filas,columnas]=size(v_input);
  
  if(filas!=3 || columnas<1)
    error('La señal de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false ||isnumeric(overv)==false||isnumeric(tinit)==false||isnumeric(tend)==false)
    error('Los parámetros de entrada a la función deben ser numéricos');
  endif
  
  if(fsampling<=0 || tinit <0 || tend<=0)
    error('Parámetros de entrada negativos');
  endif
  
  [filov,colov]=size(overv);
  if filov>colov
    error('El parámetro overv debe ser o un escalar o un vector 1X3');
  endif
  
  if colov==1
    if(overv<1.1 || overv>1.8)
    error('La sobretensión está acotada en el rango [1.1 1.8]');
    endif
    overv=[overv overv overv];
  else
    if colov!=3
      error('El parámetro overv debe ser o un escalar o un vector 1X3');
    endif
    if(overv(1)<1.1 || overv(2)<1.1 || overv(3)<1.1 || overv(1)>1.8 || overv(2)>1.8 || overv(3)>1.8)
     error('La sobretensión está acotada en el rango [1.1 1.8]');
    endif
 endif
 
  
  
  if(tend<=tinit)
    error('tend debe ser mayor que tind');
  endif
  
  
  
  % Generación del swell
  
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
  swell(1,:)=ones(1,columnas);
  swell(2,:)=ones(1,columnas);
  swell(3,:)=ones(1,columnas);
  
  if(flag_evento!=-1)
    swell(1,indini:indend)=overv(1);
    swell(2,indini:indend)=overv(2);
    swell(3,indini:indend)=overv(3);
  endif
  
  v_out(1,:)=v_input(1,:).*swell(1,:);
  v_out(2,:)=v_input(2,:).*swell(2,:);
  v_out(3,:)=v_input(3,:).*swell(3,:);
    

endfunction
