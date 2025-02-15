#
# Curva_IV_panel.m
#
# Autor: Dr. Carlos Romero Pérez
# Fecha: 01/02/2025
#
# Este script calcula y grafica la curva I-V de un panel solar. de acuerdo
# con la ecuación
#
# I=Iph-Is (e^((V+IRs)/(nK T/q))-1)-(V+IRs)/Rsh.
#
# Pero resolver esta ecuación por medio de Newton Rampsom no es
# posible porque la exponencial toma valor infinito.
#
# Para resolverlo, se reescribe la ecuación tomando ln()
#
# Llamamos Vter=nKT/q
#
# Su: Irradiancia por unidad (Su=S/Sref). Sref=1000 W/m2
# Il: Es la corriente generada fotovoltaica, que depende de la irradiancia por
#     unidad Su
# I0: Corriente de saturación inversa (depende de la temperatura)
# Rs: Resistencia en serie de la celda (depende del semiconductor)
# Rsh: Resistencia de pérdida de la celda (depende del semiconductor)
#
# Los parámetros característicos se calculan a partir de los datos
# característicos del panel (datasheet de panel):
#
# Np: Número de celdas en paralelo
# Ns: Número de celdas en serie
# Voc: Tensión de circuito abierto del panel
# Isc: Corriente de corto circuito del panel
# alfa_isc: Coeficiente de Tª de la corriente de corto circuito
# beta_vosc: Coeficiente de Tª de la tension de circuito abierto
#
# El script calcula y grafica la característica I-V de la celda.
#
#

% Condiciones ambientales
Su=1;           % Irradiancia por unidad S/Sref
T=25;           % Temperatura en ºC

% Selector Panel
ejemplo=2;

switch (ejemplo)
  case 1
    % Artículo
    Np=1;
    Ns=60;
    Iscpanel=8.85;
    Vocpanel=37.85;
    alfa_isc=0.062;
    beta_vosc=-0.33;
  case 2
    % Ejemplo de panel solar real: TSM-DE14A
    Np=3;
    Ns=24;
    Iscpanel=9.69;    %A
    Vocpanel=47;      %V
    alfa_isc=0.05;    %/ºC
    beta_vosc=-0.29  % %/ºC
  case 3
    % Ejemplo de panel solar DS new energy 600W monocristalino
    Np=6;
    Ns=20;
    Iscpanel=18.57;     %A
    Vocpanel=41.7;      %V
    alfa_isc=0.046;    %/ºC
    beta_vosc=-0.277;  % %/ºC
endswitch



# Valores típicos a 25ºC
Rs=0.01;
n=1.3;          % Factor de idealidad de semiconductor
K=1.38e-23;     % Constante de Boltzman J/K
Tk=T+273.15;    % Tempertura ambiente en Kelvin
Tref=25+273.15; % Temperatura de referencia en K (25ºC)
a=K*Tk*n;
q=1.6e-19;      % Carga del electrón en C
Vter=a/q;
Rsh=10000;
Eg=1.12;        % eV Energía de la banda gap


% Valores de celda
Isc=Iscpanel/Np;          % A
I0ref=Isc/(e^(Vocpanel/(Ns*Vter))-1);
%I0ref=1e-12;
I0=I0ref*(Tk/Tref)^3*e^(q*Eg*(1/Tref-1/Tk)/(K*n));
Il=Su*Isc*(1+alfa_isc*(Tk-Tref)/100);


iteramax=1000;

V_vect=[];
I_vect=[];
index=1;
error_max=0.001;
Npuntos=100;

% Cálculo de Voc real (I=0)
flag_loop=0;
Vn=Vocpanel/Ns;
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


% Curva característica de panelfotovoltaico
dV=Voc_real/Npuntos;

for m=0:Npuntos
  V=m*dV;
  itera=0;
  flag_loop=0;
  In=0;
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

  V_vect(index)=V;
  I_vect(index)=In;
  index=index+1;

endfor

Isc=I_vect(1);

figure(1);
plot(V_vect,I_vect);
xlabel("V [v]");ylabel("I [A]");title("Curva I-V panel");grid;









