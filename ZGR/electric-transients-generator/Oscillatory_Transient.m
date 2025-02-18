## -*- texinfo -*-
##
## Oscillatory_Transient.m
##
## Esta funci�n modela eventos transitorios oscilatorios en una l�nea trif�sica,
## de acuerdo con el modelo de IEEE 1159-1995.
##
## Los par�matros de entrada a la funci�n son:
##
##  v_input: Es una matriz 3XN donde la fila 1 es la se�al vr(n), la fila 2
##            es vs(n) y la fila 3 es vt(n). Las se�ales tienen N muestras
##
##  fsamplig: define la frecuencia de muestreo en Hz de la matriz de entrada.
##
##  freq: Esta par�metro es un vector fila cuyos elementos indican las frecuencias
##        perturbadoras. Deben ser mayores que cero, y menores que la frecuencia
##        de Nyquist. Si el par�metro es [], se generar� una �nica perturbaci�n
##        de frecuencia aleatoria en el rango (0 Fnyquist] 
##
##  scope:  Este parametros es una matriz 3 X F, siendo F el n�mero de frecuencias
##          perturbadoras. Cada elemento de la matriz puede ser 0 � 1. La fila
##          1 indica qu� frecuencias afectan a la fase R, la fila 2 a la S y la
##          fila 3 a la T. Si es '1' significa que la frecuencia afecta, y si 
##          es 0 no. Es decir, el elemento scope(i,j)=1 significa que la fase i
##          (1=R, 2=S, 3=T) est� afectada por la perturbaci�n fj. Si vale
##          [], se generar� una matriz de 1 y 0 aleatoria.
##
##  amplitude: Es un vector de la misma dimensi�n que freq que indica en valores
##             por unidad la amplitud de la frecuencia perturbadoras. Si el valor
##            es [] las amplitudes de cada frecuencia perturbadora se
##            elige aleatoriamente en el rango [0 0.25] por unidad.
##
##  period: Es un vector de la misma dimensi�n que freq que indica el periodo
##        de aparici�n de la perturbaci�n de esa frecuencia. Si el valor es
##        [], el periodo de aparici�n de la perturbaci�n ser� aleatoria. Debe
##        ser positivo.
##
##  duration: Es un vector de la misma dimensi�n que freq que indica la duraci�n
##            temporal de la perturbaci�n en [s]. Debe ser menor que el periodo.
##            Si su valor es [], la duraci�n de cada perturbaci�n se
##            asigna aleatoriamente en el rango [0 T], siendo T el tiempo
##            total de la se�al trif�sica.
##
##  type: 0: perturbaci�n senoidal 1: perturbaci�n senoidal amortiguada.
##          Si su valor es [], a cada frecuencia perturbadora se le
##          asignar� aleatoriamente el tipo de perturbaci�n.
##
##  tinit: Vector de la misma dimensi�n que freq. Cada elemento indica el instante
##         temporal de inicio del evento. Si vale [] el inicio de 
##        cada evento se escoger� de forma aleatoria
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
## @deftypefn {} {@var{v_out} =} Oscillatory_Transient(@var{v_input}, @var{fsampling}, @var{freq}, @var{scope}, @var{amplitude}, @var{period}, @var{duration}, @var{type}, @var{tinit})
##
## @seealso{https://zigorcorp.sharepoint.com/:b:/s/UTI/EfGBWx4vW-tOodR8OONEG8wBv_GYyC9JAnpmUFV0lev1Zg?e=nCvfr9}
## Author: Dr. Carlos Romero P�rez <cromero@@zigor.com>
## Created: 2024-10-08
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn

