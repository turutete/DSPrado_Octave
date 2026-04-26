#
# NSDSP_campofv.m
#
# Este script simula el caso de caída súbita de campo fotovoltaico en un
# inversor de 4.5MVA
#
# Autor: Dr. Carlos Romero Pérez
# Fecha: 25/04/2026
#

# Inicialización de variables de entorno
Fs=49000 ;                        % Freqcuencia de muestreo de las señales analógicas en Hz
fred=50;                          % Frecuencia de la red eléctrica en Hz
wred=2*pi*fred;
Fcontrol=2450;                    % Frecuencia del control
N=65536;                          % Número de muestras de la simulación
Vdcnom=1500;                      % Tensión nominal del bus DC en V
Vffrmsred=690;                    % Tensión RMS fase fase
Vfnrmsred=Vffrmsred/sqrt(3);      % Tensión RMS de red fase neutro
Snom=4.5e6;                       % Potencia aparente nominal del equipo
Lac=150e-6;                       % Inductancia del filtro LC en H
Cdc=53e-3;                        % Condensador del bus DC en F
Rcorto=0.001;                     % Resistencia de cortocircuito
Rgen=0.001;                       % Resistencia en serie de la fuente de corriente

# Consignas para resto de casos de uso
Plim=1;
Qref=0;

# Control de S<=1
if ((Plim^2+Qref^2)>1)
  Qref=sign(Qre)*sqrt(1-Plim^2);
endif



%Niveles máximos eléctricos del equipo
Idcnom=Snom/Vdcnom;
Vdcmax=Vdcnom*1.2;                % Umbral de sobretensión DC del equipo
Idcmax=Snom/Vdcnom*1.2;           % Umbral de sobrecorriente DC del equipo

Iacmax=2*(Snom/3)/(Vfnrmsred*sqrt(2))*1.2;    % Umbral de sobrecorriente AC del equipo
Vacmax=Vfnrmsred*sqrt(2)*1.2;                 % Umbral de sobretensión AC del equipo

% Modelo de panel PV
Np=1;
Ns=60;
Iscpanel=8.85;
Vocpanel=37.85;
alfa_isc=0.062;
beta_vosc=-0.33;
Vmpptpanel=30.12;
Impptpanel=8.3;
Npanels=round(Vdcnom/Vmpptpanel);
Npanelp=round(Idcnom/Impptpanel);

% Filtro Tensión de bus Corto circuito bus V0
B1corto=1/(Cdc*Fs);
A1corto=(B1corto/Rcorto-1);
xincortoz1=Vdcnom;
youtcortoz1=0;


% Simulador

n=1;                  % Índice temporal (t=n/Fs)
flag_Pdc=0;           % Se usa en el cálculo de Vdc de trabajo
dVdc=0.01;            % Intervalo de búsqueda de Vdc
dPdcmin=100;          % Valor inicial alto para primer punto de búsqueda
flag_pdcmin=0;        % Se usa en el algoritmo de cálculo de Vdc

% Condiciones ambientales
Su=1;
T=25;

% Formas de onda
iacr=[];               % Forma de onda de la corriente de salida fase R
iacs=[];               % Forma de onda de la corriente de salida fase S
iact=[];               % Forma de onda de la corriente de salida fase T

vacr=[];               % Forma de onda teórica de la tensión de salida R
vacs=[];               % Forma de onda teórica de la tensión de salida S
vact=[];               % Forma de onda teórica de la tensión de salida T

vrn=[];                 % Tensión fase r de salida del inversor
vsn=[];                 % Tensión fase s de salida del inversor
vtn=[];                 % Tensión fase t de salida del inversor

idc=[];                 % Corriente del bus DC
vdc=[];                 % Tensión del bus DC
idcin=[];               % Corriente de PV o Batería
icd=[];                 % Corriente por el condensador del bus

iarcdc=zeros(1,N);      % Corriente de arco DC
iarcac=zeros(1,N);      % Corriente de arco AC

% Formas de onda reales de Ir, Is, It
ir=[];
is=[];
it=[];

% Generamos las tensiones AC.
%
% La tensión de red no la podemos modificar desde el inversor. Nos sincronizamos
% a ella.
%
q=1:N;
vacr(q)=Vfnrmsred*sqrt(2)*cos(wred*(q-1)/Fs);
vacs(q)=Vfnrmsred*sqrt(2)*cos(wred*(q-1)/Fs-2*pi/3);
vact(q)=Vfnrmsred*sqrt(2)*cos(wred*(q-1)/Fs+2*pi/3);

