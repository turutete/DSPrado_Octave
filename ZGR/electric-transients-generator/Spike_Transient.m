## -*- texinfo -*-
##
## Spike_Transient.m
##
## Esta función modela un evento transitorio de Spike en una línea trifásica,
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los parámatros de entrada a la función son:
##
##  v_input: Es una matriz 3XN donde la fila 1 es la señal vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las señales tienen N muestras
##
##  fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
##
##  spike: Es un vector 1X3 que indica la amplitud del spike en valor por
##         unidad [1.5 6] en cada una de las fases. Si el valor introducido es
##          'aleatorio', la amplitud del strike será aleatorio dentro del
##          intervalo, aunque sel mismo signo que en el resto de las fases
##
##  tinit: Instante temporal de inicio del evento. Si el valor es 'aleatorio'
##          la posición del evento inicial es aleatorio. 
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
## @deftypefn {} {@var{v_out} =} Spike_Transient(@var{v_input}, @var{fsampling}, @var{spike}, @var{tinit})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero Pérez <cromero@@zigor.com>
## Created: 2024-10-10
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Spike_Transient (v_input, fsampling, spike, tinit)
  
  % Validación de entradas
  [filas,columnas]=size(v_input);
  
  if(filas!=3 || columnas<1)
    error('La señal de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false)
    error('Los parámetros de entrada a la función deben ser numéricos');
  endif
  
  if(fsampling<=0)
    error('La frecuencia de muestreo debe ser positova');
  endif
  
   if isnumeric(tinit)
     if tinit<0
       error('El parámetro tinit debe ser positivo');
     endif
   endif
   
   if isnumeric(spike)==false
    if spike=='aleatorio'
      spike=[1.5+rand(1)*4.5 1.5+rand(1)*4.5 1.5+rand(1)*4.5];
    else
      error('El parámetro spike debe ser un vector numérico o aleatorio');
    endif
   else
    if size(spike)!=[1,3]
      error('spike debe ser un vector 1X3');
    endif
    
    if (spike(1)<1.5 || spike(1)>6 || spike(2)<1.5 || spike(2)>6 || spike(3)<1.5 || spike(3)>6)
     error('La amplitud del spike debe estar en el rango [1.5 6]');
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
    
  notch=zeros(3,columnas);
  signo=sign(randn(1));
  
  notch(1,indini)=signo*spike(1)*Xmax;
  notch(2,indini)=signo*spike(2)*Xmax;
  notch(3,indini)=signo*spike(3)*Xmax;
   
  v_out(1,:)=v_input(1,:)+notch(1,:);
  v_out(2,:)=v_input(2,:)+notch(2,:);
  v_out(3,:)=v_input(3,:)+notch(3,:);
    

endfunction
