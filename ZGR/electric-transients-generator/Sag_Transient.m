## -*- texinfo -*-
##
## Sag_Transient.m
##
## Esta función modela un evento transitorio sag en una línea trifásica.
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los parámetros de entrada a la función son:
##
##  - v_input: Es una matriz 3XN donde la fila 1 es la señal vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las señales tienen N muestras.
##
##  - fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
##
##  - deep: Esta parámetro define la profundidad del hueco, en valor por unidad [0.1 0.9].
##        Si es un parámetro, el hueco se considera trifásico. Si es un vector,
##        debe ser de dimensión 1X3, siendo cada coeficiente del vector la
##        profundidad del hueco en cada fase.
##
##  - tinit: Instante temporal de inicio del evento
##
##  - tend: Instante temporal de fin del evento
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
## @deftypefn {} {@var{v_out} =} Sag_Transient (@var{v_input}, @var{fsampling}, @var{deep}, @var{tinit}, @var{tend})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero Pérez <cromero@@zigor.com>
## Created: 2024-10-06
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Sag_Transient (v_input, fsampling, deep, tinit, tend)
  
  % Validación de entradas
  [filas,columnas]=size(v_input);
  
  if(filas!=3 || columnas<1)
    error('La señal de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false ||isnumeric(deep)==false||isnumeric(tinit)==false||isnumeric(tend)==false)
    error('Los parámetros de entrada a la función deben ser numéricos');
  endif
  
  if(fsampling<=0 || tinit <0 || tend<=0)
    error('Parámetros de entrada negativos');
  endif
  
  if(tend<=tinit)
    error('tend debe ser mayor que tind');
  endif
  
  % Validación del parámetro deep
  [fildeep,coldeep]=size(deep);
  if fildeep>coldeep
    error('El parámetro deep debe ser un vector 1X1 o 1X3');
  endif
  
  if coldeep==1
    if(deep<0.1 || deep>0.9)
      error('La profundidad está acotada en el rango [0.1 0.9]');
    endif
  else
    if coldeep!=3
      error('El parámetro deep debe ser un vector 1X1 o 1X3');
    else
      if(deep(1)<0.1||deep(2)<0.1||deep(3)<0.1 || deep(1)>0.9 || deep(2)>0.9 || deep(3)>0.9)
        error('La profundidad está acotada en el rango [0.1 0.9]');
      endif
    endif
  endif 
  
  if coldeep==1
    deep=[deep deep deep];
  endif
  
  % Generación del sag
  
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
  sag(1,:)=ones(1,columnas);
  sag(2,:)=ones(1,columnas);
  sag(3,:)=ones(1,columnas);
  
  if(flag_evento!=-1)
    sag(1,indini:indend)=1-deep(1);
    sag(2,indini:indend)=1-deep(2);
    sag(3,indini:indend)=1-deep(3);
  endif
  
  v_out(1,:)=v_input(1,:).*sag(1,:);
  v_out(2,:)=v_input(2,:).*sag(2,:);
  v_out(3,:)=v_input(3,:).*sag(3,:);
    

endfunction
