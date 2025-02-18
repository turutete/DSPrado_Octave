## -*- texinfo -*-
##
## Notch_Transient.m
##
## Esta función modela un evento transitorio de Notch en una línea trifásica,
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los parámatros de entrada a la función son:
##
##  v_input: Es una matriz 3XN donde la fila 1 es la señal vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las señales tienen N muestras
##
##  fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
##
##  wire:   Es un vector 1X3 usado de máscara, cuyos elementos valen 0 ó 1. 
##          Si es 0 indica que el evento de notch no afecta a la fase R, S o T,
##          según sea el 1º, 2º o 3º elemento, respectivamente. Si es '1', sí
##          le afecta. Por ejemplo, si vale [0 1 1], el evento afectará a las
##          fase S y T, pero no a la R.
##  deep: Profundidad del notch en valor por unidad [0 1]
##
##  period: Periodicidad en s de repetición del evento. Si vale 0 es un evento
##          unico.
##
##  tinit: Instante temporal de inicio del evento. Si el valor es 'aleatorio'
##          la posición del evento inicial es aleatorio. Si tiene pariodicidad,
##          los siguientes eventos aparecerán con la periodicidad introducida
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
## @deftypefn {} {@var{v_out} =} Notch_Transient(@var{v_input}, @var{fsampling}, @var{wire}, @var{deep}, @var{period}, @var{tinit})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero Pérez <cromero@@zigor.com>
## Created: 2024-10-10
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Notch_Transient (v_input, fsampling, wire, deep, period, tinit)
  
  % Validación de entradas
  [filas,columnas]=size(v_input);
  
  if(filas!=3 || columnas<1)
    error('La señal de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false || isnumeric(wire)==false || isnumeric(deep)==false || isnumeric(period)==false)
    error('Los parámetros de entrada a la función deben ser numéricos');
  endif
  
  if(fsampling<=0 || deep<0 || period<0)
    error('Parámetros de entrada negativos');
  endif
  
   if isnumeric(tinit)
     if tinit<0
       error('El parámetro tinit debe ser positivo');
     endif
   endif
   
   if deep>1
     error('La profundidad del notch como máximo debe ser 1');
   endif
   
   if size(wire)!=[1,3]
     error('El parámetro wire debe ser un vector 1X3');
   else
     if ((wire(1)!=0 && wire(1)!=1)|| (wire(2)!=0 && wire(2)!=1) || (wire(3)!=0 && wire(3)!=1))
       error('Los elementos del parámetro wire toman valores 0 ó 1');
     endif
   endif
   

  % Detección de la amplitud de la señal trifásica
  Xmax=max([max(v_input(1,:)) max(v_input(2,:)) max(v_input(3,:))]);
  
  % Síntesis de la perturbación
  % Cálculo del primer instante de aparición
  if tinit=='aleatorio'
    indini=floor(rand(1)*columnas);
  else
    indini=floor(tinit*fsampling);
  endif
  
  flag_periodo=0;
  if period>0
    flag_periodo=1;
    indperiodo=floor(period*fsampling);
  endif
  
  notch=zeros(3,columnas);
  
  notch(1,indini)=sign(v_input(1,indini))*min(wire(1)*deep*Xmax,abs(v_input(1,indini)));
  notch(2,indini)=sign(v_input(2,indini))*min(wire(2)*deep*Xmax,abs(v_input(2,indini)));
  notch(3,indini)=sign(v_input(3,indini))*min(wire(3)*deep*Xmax,abs(v_input(3,indini)));
  
  while flag_periodo==1
    indini=indini+indperiodo;
    if indini<=columnas
      notch(1,indini)=sign(v_input(1,indini))*min(wire(1)*deep*Xmax,abs(v_input(1,indini)));
      notch(2,indini)=sign(v_input(2,indini))*min(wire(2)*deep*Xmax,abs(v_input(2,indini)));
      notch(3,indini)=sign(v_input(3,indini))*min(wire(3)*deep*Xmax,abs(v_input(3,indini))); 
      else
        flag_periodo=0;
    endif   
  endwhile
   
  
  v_out(1,:)=v_input(1,:)-notch(1,:);
  v_out(2,:)=v_input(2,:)-notch(2,:);
  v_out(3,:)=v_input(3,:)-notch(3,:);
    

endfunction
