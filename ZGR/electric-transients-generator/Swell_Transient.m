## -*- texinfo -*-
##
## Swell_Transient.m
##
## Esta funci�n modela un evento transitorio swell en una l�nea trif�sica,
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los par�matros de entrada a la funci�n son:
##
##  v_input: Es una matriz 3XN donde la fila 1 es la se�al vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las se�ales tienen N muestras.
##
##  fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
##
##  overv: Esta par�metro define el sobrevoltaje, en valor por unidad [1.1 1.8]
##          Si el par�metro es un escalar, la sobretensi�n es igual en las 3 fases.
##          Si es un vector 1X3, cada elementor del vector indica la sobretensi�n
##          de cada fase
##
##  tinit: Instante temporal de inicio del evento
##
##  tend: Instante temporal de fin del evento
##
##  La se�al de salida v_out es una matriz 3XN, siendo las filas 1, 2, 3 las
##  se�ales vr, vs, vt con la perturbaci�n sag a�adida en el instante temporal
##  configurado.
##
##  Si el instante temporal configurado est� fuera de la ventana mostrada en la
##  se�al de entrada, o no puede ser mostrada en su totalidad, la funci�n 
##  devuelve v_out acorde a la configuraci�n, pero indica en la ventana de comando
##  este hecho.
##  
## @deftypefn {} {@var{v_out} =} Swell_Transient(@var{v_input}, @var{fsampling}, @var{overv}, @var{tinit}, @var{tend})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero P�rez <cromero@@zigor.com>
## Created: 2024-10-08
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Swell_Transient (v_input, fsampling, overv, tinit, tend)
  
  % Validaci�n de entradas
  [filas,columnas]=size(v_input);
  
  if(filas!=3 || columnas<1)
    error('La se�al de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false ||isnumeric(overv)==false||isnumeric(tinit)==false||isnumeric(tend)==false)
    error('Los par�metros de entrada a la funci�n deben ser num�ricos');
  endif
  
  if(fsampling<=0 || tinit <0 || tend<=0)
    error('Par�metros de entrada negativos');
  endif
  
  [filov,colov]=size(overv);
  if filov>colov
    error('El par�metro overv debe ser o un escalar o un vector 1X3');
  endif
  
  if colov==1
    if(overv<1.1 || overv>1.8)
    error('La sobretensi�n est� acotada en el rango [1.1 1.8]');
    endif
    overv=[overv overv overv];
  else
    if colov!=3
      error('El par�metro overv debe ser o un escalar o un vector 1X3');
    endif
    if(overv(1)<1.1 || overv(2)<1.1 || overv(3)<1.1 || overv(1)>1.8 || overv(2)>1.8 || overv(3)>1.8)
     error('La sobretensi�n est� acotada en el rango [1.1 1.8]');
    endif
 endif
 
  
  
  if(tend<=tinit)
    error('tend debe ser mayor que tind');
  endif
  
  
  
  % Generaci�n del swell
  
  tultimo=columnas/fsampling;
  flag_evento=0;                % 0: El evento se puede representar entero
                                % 1: El evento se representa parcialmente
                                % -1: El evento no se puede representar
  if(tinit>tultimo)
    flag_evento=-1;
  elseif (tend>tultimo)
    flag_evento=1;
  endif
  
  %Calcula �ndices de inicio y fin de evento
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