function v_out = Oscillatory_Transient (v_input, fsampling, freq, scope, amplitude, period, duration, type, tinit)
  
  % Validaci�n de entradas
  [filas,columnas]=size(v_input);
  
  Xmax=max(max(abs(v_input)));
  
  if(filas!=3 || columnas<1)
    error('La se�al de entrada tiene que ser una matriz 3 X N, con N>=1');
  endif
  
  if(isnumeric(v_input)==false || isnumeric(fsampling)==false)
    error('Los par�metros de entrada a la funci�n deben ser num�ricos');
  endif
  
  % Validaci�n de datos y generaci�n de transitorios
  fnyquist=fsampling/2;
  l=1:columnas;
  
  
  if isempty(freq)
    freq=rand(1)*fnyquist;
  else
    if isnumeric(freq)==false
      error('El vector de frecuencias debe ser num�rico');
    endif

    if isvector(freq)==false
      error('El par�metro freq debe ser un vector 1 X N');
    endif
    
    if(max(freq)>fnyquist || min(freq)<=0)
      error('Vector de frecuencia incorrecto. Debe ser 0< freq<fnyquist');
    endif
    
  endif

  [fil,col]=size(freq);
  if fil>col
    freq=freq';
    col=fil;
  endif
  
  for ind=1:col
    phase=rand(1)*2*pi;
    oscil(ind,l)=sin(2*pi*freq(ind)*(l-1)/fsampling+phase);
  endfor
  
     
  % Validada freq, el resto de par�metros debe tener la misma dimensi�n
  
  if isempty(scope)
    scope=randi([0,1],3,col);
  else
    if isnumeric(scope)==false
      error('scope debe ser num�rico');
    endif
    
    if size(scope)!=[3,col]
      error('scope debe ser una matriz 3XF, siendo F el n�mero de frecuencias');
    endif
    
    scopemin=min(min(scope));
    scopemax=max(max(scope));
        
    if (scopemin<0 || scopemax>1)
      error('Los elementos de scope deben ser 0 � 1');
    endif
    
  endif
  
   
  if isempty(amplitude)
      amplitude=rand(size(freq))*0.25;  
  else
    if isnumeric(amplitude)==false
      error('El vector de amplitudes debe ser num�rico');
    endif
    if size(amplitude)!=size(freq)
      error('el tama�o de freq y amplitude debe ser el mismo');
    endif
  endif
  
    
  for ind=1:col
    oscil(ind,:)=Xmax*amplitude(ind).*oscil(ind,:);
  endfor
    
  
  if isempty(duration)
    for q=1:col
      duration(q)=(abs(rand(1)-rand(1))*columnas)/fsampling;
    endfor 
  else
    if size(duration)!=size(freq)
      error('El tama�o del par�metro duration debe ser igual al de freq');
    endif
    
    if isnumeric(duration)==false
      error('duration debe ser num�rico');
    endif
    
    for q=1:col
      if duration(q)<0
        error('duration debe ser positivo');
      endif
    endfor 
  endif
  
  if isempty(period)
    for q=1:col
      period(q)=(columnas/fsampling)*rand(1)+duration(q);
    endfor
  else
    if size(period)!=size(freq)
      error('period debe ser un vector del mismo tama�o que freq');
    endif
    if isnumeric(period)==false
      error('period debe ser num�rico');
    endif
    for q=1:col
      if period(q)<0
        error('period debe ser positivo');
      endif
    endfor
  endif
      
  if isempty(type)
    type=randi([0,1],1,col);
  else
    if size(type)!=size(freq)
      error('El tama�o del par�metro type debe ser igual a freq');
    endif

    if isnumeric(type)==false
      error('type debe ser un vector num�rico');
    endif
    for q=1:col
      if (type(q)!=0 && type(q)!=1)
        error('El par�metro type puede ser 0:seno o 1:exp');
      endif
     endfor
  endif
  
  if isempty(tinit)
    for q=1:col
      tinit(q)=rand(1)*(columnas/fsampling);
    endfor
  else
    if isnumeric(tinit)==false
      error('El par�metro tinit debe ser num�rico');
    endif
    for q=1:col
      if tinit(q)<0
        error('tinit debe ser positivo');
      endif
    endfor
  endif
  
  
  % Generaci�n de pulsos de perturbaci�n
  transient=zeros(col,columnas);
  
  npulsos=zeros(1,3);
  
  for q=1:col
    npulsos(q)=floor(duration(q)*fsampling);
  endfor
  
  for q=1:col
    k=1:npulsos(q);
    
    if type(q)==0
      perturbation(q,k)=1;
    else
      perturbation(q,k)=e.^(-(k-1)*4.6/(fsampling*duration(q)));
    endif
  endfor
  
  
  for q=1:col
    indini=floor(tinit(q)*fsampling);
    npulse=npulsos(q);
    nperiod=floor(period(q)*fsampling);
    
    if indini>columnas
      flag_run=1;
    else
      flag_run=0;
    endif
    
    while flag_run==0
      indmax=indini+npulse;
      if (indmax>columnas)
        indmax=columnas;
      endif
      k=1;
      indwrite=indini;
      while indwrite<indmax
        transient(q,indwrite)=perturbation(q,k);
        indwrite=indwrite+1;
        k=k+1;
      endwhile
      
      indini=indini+nperiod;
      if indini>columnas
        flag_run=1;
      endif
      
    endwhile


  endfor
  
  transient=transient.*oscil;
  
  v_out(1,:)=v_input(1,:);
  v_out(2,:)=v_input(2,:);
  v_out(3,:)=v_input(3,:);
  
  
  for q=1:col
    if scope(1,q)==1
      v_out(1,:)=v_out(1,:)+transient(q,:);
    endif
    if scope(2,q)==1
      v_out(2,:)=v_out(2,:)+transient(q,:);
    endif
    if scope(3,q)==1
      v_out(3,:)=v_out(3,:)+transient(q,:);
    endif    
    
  endfor
 
endfunction