% En esta simulación, Plim y Qref no varían. Son las consignas que piden
% la eléctrica a la planta.
%
% En primer lugar, se comprueba si el límite de potencia Plim que piden es 1 o
% menor que 1.
% Si es 1, piden la máxima potencia, por lo que hay que trabajar en mppt.
% Si es menor, el algoritmo de control del inversor calcula cuál debe ser
% el valor del bus DC que haga que la potencia generada por los paneles
% sea igual a la potencia demandada, evitando así que la tensión del bus
% aumente y llegue a una sobretensión de ruptura
if (Plim<1)
  Vdc=Vmpptpanel;
  Pdcobj=Plim*Snom/Npanelp;     % Calculamos por panel, no por inversor
  Idcprev=Impptpanel;
  Pdcprev=Vmpptpanel*Idcprev;

  while (flag_Pdc==0)
    % Usamos la función Idc_Panel para calcular la corriente del panel para
    % cada uno de los valores de Vdc que vamos a analizar.
    % Vdc tomará valores en el intervalo [Vmpptpanel Vocpanel].
    % Deben ser incrementos de Vdc pequeños, ya que la curva decrece a 0
    % muy rápidamente
    Vdc=Vdc*(1-dVdc);
    if (Vdc<=Vocpanel)
      Vdcpanel=Vocpanel;
      flag_Pdc=1;             % La tensión del panel máxima de la de circuito abierto
    endif

    %Idcaux=Idc_Panel(Vdc,Su,T,Iscpanel,Vocpanel,Vmpptpanel,Impptpanel,Ns,Np,alfa_isc,beta_vosc);
    Idcaux=Idc_Panel_Modelo(Vdc,Iscpanel,Vocpanel, Vmpptpanel, Impptpanel);
    Pdaux=Vdc*Idcaux;
    if (abs(Pdaux-Pdcobj)<dPdcmin)
      dPdcmin=abs(Pdaux-Pdcobj);
    else
      flag_Pdc=1;               % Encontrado el valor de Vdc que hace Ppanel=Plim
    endif
  endwhile
else
  % Si Plim=1, se trabaja en Mppt
  Vdc=Vmpptpanel;
  %Idcaux=Idc_Panel(Vdc,Su,T,Iscpanel,Vocpanel,Vmpptpanel,Impptpanel,Ns,Np,alfa_isc,beta_vosc);
  Idcaux=Idc_Panel_Modelo(Vdc,Iscpanel,Vocpanel, Vmpptpanel, Impptpanel);
endif


% En este punto conocemos Idcpanel e Vdcpanel que hacen que Ppv=Plimt
% Lo generalizamos a los Npanelp en paralelo y Npanels y obtenmos Vdc, Idc de trabajo
Vpv=Vdc*Npanels;
Idc=Idcaux*Npanelp;

% Modelo de dependencia de Vbus de (ipv-idc)
% Lo inicializamos al iniciar la simulación, cuando ya sabemos el valor
% inicial de Vdc
Kdc=1/(Cdc*Fs);
Adcz1=Vpv;    % Valor inicial del retraso y(n-1) del filtro LP para n=0


Sref=sqrt(Plim^2+Qref^2);

% Conocida la potencia aparente demandada, podemos calcular la corriente AC
% de salida que hay que generar, ya que la tensión de red es conocida y no
% depende de la dinámica interna del inversor.
%
% Llamamos a la amplitud de las corrientes de fase Im.
%
% El desfase de Ir, Is, It respecto También conocemos el desfase solicitado
%
% Im=2/3* Sref/(Vfnrmsred*sqrt(2))
%
% Conocido Im y phi, podremos generar la forma de onda de ir(t), is(t) e it(t)
%
% ir(t)=Im*cos(wred t + phi)
% is(t)=Im*cos(wred t + phi -2pi/3)
% it(t)=Im*cos(wred t + phi +2pi/3)
%

Im=2/3*Sref*Snom/(Vfnrmsred*sqrt(2));
phi=atan(Qref/Plim);

% Ahora queremos calcular la amplitud de la tensión de salida trifásica que
% debe generar el inversor para inyectar la corriente trifásica que hemos
% calculado.
% Usaremos Kircchoff, y trabajamos con fasores.
%
% La impedancia de una bobina es ZL=j wred Lac
% Iac=Im cos(phi)+ j Im sin(phi)
%
% Por Kircchoff: Vinvvac - Vfnrmsred = j*Iac*wred*Lac.
%
% Vinvvac=(Vfnrmsred- Im Lac wred sin(phi))+j Im L wred cos(phi)
%
% El módulo es:

Vinvvac=sqrt((Vfnrmsred*sqrt(2)-wred*Lac*Im*sin(phi))^2+(wred*Lac*Im*cos(phi))^2);

% El índice de modulación se obtiene de la expresión
% Vinvvac=M*Vdc/2

