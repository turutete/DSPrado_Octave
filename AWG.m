##
##  AWG.m
##
## Prototipo: y=AWG(nsignal)
##
## nsignal= N�mero de muestras de la se�al generada
## y= se�al generada
##
## AWG (Arbitrary Wave Generator) es un generador de onda arbitrario.
## Mediante men�s, el usuario puede generar un conjunto de ondas arbitrarias,
## muestreada a la frecuencia de muestreo que desee el usuario. La frecuencia
## de muestreo tambi�n es un par�metro configurable mediante men�.
##
##  El script permite visualizar la forma de onda, su espectro, y almacenar 
## la forma de onda en un fichero.
##
## Copyright (C) 2021 Dr. Carlos Romero
## 
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see
## <https://www.gnu.org/licenses/>.
## Author: Dr. Carlos Romero
## Created: 2021-12-18

function y = AWG (nsignal)
  
% Tolerencia a fallos en la interfaz de usuario
nargumentos=nargin();
if nargumentos!=1
  error("Esta funci�n requiere un par�metro de entrada, el tama�o del vector de salida");
endif
 
if(isnumeric(nsignal)==false)
  error("El par�metro de entrada nsignal debe ser num�rico");
endif

if(nsignal<0)
  error("El tama�o de la se�al de salida debe ser positivo");
end

L=floor(nsignal);    % La longitud de la se�al es un entero positivo


% Par�metros por defecto
fsampling=160e9;     % Fsampling defecto= 16 GHz
select=0;
Noptions=6;           % Noptions es el n�mero de opciones el men�
                      % OJO: Si se a�aden o quitan opciones al men� principal
                      % este valor debe ser modificado. La opci�n Salir
                      % debe ser la �ltima de la lista

while select!=Noptions
  
   % Men� principal: Selecci�n de frecuencia de muestreo y tipo de se�al
  select=menu("Men� Principal","Frecuencia de Muestreo","Onda Continua",...
  "Onda Pulsada","Comunicaciones","Ruido","Salir");
  
  switch select
    case 1
      fsampling=SetFsampling(fsampling);
    case 2
      % Onda cont�nua
        y=awg_sine(L,fsampling);
     case 3
      % Onda pulsada
        y=awg_pulse(L,fsampling);
      case 4
        % Comunicaciones
        y=awg_comms(L,fsampling);
      case 5
        y=awg_noise(L,fsampling);
             
   endswitch
   
 endwhile
 
endfunction


function retval=SetFsampling(fs)
  retval=fs;
  printf("Frecuencia de muestreo actual= %f\n",fs);
  fflush (stdout);
  faux=input("Frecuencia de muestro nueva=");
  if (isnumeric(faux)==true &&  faux>0)
    retval=faux;
  endif
  
  printf("Frecuencia de muestreo actual= %f\n",retval);
endfunction


function  y=awg_sine(N,fs)
  fflush (stdout);
  faux=input("Frecuencia de portadora=");
  if (isnumeric(faux)==true &&  faux>0)
    fcarrier=faux;
  else
    disp("La frecuencia de portadora debe ser mayor que cero\n");
    fcarrier=fs/4;
    disp("Se toma el valor por defecto para fcarrier\n");
  endif
  
  if(fcarrier*2>=fs)
    disp("La fecuencia de portadora no cumple el criterio de Nyquist\n");
    disp("Se toma el valor por defecto para fcarrier\n");
    fcarrier=fs/4;
  endif
  

  printf("Frecuencia de portadora= %f\n",fcarrier);
  
  fd=fcarrier/fs;
  
  n=1:N;
  y(n)=sin(2*pi*(n-1)*fd);
  
endfunction

