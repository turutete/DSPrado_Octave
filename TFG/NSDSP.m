#
# Detección de Arco Eléctrico Mediante Técnicas de Procesamiento Digital
# de Señales No Estacionarias
#

# Selección de tipo de inversor (Descomentar el tipo de inversor)
inversor="PV";
#inversor="PCS"

switch (inversor)
  case {"PV"}
    inverter=0;
  case {"PCS"}
    inverter=1;
  otherwise
    inverter=0;
endswitch

% Inicialización de variables aleatorias
flag_aleatorio=0;                 % 0:No hay variables aleatorias 1: Hay aleatoriedad

# Inicialización de variables de entorno
Fs=2450;                         % Freqcuencia de muestreo de las señales analógicas en Hz
fred=50;                          % Frecuencia de la red eléctrica en Hz
wred=2*pi*fred;
Fcontrol=2450;                    % Frecuencia del control
N=4096;                          % Número de muestras de la simulación
Vdcnom=1500;                      % Tensión nominal del bus DC en V
Vffrmsred=690;                    % Tensión RMS fase fase
Vfnrmsred=Vffrmsred/sqrt(3);      % Tensión RMS de red fase neutro
Snom=4.5e6;                       % Potencia aparente nominal del equipo
Plim=1;                           % Límite de potencia activa [0 1] pedida
Qref=0;                           % Referencia de potencia reactiva [-1 1] pedida
Lac=150e-6;                       % Inductancia del filtro LC en H
Cdc=45e-3;                        % Condensador del bus DC en F
M=1;                              % Índice de modulación por defecto (M=Vinv/(Vdc/2))

%Niveles máximos eléctricos del equipo
Idcnom=Snom/Vdcnom;
Vdcmax=Vdcnom*1.2;                % Umbral de sobretensión DC del equipo
Idcmax=Snom/Vdcnom*1.2;           % Umbral de sobrecorriente DC del equipo

Iacmax=Snom/(3*Vfnrmsred)*1.2;    % Umbral de sobrecorriente AC del equipo
Vacmax=Vfnrmsred*1.2+2*pi*fred*Lac*Iacmax; % Umbral de sobretensión AC del equipo

porcentaje=zeros(1,N);


# Selección del tipo de prueba
tipo_arco="DC"; % Descomentar la opción del tipo de arco que se quiere hacer
#tipo_arco="AC"


# Parámetros de modelado de paneles solares
# Se estudian 3 ejemplos de paneles solares:
# 1) Ejemplo de panel de artículo
# 2) Ejemplopanel TSM-DE14A
# 3) Ejemplo panel DS 600W monocristalino

% Selector Panel
ejemplo=3;

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
    Npanels=round(Vdcnom/Vmpptpanel);
    Npanelp=round(Idcnom/Impptpanel);
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
    Npanels=round(Vdcnom/Vmpptpanel);
    Npanelp=round(Idcnom/Impptpanel);
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
    Npanels=round(Vdcnom/Vmpptpanel);
    Npanelp=round(Idcnom/Impptpanel);
endswitch

% Modelo de arco eléctrico AC
Rl_arco=10;   % Resistencia del circuito de carga al producirse el arco [ohms]
Vd=900;       % Tensión de creación de canal
Id=0.1;       % Corriente inicio de creación de canal
V0=25;        % Tensión del arco

alfa_arco=V0*pi/2;                % Parámetro alpha del modelo
Rc_arco=Vd/Id;                    % Parámetros Rc del modelo
beta_arco=tan(alfa_arco/Vd)/Id;   % Parámetro beta del modelo


