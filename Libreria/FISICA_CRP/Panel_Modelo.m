## -*- texinfo -*-
##
## Panel_Modelo.m
##
## Author: Dr. Carlos Romero P�rez
## Created: 2025-02-08
##
## Copyright (C) 2025 Carlos Romero
##
## Esta funci�n modela el comportamiento de un panel fotovoltaico de Ns celdas
## en serie y Np celdas en paralelo, devolviendo el valor de corriente Ipanel
## suministrada por el panel para una condiciones de irradiancia Su expresadas
## en valores por unidad (Su=S/Sref). Siendo S la irradiancia y Sref la
## irradiancia de referencia (1000W/m2), siendo la tensi�n de salida del panel
## Vpanel.
##
## La funci�n retorna tambi�n la corriente de cortocircuito del panel Isc y la
## tensi�n de circuito abierto Voc.
##
##
## La variable de retorno (panel) es un vector de 3 componentes:
##
##  panel=[Ipanel,Isc,Voc]
##
##  En el caso de querer simular con m�s precisi�n el comportamiento, deber�n
##  ser modificados estos par�metros para ajustarlo a las caracter�sticas
##  especi�ficas de la celda solar
## @deftypefn {} {@var{panel} =} Panel_Modelo (@var{Vpanel}, @var{Spu}, @var{T})
##
## @end deftypefn


function panel = Panel_Modelo (Vpanel,Spu,T)

  % Validaci�n de par�metros de entrada
  if (isscalar(Vpanel)==false || isscalar(Spu)==false || isscalar(T)==false)
    error("Los par�metros de entrada deben ser escalares");
  endif

  if(Vpanel<0 || Spu<0)
    error("Los par�metros Vpanel y Spu deben ser positivos");
  endif

  if(Spu>1)
    error("La irradiancia por unidad debe ser menor o igual que 1");
  endif



% Ejemplo de panel solar real
Np=2;
Ns=60;

Vocpanel=41.7;    %V
Vmpptpanel=34.6;  %V
Iscpanel=18.57;    %A
Impptpanel=17.49; %A
Efipanel=0.214;
alfa_isc=0.046;   % %/�C
beta_voc=-0.277;  % 5/�C

# Valores t�picos a 25�C
Rs=0.01;
n=1.3;          % Factor de idealidad de semiconductor
K=1.38e-23;     % Constante de Boltzman J/K
Tk=T+273.15;    % Tempertura ambiente en Kelvin
Tref=25+273.15; % Temperatura de referencia en K (25�C)
a=K*Tk*n;
q=1.6e-19;      % Carga del electr�n en C
Vter=a/q;
Rsh=10000;
Eg=1.12;        % eV Energ�a de la banda gap


% Valores de celda a partir de datos del panel
Voc=(Vocpanel/Ns)*(1+beta_voc*(Tk-Tref)/100);
Isc=Iscpanel/Np;
I0ref=1e-14;
I0=I0ref*(Tk/Tref)^3*e^(q*Eg*(1/Tref-1/Tk)/(K*n));
Il=Spu*Isc*(1+alfa_isc*(Tk-Tref)/100);


iteramax=1000;
error_max=0.001;

% C�lculo de Voc real (I=0)
flag_loop=0;
Vn=1;
itera=0;
while(flag_loop==0)
  f=Il-I0*(e^(Vn/Vter)-1)-Vn/Rsh;
  df=-I0/Vter*e^(Vn/Vter)-1/Rsh;
  Vnext=Vn-f/df;
  err=abs(Vn-Vnext);
  Vn=Vnext;
  if(err<error_max)
    flag_loop=1;
  endif
  itera=itera+1;
  if(itera>iteramax)
    error("No converge");
  endif
endwhile

Voc_real=Vn;

Voc_panel_real=Voc_real*Ns;
if(Voc_panel_real<Vpanel)
  disp("Tensi�n de panel mayor que tensi�n de circuito abierto");
  flag_loop=1;
  Ipanel=0;
else
  flag_loop=0;
endif



% C�lculo de la corriente de salida I

itera=0;
In=0;
V=Vpanel/Ns;

while(flag_loop==0)
  f=In-Il+I0*(e^((V+In*Rs)/Vter)-1)+(V+In*Rs)/Rsh;
  df=1+I0*Rs/Vter*e^((V+In*Rs)/Vter)+Rs/Rsh;
  Inext=In-f/df;
  err=abs(In-Inext);
  In=Inext;
  if(err<=error_max)
    flag_loop=1;
  endif
  itera=itera+1;
  if(itera>iteramax)
    error("No converge");
  endif
endwhile

Ipanel=In*Np;


panel=[Ipanel Iscpanel Voc_panel_real];


endfunction
