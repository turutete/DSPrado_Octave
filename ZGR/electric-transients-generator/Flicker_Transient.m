## -*- texinfo -*-
##
## Flicker_Transient.m
##
## Esta funci�n modela un evento transitorio de flicker en una l�nea trif�sica,
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los par�matros de entrada a la funci�n son:
##
##  v_input: Es una matriz 3XN donde la fila 1 es la se�al vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las se�ales tienen N muestras
##
##  fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
#
##  fflicker: Esta par�metro es la frecuencia de la moduladora en Hz [0.5 30]
##
##  aflicker: Este par�metro es la amplitud de la moduladora [0.01 0.03]
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
##  La funci�n calcula la frecuencia fundamental de la se�al trif�sica x, y 
##  calcula los arm�nicos a partir de esta informaci�n.
##  
## @deftypefn {} {@var{v_out} =} Flicker_Transient(@var{v_input}, @var{fsampling}, @var{fflicker}, @var{aflicker}, @var{tinit}, @var{tend})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero P�rez <cromero@@zigor.com>
## Created: 2024-10-08
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Flicker_Transient (v_input, fsampling, fflicker, aflicker, tinit, tend)
  
  % Validaci�n de entradas
  [filas,columnas]=size(v_input);
  
  if(filas!=3 || columnas<1)
    error('La se�al de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false ||isnumeric(fflicker)==false || isnumeric(aflicker)==false ||isnumeric(tinit)==false||isnumeric(tend)==false)
    error('Los par�metros de entrada a la funci�n deben ser num�ricos');
  endif
  
  if(fsampling<=0 || fflicker<0 || aflicker<0 || tinit <0 || tend<=0)
    error('Par�metros de entrada negativos');
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
  
  % Detecci�n de la amplitud de la se�al trif�sica
  Xmax=max([max(v_input(1,:)) max(v_input(2,:)) max(v_input(3,:))]);
  % Generaci�n de moduladora
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
  transient=zeros(1,columnas);
  
  if(flag_evento!=-1)
    transient(indini:indend)=1;
  endif
  
  
  v_out(1,:)=v_input(1,:).*(1+xflicker.*transient);
  v_out(2,:)=v_input(2,:).*(1+xflicker.*transient);
  v_out(3,:)=v_input(3,:).*(1+xflicker.*transient);
    

endfunction
