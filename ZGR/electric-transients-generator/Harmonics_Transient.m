## -*- texinfo -*-
##
## Harmonics_Transient.m
##
## Esta función modela un evento transitorio de armónicos en una línea trifásica,
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los parámatros de entrada a la función son:
##
##  v_input: Es una matriz 3XN donde la fila 1 es la señal vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las señales tienen N muestras
##
##  fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
##
##  Harm: Esta parámetro es un vector fila cuyos elementos representa la amplitud 
##        por unidad del armónico fh(k)= fn*(k+1). Se pueden añadir tantos armónicos como
##        se desee, pero todos los anteriores elementos deben tener un valor. Por ejemplo.
##        si se quiere añadir el 3º y 5º armónico con amplitudes por unidad de 0.1
##        y 0.01 respectivamente, Harm=[0 0.1 0 0.01]. El 2º y 4º armónico deben
##        incluirse, con el valor deseado 0.
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
## @deftypefn {} {@var{v_out} =} Harmonics_Transient(@var{v_input}, @var{fsampling}, @var{Harm}, @var{tinit}, @var{tend})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero Pérez <cromero@@zigor.com>
## Created: 2024-10-08
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Harmonics_Transient (v_input, fsampling, harm, tinit, tend)
  
  % Validación de entradas
  [filas,columnas]=size(v_input);
  
  if(filas!=3 || columnas<1)
    error('La señal de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false ||isnumeric(harm)==false||isnumeric(tinit)==false||isnumeric(tend)==false)
    error('Los parámetros de entrada a la función deben ser numéricos');
  endif
  
  if(fsampling<=0 || tinit <0 || tend<=0)
    error('Parámetros de entrada negativos');
  endif
  
  if(tend<=tinit)
    error('tend debe ser mayor que tind');
  endif
  
  [filh,colh]=size(harm);
  if(filh>1 && colh>1)
    error('El parámetro harm debe ser un vector fila');
  elseif (filh>colh)
    harm=harm';
  endif
  
  Nharm=length(harm);
  
  % Calcula la frecuencia fundamental
  X1=fft(v_input(1,:),columnas);
  X2=fft(v_input(2,:),columnas);
  X3=fft(v_input(3,:),columnas);
  [Vtemp,indmax]=max(abs(X1));
  indmax=indmax-1;
  X1max=X1(indmax+1);
  X2max=X2(indmax+1);
  X3max=X3(indmax+1);
    
  % Generación de armónicos
  
  X1arm=zeros(1,columnas);
  X2arm=zeros(1,columnas);
  X3arm=zeros(1,columnas);
  

  indharm=indmax;
  indharm=indharm+indmax;
  index=1;
  if ((indharm+1)<=round(columnas/2))
    flag=0;
  else
    flag=1;
  endif
  
  while flag==0
    X1arm(indharm+1)=harm(index)*X1max;
    X1arm(columnas-indharm+1)=harm(index)*conj(X1max);
    X2arm(indharm+1)=harm(index)*X2max;
    X2arm(columnas-indharm+1)=harm(index)*conj(X2max);
    X3arm(indharm+1)=harm(index)*X3max;
    X3arm(columnas-indharm+1)=harm(index)*conj(X3max);
    
    indharm=indharm+indmax;
    index=index+1;  
    if(index>Nharm || (indharm+1)>round(columnas/2))
      flag=1;
    endif
  endwhile
  
  x1harm=real(ifft(X1arm,columnas));
  x2harm=real(ifft(X2arm,columnas));
  x3harm=real(ifft(X3arm,columnas));  
  
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
  
  v_out(1,:)=v_input(1,:)+(x1harm.*transient);
  v_out(2,:)=v_input(2,:)+(x2harm.*transient);
  v_out(3,:)=v_input(3,:)+(x3harm.*transient);
    

endfunction