% Calculamos la señal completa para toda la simulación. Por eso sólo lo
% hacemos una vez, cuando n=1
% Es una señal triangular de -1 a 1. La frecuencia es Fcontrol, y tiene
% Fs/Fcontrol muestras por ciclo
%
% Esta señal es la que se usa para comparar con la señal senoidal que se quiere
% codificar.
v_tri = 2*abs(2*mod(Fcontrol*(q-1)/Fs, 1) - 1) - 1;


% Inicilaización de filtros de Ir, Is e It
vrredz1=Vfnrmsred*sqrt(2)*cos(wred*(-1)/Fs);
vsredz1=Vfnrmsred*sqrt(2)*cos(wred*(-1)/Fs-2*pi/3);
vtredz1=Vfnrmsred*sqrt(2)*cos(wred*(-1)/Fs+2*pi/3);
irredz1=Im*cos(wred*(-1)/Fs+phi);
isredz1=Im*cos(wred*(-1)/Fs+phi-2*pi/3);
itredz1=Im*cos(wred*(-1)/Fs+phi+2*pi/3);

flag_q=0;               % 0: Resistivo, 1: Inductivo, -1=Capacitivo

Rred=2*Plim*Snom/Im^2;
if (Qref>0)
  flag_q=1;
  Lred=Qref*Snom/(Im^2*pi*fred);
  Bred=1/(Rred+Lred*2*Fs);
  Ared=(Rred-2*Fs*Lred)/(Rred+2*Fs*Lred);
endif

if (Qref<0)
  flag_q=-1;
  Cred=-Im^2/(4*pi*fred*Qref*Snom);
  Bred=2*Fs/(1+2*Fs*Rred*Cred);
  Ared=(1-2*Fs*Rred*Cred)/(1+2*Fs*Rred*Cred);
endif


M=2*Vinvvac/Vpv;

while (n<=N)

  % Generamos las señales moduladoras, que son las que se quieren
  % obtener tras demodular las PWM. Como M puede variar durante la simulación
  % hay que calcularlo muestra a muestra

  mod_r= M*cos(wred*(n-1)/Fs);
  mod_s= M*cos(wred*(n-1)/Fs-2*pi/3);
  mod_t= M*cos(wred*(n-1)/Fs+2*pi/3);


  % Las señales Spx y Snx (x=r,s,t) son las señales PWM de cada una de las fases.
  % positiva y negativa.
  %
  % Se generan comparando las señales senoidales que se quieren generar,
  % es decir, mod_x, con la triangular.
  %

  Spr = (mod_r > 0) .* (mod_r >= (v_tri(n) + 1) / 2);
  Snr = (mod_r < 0) .* (mod_r <= (v_tri(n) - 1) / 2);

  Sps = (mod_s > 0) .* (mod_s >= (v_tri(n) + 1) / 2);
  Sns = (mod_s < 0) .* (mod_s <= (v_tri(n) - 1) / 2);

  Spt = (mod_t > 0) .* (mod_t >= (v_tri(n) + 1) / 2);
  Snt = (mod_t < 0) .* (mod_t <= (v_tri(n) - 1) / 2);

  % Calculamos la forma de onda de las corrientes idcpx(n)e idcnx,
  % que son las corriente en las ramas positivas y negativas de cada fase.
  %
  % La corriente total de cada fase x será la suma de ambas contribuciones
  %
  % idcx=idcpx+idcnx.
  %

  idcpr=Spr*Im*cos(wred*(n-1)/Fs +phi);
  idcnr=Snr*Im*cos(wred*(n-1)/Fs +phi);
  idcr=idcpr+idcnr;

  idcps=Sps*Im*cos(wred*(n-1)/Fs +phi-2*pi/3);
  idcns=Sns*Im*cos(wred*(n-1)/Fs +phi-2*pi/3);
  idcs=idcps+idcns;

  idcpt=Spt*Im*cos(wred*(n-1)/Fs +phi+2*pi/3);
  idcnt=Snt*Im*cos(wred*(n-1)/Fs +phi+2*pi/3);
  idct=idcpt+idcnt;

  % Forma de onda real en cada fase
  %
  % calculadas como Ired=Vred/Zred

  if (flag_q==0)
    ir(n)=vacr(n)/Rred;
    is(n)=vacs(n)/Rred;
    it(n)=vact(n)/Rred;
  else
    ir(n)=Bred*vacr(n)-Bred*vrredz1-Ared*irredz1;
    is(n)=Bred*vacs(n)-Bred*vsredz1-Ared*isredz1;
    it(n)=Bred*vact(n)-Bred*vtredz1-Ared*itredz1;

    vrredz1=vacr(n);
    irredz1=ir(n);
    vsredz1=vacs(n);
    isredz1=is(n);
    vtredz1=vact(n);
    itredz1=it(n);

  endif

  % Solo sumamos las positivas. Las negativas son iguales pero de sentido contrario
  %
  idc(n)=idcpr+idcps+idcpt;




  n=n+1;

endwhile

