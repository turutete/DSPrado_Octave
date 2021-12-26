
##
## y=tren_pulsos (ftren,dutty, fmuestreo,tmax)
##
##  ftren: Frecuencia del tren de pulsos en Hz
##  dutty: Dutty cycle en %
##  fuestreo: Frecuencia de muestreo en Hz
##  tmax: Duraci�n de la se�al en segundos
##
## Author: Dr. Carlos Romero
## Created: 2020-05-03

function retval = tren_pulsos (ftren, dutty, fmuestreo, tmax)
  
  % Comprobacion de seguridad
  if ftren<=0
    error('La frecuencia del ten de pulsos ftren debe ser mayor que cero');
  endif
  
  
  nmax=tmax*fmuestreo;        % N�mero de muestras total del vector salida
  nmc=fmuestreo/ftren;        %N�mero de muestras por ciclo
  nmones=round(nmc*dutty/100);  % N�mero de muestras '1' por ciclo
  
  %C�lculo del n�mero de ciclos completos que caben en el vector salida
  ncc=floor(nmax/nmc);
  %C�lculo de n�mero de muestras del �ltimo vector
  nmuv=rem(nmax,nmc);
   
   %Vector peri�dico
   vector_periodico=[ones(1,nmones) zeros(1,nmc-nmones)];
   % �ltimo vector
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