% Modelo dinámico del arco eléctrico
tau_aval=100e-6; % Parámetro tau (modelamos el tiempo de formación del canal
nest=tau_aval*Fs;
tau=1/(Fs*(e^(2.3/nest)-1));

a0=1+tau*Fs;    % Coeficientes del filtro IIR que modela la dinámica
a1=-tau*Fs;
Nom=1/a0;
Den=a1/a0;
DenVz1=0;       % Retraso del filto IIR tensión
DenIz1=0;       % Retraso del filtro IIR corriente


% Cálculo de puntos de trabajo
dI=0.01;
It=(-32768:32767).*dI;
Vt=(alfa_arco*Rc_arco.*It)./(atan(beta_arco.*It).*It.*Rc_arco+alfa_arco); % Curva V-I arco

Vaval=max(Vt);  % Tensión aproximada de avalancha


if (tipo_arco=="DC")
  flag_tipo_arco=0;
else
  flag_tipo_arco=1;
endif

# El código siguiente es el simulador dinámico de la planta+inversor+red
# El simulador genera las tensiones y corriente de AC y DC
# incluyendo el arco elegido, y su efecto en las tensiones y corrientes.
#
# El valor de la irradiancia es constante, por lo que la curva I-V de los
# paneles es constante.
#
# De igual forma, Plim y Qref son constantes en la simulación.

n=1;                  % Índice temporal (t=n/Fs)
flag_Pdc=0;           % Se usa en el cálculo de Vdc de trabajo
dVdc=0.01;            % Intervalo de búsqueda de Vdc
dPdcmin=100;          % Valor inicial alto para primer punto de búsqueda
flag_pdcmin=0;        % Se usa en el algoritmo de cálculo de Vdc

% Formas de onda
iacr=[];               % Forma de onda de la corriente de salida fase R
iacs=[];               % Forma de onda de la corriente de salida fase S
iact=[];               % Forma de onda de la corriente de salida fase T

vacr=[];               % Forma de onda de la tensión de salida R
vacs=[];               % Forma de onda de la tensión de salida S
vact=[];               % Forma de onda de la tensión de salida T

idc=[];                 % Corriente del bus DC
vdc=[];                 % Tensión del bus DC

varcdc=zeros(1,N);      % Tensión de arco DC
iarcdc=zeros(1,N);      % Corriente de arco DC
varcac=zeros(1,N);      % Tensión de arco AC
iarcac=zeros(1,N);      % Corriente de arco AC


# Control de las referencias de Plim y Qref
Sref=sqrt(Plim^2+Qref^2);
if (Sref>1)
  Qref=sign(Qref)*sqrt(1-Plim^2);
endif

Pfisica=Snom*Plim;  % Consignas de potencia demandadas por el operador de red
Qfisica=Snom*Qref;

# Este código define la irradiancia y la temperatura en la planta.
# Según se haya seleccionado usar o no aleatoriedad, se usa unos valores de
# irradiancia Su=1 y T=25ºC, o se escoge cierta aleatoriedad cada vez que se
# ejecuta el script

if (flag_aleatorio==0)
  % Condiciones ambientales
  Su=1;
  T=25;
  indarc=floor(N/2);    % El arco se inicia en la mitad de la simulación
else
  Su=0.5+0.5*rand(1);    % Irradiancia por unidad S/Sref [0.5 - 1]
  T=25+15*(1-rand(1));   % Temperatura en ºC [25 - 40]
  indarc=floor(N/4+1/2*randn(1));   % El arco se inicia en algún punto [N/4 3N/4]
endif

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

    Idcaux=Idc_Panel(Vdc,Su,T,Iscpanel,Vocpanel,Vmpptpanel,Impptpanel,Ns,Np,alfa_isc,beta_vosc);
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
  Idcaux=Idc_Panel(Vdc,Su,T,Iscpanel,Vocpanel,Vmpptpanel,Impptpanel,Ns,Np,alfa_isc,beta_vosc);
endif


% En este punto conocemos Idcpanel e Vdcpanel que hacen que Ppv=Plimt
% Lo generalizamos a los Npanelp en paralelo y Npanels y obtenmos Vdc, Idc de trabajo
Vpv=Vdc*Npanels;
Idc=Idcaux*Npanelp;

% Modelo de dependencia de Vbus de (ipv-idc)
% Lo inicializamos al iniciar la simulación, cuando ya sabemos el valor
% inicial de Vdc
Kdc=1/(Cdc*Fs);
Bdcz1=0;      % Valor inicial del retraso x(n-1) del filtro LP para n=0
Adcz1=Vpv;    % Valor inicial del retraso y(n-1) del filtro LP para n=0

Iarc=0;

%Condición inicial de campo fotovoltaico
Vdc=Vpv/Npanels;
Idcaux=Idc_Panel(Vdc,Su,T,Iscpanel,Vocpanel,Vmpptpanel,Impptpanel,Ns,Np,alfa_isc,beta_vosc);
Ipv=Idcaux*Npanelp;

while (n<=N)

  porcentaje(n)=(n-1)*100/N;
  plot(q-1,porcentaje);

  % Conocido el valor de la tensión de bus DC, se puede calcular el valor de la
  % amplitud de las corrientes de fase Ir, Is, It para inyectar la Plim y Qref
  % solicitada. Llamamos a esta amplitud Im. También conocemos el desfase solicitado
  %
  % Im=2/3* Sref/Vfnrmsred
  %
  % Conocido Im y phi, podremos generar la forma de onda de ir(t), is(t) e it(t)
  %
  % ir(t)=Im*cos(wred t + phi)
  % is(t)=Im*cos(wred t + phi -2pi/3)
  % it(t)=Im*cos(wred t + phi +2pi/3)
  %
  % Si se produce arco DC, la corriente Iarc debe ser alimentada por la
  % corriente de paneles, por lo que la la amplitud Im decrece de la teóricamente
  % calculada

  Im=max(2/3*Sref*Snom/Vfnrmsred-Iarc,0);    % Im no puede ser negativo
  phi=atan(Qref/Plim);

  % Si se produce un arco en AC, la corriente AC de salida de la fase donde
  % se produzca el arco aumentará con la corriente que consume el arco
  % Supondremos siempre en esta simulación que se produce en la fase Ir
  %
  % ir(t)=Im cos(wred t +phi) + Iarc(t)
  %
  % Pero esto no afecta al cálculo de Vinvac, ya que lo que se usa para
  % calcular el índice de modulación son las consignas Plim y Qref, no la medida
  % de corrientes de fase real

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

  Vinvvac=sqrt((Vfnrmsred-wred*Lac*Im*sin(phi))^2+(wred*Lac*Im*cos(phi))^2);

  % El índice de modulación se obtiene de la expresión
  % Vinvvac=M*Vdc/2
  if (n==1)
    M=2*Vinvvac/(Vdc*Npanels);
  else
    M=2*Vinvvac/Vpv;
  endif

  % Calculamos formas de onda en AC en el instante n
  if (flag_tipo_arco==1 && n>=indarc)
    % Cálculo de puntos de trabajo
    % Buscamos los punto de corte de la recta de carga con la V-I del arco
    Vt2=vacr(n)-It.*Rl_arco;
    % Cálculo rápido puntos corte
    if (abs(vacr(n))<=abs(Vaval))
      index_corte=Puntos_Corte(Vt,Vt2);
      It_corte=(index_corte-32769).*dI;
      Vt_corte=vacr(n)-It_corte.*Rl_arco;
    else
      V0=2*alfa_arco/pi;
      It_corte=sign(vacr(n))*(abs(vacr(n))-V0)/Rl_arco;
      Vt_corte=sign(vacr(n))*V0;
    endif

    if start_arc==1
      % El primer punto, se escoge en zona de descarga luminiscente
      % si uno de los puntos de corte está en esta zona. Si no, se
      % escoge el de mayor corriente en zona de avalancha
      start_arc=0;
      [Itn,indtn]=min(It_corte);

      Vtn=Vt_corte(indtn);
      Vtprev=Vtn;
      Itprev=Itn;
      Ptprev=Vtn*Itn;
    else
      Pn_vect=It_corte.*Vt_corte;
      Pnprev_vect=Ptprev*ones(size(It_corte));
      Pdif=abs(Pnprev_vect-Pn_vect);
      [Pdifmin,indmin]=min(Pdif);
      Vtn=Vt_corte(indmin);
      Itn=It_corte(indmin);
      Vtprev=Vtn;
      Itprev=Itn;
      Ptprev=Vtn*Itn;
    endif

    % Filtrado dinámico del arco
    Varc=Vtn*Nom-DenVz1*Den;
    DenVz1=Varc;
    iarcac(n)=Itn*Nom-DenIz1*Den;
    DenIz1=iarcac(n);
  endif

  % Si se ha producido arco AC las corrientes de fase medidas por el inversor
  % serán:
  %
  % ir(t)= Im cos(wred t+ phi) + Iarc(t)
  % is(t)= Im cos(wred t + phi -2pi/3)
  % it(t)= Im cos(wred t + phi +2pi/3)

  iacr(n)= Im*cos(wred*(n-1)/Fs+phi)+iarcac(n);
  iacs(n)= Im*cos(wred*(n-1)/Fs+phi-2*pi/3);
  iact(n)= Im*cos(wred*(n-1)/Fs+phi+2*pi/3);

  % Analizamos ahora la parte de DC
  %
  % Hemos calculado el valor del íncide de modulación M necesario
  % para generar el Plim que solicita la eléctrica.
  %
  % En un inversor con etapa de potencia en 3 niveles, el valor de la corriente
  % en el bus de DC idc(t) se puede expresar del siguiente modo:
  %
  % idc(t)=Sum (M*cos(wx t)*(sign(cos(wx t)+1)/2))*Im*cos(wx t+phi)
  %         x=r,s,t
  %
  % siendo wr t=wred t , ws t = wred t - 2pi/3  y wt t= wred t + 2pi/3
  %
  idcr=M*cos(wred*(n-1)/Fs)*(sign(cos(wred*(n-1)/Fs)+1)/2)*Im*cos(wred*(n-1)/Fs+phi);
  idcs=M*cos(wred*(n-1)/Fs-2*pi/3)*(sign(cos(wred*(n-1)/Fs-2*pi/3)+1)/2)*Im*cos(wred*(n-1)/Fs-2*pi/3+phi);
  idct=M*cos(wred*(n-1)/Fs+2*pi/3)*(sign(cos(wred*(n-1)/Fs+2*pi/3)+1)/2)*Im*cos(wred*(n-1)/Fs+2*pi/3+phi);


  % En esta punto, añadimos la simulación de arco eléctrico en DC
  %
  % Si se produce, la corriente de arco DC deberá suministrarla el campo fotovoltaico

   if (n>=indarc && flag_tipo_arco==0)
    % Cálculo de puntos de trabajo
    Vt2=vdc(n)-It.*Rl_arco;
    % Cálculo rápido puntos corte
    if (abs(vdc(n))<=abs(Vaval))
      index_corte=Puntos_Corte(Vt,Vt2);
      It_corte=(index_corte-32769).*dI;
      Vt_corte=v-It_corte.*Rl_arco;
    else
      V0=2*alfa_arco/pi;
      It_corte=sign(vdc(n))*(abs(vdc(n))-V0)/Rl_arco;
      Vt_corte=sign(vdc(n))*V0;
    endif

    if start_arc==1
      % El primer punto, se escoge en zona de descarga luminiscente
      % si uno de los puntos de corte está en esta zona. Si no, se
      % escoge el de mayor corriente en zona de avalancha
      start_arc=0;
      [Itn,indtn]=min(It_corte);

      Vtn=Vt_corte(indtn);
      Vtprev=Vtn;
      Itprev=Itn;
      Ptprev=Vtn*Itn;
    else
      Pn_vect=It_corte.*Vt_corte;
      Pnprev_vect=Ptprev*ones(size(It_corte));
      Pdif=abs(Pnprev_vect-Pn_vect);
      [Pdifmin,indmin]=min(Pdif);
      Vtn=Vt_corte(indmin);
      Itn=It_corte(indmin);
      Vtprev=Vtn;
      Itprev=Itn;
      Ptprev=Vtn*Itn;
    endif

    % Filtrado dinámico del arco
    Varc=Vtn*Nom-DenVz1*Den;
    DenVz1=Varc;

    Iarc=Itn*Nom-DenIz1*Den;

    DenIz1=Iarc;
    iarcdc(n)=Iarc;
  endif

  idc(n)=idcr+idcs+idct+Iarc;

  % Este idc(n) es el que consume la etapa de potencia para generar la amplitud
  % Vinvvac.
  %
  % Esta corriente la suministra el campo fotovoltaico. Esta corriente la
  % puede suministrar porque la tensión del bus DC se ha regulado al punto.
  %
  % Si por cualquier motivo la corriente que consume idc es mayor que la que puede
  % generar el campo, la energía la proporcionaría el C, y bajaría la tensión
  % de bus. Si lo que ocurre es que baja el consumo de Idc, subiría la tensión
  % de bus.
  %
  % El valor de Vdc(t) se puede modelar en función de ipv(t)-idc(t) mediante
  % un filtro LP H(z)
  %
  % H(z)=1/(Cdc*Fs)* Z^-1/(1-Z^-1)
  %
  xinaux=Ipv-idc(n);
  vdc(n)=Kdc*Bdcz1+Adcz1;
  Bdcz1=xinaux;
  Adcz1=vdc(n);
  Vpv=vdc(n);       % Modificación de la tensión del bus por Ipv-Idc(n)

  %Esta tensión de bus impone un nuevo valor de corriente de panel Idc
  Vdc=Vpv/Npanels;
  Idcaux=Idc_Panel(Vdc,Su,T,Iscpanel,Vocpanel,Vmpptpanel,Impptpanel,Ns,Np,alfa_isc,beta_vosc);
  Ipv=Idcaux*Npanelp;

  n=n+1;

endwhile


