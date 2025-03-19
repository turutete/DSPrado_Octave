## -*- texinfo -*-
##
## Harmonics_Transient.m
##
## Esta funci�n modela un evento transitorio de arm�nicos en una l�nea trif�sica,
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los par�matros de entrada a la funci�n son:
##
##  v_input: Es una matriz 3XN donde la fila 1 es la se�al vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las se�ales tienen N muestras
##
##  fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
##
##  Harm: Esta par�metro es un vector fila cuyos elementos representa la amplitud 
##        por unidad del arm�nico fh(k)= fn*(k+1). Se pueden a�adir tantos arm�nicos como
##        se desee, pero todos los anteriores elementos deben tener un valor. Por ejemplo.
##        si se quiere a�adir el 3� y 5� arm�nico con amplitudes por unidad de 0.1
##        y 0.01 respectivamente, Harm=[0 0.1 0 0.01]. El 2� y 4� arm�nico deben
##        incluirse, con el valor deseado 0.
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
## @deftypefn {} {@var{v_out} =} Harmonics_Transient(@var{v_input}, @var{fsampling}, @var{Harm}, @var{tinit}, @var{tend})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero P�rez <cromero@@zigor.com>
## Created: 2024-10-08
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Harmonics_Transient (v_input, fsampling, harm, tinit, tend)
  
  % Validaci�n de entradas
  [filas,columnas]=size(v_input);
  
  if(filas!=3 || columnas<1)
    error('La se�al de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false ||isnumeric(harm)==false||isnumeric(tinit)==false||isnumeric(tend)==false)
    error('Los par�metros de entrada a la funci�n deben ser num�ricos');
  endif
  
  if(fsampling<=0 || tinit <0 || tend<=0)
    error('Par�metros de entrada negativos');
  endif
  
  if(tend<=tinit)
    error('tend debe ser mayor que tind');
  endif
  
  [filh,colh]=size(harm);
  if(filh>1 && colh>1)
    error('El par�metro harm debe ser un vector fila');
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
    
  % Generaci�n de arm�nicos
  
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
  
  v_out(1,:)=v_input(1,:)+(x1harm.*transient);
  v_out(2,:)=v_input(2,:)+(x2harm.*transient);
  v_out(3,:)=v_input(3,:)+(x3harm.*transient);
    

endfunction
