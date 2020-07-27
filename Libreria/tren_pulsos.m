
##
## y=tren_pulsos (ftren,dutty, fmuestreo,tmax)
##
##  ftren: Frecuencia del tren de pulsos en Hz
##  dutty: Dutty cycle en %
##  fuestreo: Frecuencia de muestreo en Hz
##  tmax: Duración de la señal en segundos
##
## Author: Dr. Carlos Romero
## Created: 2020-05-03

function retval = tren_pulsos (ftren, dutty, fmuestreo, tmax)
  
  % Comprobacion de seguridad
  if ftren<=0
    error('La frecuencia del ten de pulsos ftren debe ser mayor que cero');
  endif
  
  
  nmax=tmax*fmuestreo;        % Número de muestras total del vector salida
  nmc=fmuestreo/ftren;        %Número de muestras por ciclo
  nmones=round(nmc*dutty/100);  % Número de muestras '1' por ciclo
  
  %Cálculo del número de ciclos completos que caben en el vector salida
  ncc=floor(nmax/nmc);
  %Cálculo de número de muestras del último vector
  nmuv=rem(nmax,nmc);
   
   %Vector periódico
   vector_periodico=[ones(1,nmones) zeros(1,nmc-nmones)];
   % Último vector
   if nmuv<=nmones
     vector_ultimo=ones(1,nmuv);
   else
     vector_ultimo=[ones(1,nmones) zeros(1,nmuv-nmones)];
   endif
   
   retval=[];
   for nciclos=1:ncc
     retval=[retval vector_periodico];
   endfor
   
   if nmuv>0
     retval=[retval vector_ultimo];
   endif
     

endfunction
