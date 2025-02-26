#
# Arco_DC.m
#
# Ejemplo de arco DC en el equipo.
#
# Este ejemplo usa los datos de un panel comercial.
#
# Simula, para unas condiciones ambientales de irradiancia Su, y temperatura T
# y una referencia de potencia activa Pref por unidad, la forma de onda de
# corriente Idc que mide el sensor de medida de corriente DC del equipo, antes
# y después de producirse un evento de arco DC
#
# Autor: Dr. Carlos Romero Pérez
# Fecha: 15/02/2025
#

addpath('../Libreria');

% Condiciones ambientales
%Su=0.5+0.5*rand(1);    % Irradiancia por unidad S/Sref [0.5 - 1]
%T=25+15*(1-rand(1));           % Temperatura en ºC [25 - 40]
Su=1;
T=25;

% Condiciones de trabajo
Msampling=5;
fswitch=2500;
fsampling=Msampling*fswitch;
Nciclos=10;


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
    Vmpptpanel=30.12;
    Impptpanel=8.3;
  case 2
    % Ejemplo de panel solar real: TSM-DE14A
    Np=3;
    Ns=24;
    Iscpanel=9.69;    %A
    Vocpanel=47;      %V
    alfa_isc=0.05;    %/ºC
    beta_vosc=-0.29;  % %/ºC
    Vmpptpanel=38.7;
    Impptpanel=9.17;
  case 3
    % Ejemplo de panel solar DS new energy 600W monocristalino
    Np=6;
    Ns=20;
    Iscpanel=18.57;     %A
    Vocpanel=41.7;      %V
    alfa_isc=0.046;    %/ºC
    beta_vosc=-0.277;  % %/ºC
    Vmpptpanel=34.6;
    Impptpanel=17.49;
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
I0=I0ref*(Tk/Tref)^3*e^(q*Eg*(1/Tref-1/Tk)/(K*n));
Il=Su*Isc*(1+alfa_isc*(Tk-Tref)/100);
Vmppt=Vmpptpanel/Ns;

% Cálculo de Voc real (I=0)
flag_loop=0;
Vn=Vmppt;
itera=0;
error_max=0.001;
iteramax=1000;

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
if(Voc_panel_real<Vmpptpanel)
  disp("Tensión de panel mayor que tensión de circuito abierto");
  flag_loop=1;
  Ipanel=0;
else
  flag_loop=0;
endif

% Simulación de corriente en bus DC debido a la carga. Suponemos D=0.5
D=0.5;
c=1:3;
idcp(c)=Iscpanel*(c-1)/(Msampling*D);
c=4:Msampling;
idcp(c)=Iscpanel*(1-(c-1)/Msampling)/(1-D);

idc_load=[idcp idcp idcp idcp idcp];

L=length(idc_load);

% Simulación dinámica arco-panel
iarco=0;

for n=1:L
  % Valor de tensión DC
  idctotal=iarco+idc_load(n);
endfor








