## -*- texinfo -*-
##
## Spike_Transient.m
##
## Esta funci�n modela un evento transitorio de Spike en una l�nea trif�sica,
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los par�matros de entrada a la funci�n son:
##
##  v_input: Es una matriz 3XN donde la fila 1 es la se�al vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las se�ales tienen N muestras
##
##  fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
##
##  spike: Es un vector 1X3 que indica la amplitud del spike en valor por
##         unidad [1.5 6] en cada una de las fases. Si el valor introducido es
##          'aleatorio', la amplitud del strike ser� aleatorio dentro del
##          intervalo, aunque sel mismo signo que en el resto de las fases
##
##  tinit: Instante temporal de inicio del evento. Si el valor es 'aleatorio'
##          la posici�n del evento inicial es aleatorio. 
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
## @deftypefn {} {@var{v_out} =} Spike_Transient(@var{v_input}, @var{fsampling}, @var{spike}, @var{tinit})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero P�rez <cromero@@zigor.com>
## Created: 2024-10-10
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Spike_Transient (v_input, fsampling, spike, tinit)
  
  % Validaci�n de entradas
  [filas,columnas]=size(v_input);
  
  if(filas!=3 || columnas<1)
    error('La se�al de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false)
    error('Los par�metros de entrada a la funci�n deben ser num�ricos');
  endif
  
  if(fsampling<=0)
    error('La frecuencia de muestreo debe ser positova');
  endif
  
   if isnumeric(tinit)
     if tinit<0
       error('El par�metro tinit debe ser positivo');
     endif
   endif
   
   if isnumeric(spike)==false
    if spike=='aleatorio'
      spike=[1.5+rand(1)*4.5 1.5+rand(1)*4.5 1.5+rand(1)*4.5];
    else
      error('El par�metro spike debe ser un vector num�rico o aleatorio');
    endif
   else
    if size(spike)!=[1,3]
      error('spike debe ser un vector 1X3');
    endif
    
    if (spike(1)<1.5 || spike(1)>6 || spike(2)<1.5 || spike(2)>6 || spike(3)<1.5 || spike(3)>6)
     error('La amplitud del spike debe estar en el rango [1.5 6]');
    endif
  endif
  
      

  % Detecci�n de la amplitud de la se�al trif�sica
  Xmax=max([max(v_input(1,:)) max(v_input(2,:)) max(v_input(3,:))]);
  
  % S�ntesis de la perturbaci�n
  % C�lculo del primer instante de aparici�n
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
