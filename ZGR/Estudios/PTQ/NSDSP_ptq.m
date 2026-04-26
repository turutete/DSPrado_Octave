#
# Detección de Arco Eléctrico Mediante Técnicas de Procesamiento Digital
# de Señales No Estacionarias
#
# Autor: Dr. Carlos Romero Pérez
# Fecha: 18/04/2026
#

inverter= menu("TIPO INVERSOR","PV","PCS");
inversor=inverter-1;

flag_tipo_arco= menu("CASO DE USO","DC","AC","ESTABLE","PREF VARIABLE","IM SÚBITA");

flag_tipo_arco=flag_tipo_arco-1;

% Inicialización de variables aleatorias
flag_aleatorio=0;                 % 0:No hay variables aleatorias 1: Hay aleatoriedad


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
rampa=0.1;                        % Rampa %Snominal/s
Rbat=0.005;                       % Tensión thevening de la batería
Vcaida=16.549;                    % Caida de Vdc por Rbat


# Variables de actualización cada Fcontrol
Ncontrol=Fs/Fcontrol;
flag_control=1;
contador_control=0;

# Consignas para el caso de uso PREF VARIABLE
Pliminit=0.8;
Qrefinit=0.1;
Ptarget=1;
Qtarget=0;

# Consignas para resto de casos de uso
Plim=1;
Qref=0;

# Control de S<=1
if ((Pliminit^2+Qrefinit^2)>1)
  Qrefinit=sign(Qrefinit)*sqrt(1-Pliminit^2);
endif

if ((Ptarget^2+Qtarget^2)>1)
  Qtarget=sign(Qtarget)*sqrt(1-Ptarget^2);
endif

 if ((Plim^2+Qref^2)>1)
  Qref=sign(Qref)*sqrt(1-Plim^2);
endif


%Niveles máximos eléctricos del equipo
Idcnom=Snom/Vdcnom;
Vdcmax=Vdcnom*1.2;                % Umbral de sobretensión DC del equipo
Idcmax=Snom/Vdcnom*1.2;           % Umbral de sobrecorriente DC del equipo

Iacmax=2*(Snom/3)/(Vfnrmsred*sqrt(2))*1.2;    % Umbral de sobrecorriente AC del equipo
Vacmax=Vfnrmsred*sqrt(2)*1.2;                 % Umbral de sobretensión AC del equipo

% Filtro Tensión de bus V0=f(Vbat,Idc)
aux=Rbat*Cdc*Fs;
aux2=1-aux;
Bdc1=1/aux;
Adc1=aux2/aux;

vdcz1=Vdcnom;
v0z1=Vdcnom;


if (inverter==0)
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

  # Aunque la potencia Snom del equipo dea 4.5MVA, la real es la que suministre
  # el campo fotovoltaico
  Vnomreal=Vmpptpanel*Npanels;
  Inomreal=Impptpanel*Npanelp;
  Snomreal=Vnomreal*Inomreal;
else
  # En el caso de ser un PCS, la fuente de DC son bateríss
  Vbateria=Vdcnom+Vcaida;
endif



% Cálculo de puntos de trabajo
%dI=0.01;
%It=(-32768:32767).*dI;
%Vt=(alfa_arco*Rc_arco.*It)./(atan(beta_arco.*It).*It.*Rc_arco+alfa_arco); % Curva V-I arco

%Vaval=max(Vt);  % Tensión aproximada de avalancha


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
flag_fallo_Idc=0;     % Se usan para mostrar sólo una vez el texto de fallo en consola
flag_fallo_Iac=0;     % Se usan para mostrar sólo una vez el texto de fallo en consola
flag_rampaP=0;        % Se usa en el control de la rampa de P
flag_rampaQ=0;        % Se usa en el control de la rampa de Q

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



# Este código define la irradiancia y la temperatura en la planta.
# Según se haya seleccionado usar o no aleatoriedad, se usa unos valores de
# irradiancia Su=1 y T=25ºC, o se escoge cierta aleatoriedad cada vez que se
# ejecuta el script

if (flag_aleatorio==0)
  % Condiciones ambientales
  Su=1;
  T=25;
  indarc=floor(N/2);    % El arco se inicia en la mitad de la simulación
  indeven=floor(N/2);   % Muestra en la que se produce el evento no arco
else
  Su=0.5+0.5*rand(1);    % Irradiancia por unidad S/Sref [0.5 - 1]
  T=25+15*(1-rand(1));   % Temperatura en ºC [25 - 40]
  indarc=floor(N/4+1/2*randn(1));   % El arco se inicia en algún punto [N/4 3N/4]
  indeven=floor(N/4+1/2*randn(1));  % El evento no arco se inicia en algún punto [N/4 3N/4]
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

if (inversor==0)
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


  %Condición inicial de campo fotovoltaico
  Vdc=Vpv/Npanels;
  %Idcaux=Idc_Panel(Vdc,Su,T,Iscpanel,Vocpanel,Vmpptpanel,Impptpanel,Ns,Np,alfa_isc,beta_vosc);
  Idcaux=Idc_Panel_Modelo(Vdc,Iscpanel,Vocpanel, Vmpptpanel, Impptpanel);
  Ipv=Idcaux*Npanelp;
else
  Vpv=Vbateria;       % La tensión de entrada al bus es constante con baterías
endif


while (n<=N)

  % Este bloque se añade para los casos de uso donde se modifique Sref en un
  % momento dado.
  %
  % Cuando cambia la consigna, el cambio lo hace siempre el inversor mediante
  % una rampa. La pendiente de la rampa rampa (%VA/s) está definida al inicio
  % del script

  if (flag_tipo_arco==0 || flag_tipo_arco==1 || flag_tipo_arco==2)
    Plim=1;       % Límite de potencia activa [0 1] pedida
    Qref=0;       % Referencia de potencia reactiva [-1 1] pedida
  endif

  if (flag_tipo_arco==3)
    if (n<=indeven)
      Plim=Pliminit;          % Límite de potencia activa [0 1] pedida
      Qref=Qrefinit;          % Referencia de potencia reactiva [-1 1] pedida
    else
      if (n==(indeven+1))
        Plimprev=Pliminit;
        Qrefprev=Qrefinit;
        flag_rampaP=0;        % Indica '1' cuando se alcanza Ptarget
        flag_rampaQ=0;        % Indica '1' cuando se alcanza Qtarget
        signop=sign(Ptarget-Pliminit);
        signoq=sign(Qtarget-Qrefinit);
      endif
      if (flag_rampaP==0)
        Plim=Plimprev+signop*(rampa/Fs);
        if (signop==1 && Plim>=Ptarget)
          Plim=Ptarget;
          flag_rampaP=1;
        endif
        if (signop==-1 && Plim<=Ptarget)
          Plim=Ptarget;
          flag_rampaP=1;
        endif
      endif
      if (flag_rampaQ==0)
        Qref=Qrefprev+signoq*(rampa/Fs);
        if ((Plim^2+Qref^2)>1)
          Qref=sign(Qref)*sqrt(1-Plim^2);    % Prioridad P
        endif

        if ((signoq==1 && Qref>=Qtarget ) || (signoq==-1 && Qref<=Qtarget))
          Qref=Qtarget;
          flag_rampaQ=1;
        endif
      endif
    endif
  endif


  if (flag_tipo_arco==4)
    # Caso no realista que en el instante de inicio del evento, la Potencia P
    # forma paulatina al 100% y Q=0%, sin rampa
    if (n<indeven)
      Plim=Pliminit;          % Límite de potencia activa [0 1] pedida
      Qref=Qrefinit;          % Referencia de potencia reactiva [-1 1] pedida
    else
      Plim=1;
      Qref=0;
    endif
  endif

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

  if (flag_control==1)
    % El valor de M se actualiza cada ciclo de control
    if (inversor==0)
      if (n==1)
        M=2*Vinvvac/(Vdc*Npanels);
      else
        M=2*Vinvvac/Vpv;
      endif
    else
      M=2*Vinvvac/v0z1;
    endif

    if (M>1.15)
      M=1.15;         % Saturación que se pone al índice de modulación para no aumentar THD
    endif

    flag_control=0;
    contador_control=0;
  endif

  contador_control=contador_control+1;
  if (contador_control==Ncontrol)
    flag_control=1;
  endif


  % Generamos la corriente de arco, según sea el tipo de arco seleccionado
  if (n>=indarc)
    if (flag_tipo_arco==0)
      Iarcdc=Genera_Iarc_RT(Vpv,Fs);
      Iarcac=0;
      iarcdc(n)=Iarcdc;
    elseif (flag_tipo_arco==1)
      Iarcac=Genera_Iarc_RT(vacr(n),Fs);   % El arco se produce en la fase R
      Iarcdc=0;
      iarcac(n)=Iarcac;
    else
      Iarcac=0;
      Iarcdc=0;
    endif
  else
    Iarcac=0;
    Iarcdc=0;
  endif

  % La corriente que se desea generar es:
  %
  % ir(t)= Im cos(wred t+ phi) + Iarc(t)
  % is(t)= Im cos(wred t + phi -2pi/3)
  % it(t)= Im cos(wred t + phi +2pi/3)

  iacr(n)= Im*cos(wred*(n-1)/Fs+phi);
  iacs(n)= Im*cos(wred*(n-1)/Fs+phi-2*pi/3);
  iact(n)= Im*cos(wred*(n-1)/Fs+phi+2*pi/3);


  % Analizamos ahora la parte de DC
  %
  % Hemos calculado el valor del índice de modulación M necesario
  % para generar el Plim que solicita la eléctrica.
  %
  % En un inversor con etapa de potencia en 3 niveles, el valor de la corriente
  % en el bus de DC idc(t) se puede expresar del siguiente modo:
  %
  % Se genera la portadora PWM v_tri que es una triangular de frecuencia
  % Fcontrol. Esta portadora se usa para genera las PWM de cada fase Sx.
  %
  % mod_x= M* cos(wredx t)
  %
  % Por cada fase hay 2 PWM, la de los igbt para el ciclo positivo y los igbt
  % del ciclo negativo
  %
  % Spx = (mod_x>0)*(mod_x>=v_tri)
  % Snx = (mod_x<0)*(mod_x<=-v_tri)
  %
  % Spx y Sns son señales digitales (0,1). '1' activa los igbts de la rama positiva
  % o negativa, según sea el semiperiodo de la moduladora (que es la señal que
  % se está codificando.
  %
  % Las corrientes de la rama positiva y negativa vendrán dadas por:
  %
  % idcpx=Spx*Im*cos(wredx t +phi)
  % idcnx=SnxÎm*cons(wredx t +phi)
  %
  % La corriente idcx de cada fase viene dada por la contribución
  % de la corriente durante el semiperiodo positivo y el negativo:
  %
  % idcx=idcpx+idcnx
  %
  % siendo:
  %
  % (wredx t) = (2pi fref (n-1)/Fs+phix)
  %
  % donde phix=0, -2pi/3, 2pi/3
  %
  % Estas señales de idcx son realistas
  %



  % Generamos la señal triangular, que es la misma para las 3 fases
  if (n==1)
    % Calculamos la señal completa para toda la simulación. Por eso sólo lo
    % hacemos una vez, cuando n=1
    % Es una señal triangular de -1 a 1. La frecuencia es Fcontrol, y tiene
    % Fs/Fcontrol muestras por ciclo
    %
    % Esta señal es la que se usa para comparar con la señal senoidal que se quiere
    % codificar.
    v_tri = 2*abs(2*mod(Fcontrol*(q-1)/Fs, 1) - 1) - 1;

    idcprmax=0;
  endif

  % Generamos también las señales moduladoras, que son las que se quieren
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

  if (idcpr>idcprmax)
    idcprmax=idcpr;
  endif


  % Solo sumamos las positivas. Las negativas son iguales pero de sentido contrario
  %
  idc(n)=idcpr+idcps+idcpt;

  % Las tensiones trifásicas

  % Cálculo del valor de tensión en bus dc V0(n)
  xdcin=Vpv-Rbat*idc(n);
  vdc(n)=vdcz1*Bdc1-v0z1*Adc1;
  v0z1=vdc(n);
  vdcz1=xdcin;

  % Cálculo de la corriente de salida de la batería
  idcin(n)=(Vbateria-vdc(n))/Rbat;

  % Cálculo de la corriente por el condensador de DC Ic(s)=C S V0(s)

  icd(n)=idcin(n)-idc(n);

  % Tensiones Vr, Vs, Vt
  vrn(n) = (Spr - Snr) * (vdc(n)/ 2);
  vsn(n) = (Sps - Sns) * (vdc(n) / 2);
  vtn(n) = (Spt - Snt) * (vdc(n) / 2);


  if (inversor==0)

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
    % Vdc(n+1)=Vdc(n)+1/(Cdc*Fs) * (Ipv(n)-Idc(n) - Iarc(n))
    %

    % --- PASO 1: PREDICCIÓN (Euler simple) ---
    % Calculamos la pendiente actual (derivada)
    xinaux=Ipv-idc(n)-Iarc;
    derivada_k=xinaux/Cdc;
    % Predicción de la tensión en el siguiente instante
    if (n==1)
      Vdc_predict= Vpv + (1/Fs)*derivada_k;
    else
      Vdc_predict= vdc(n-1) + (1/Fs)*derivada_k;
    endif

    % --- PASO 2: CORRECCIÓN ---
    % Calculamos la nueva Ipv y la nueva idc basada en la predicción
    Vdc_panel_predict = Vdc_predict / Npanels;
    Idcaux_predict = Idc_Panel_Modelo(Vdc_panel_predict, Iscpanel, Vocpanel, Vmpptpanel, Impptpanel);
    Ipv_predict = Idcaux_predict * Npanelp;

    % Para idc(n+1) usamos el siguiente valor de la sumatoria (n+1)
    % [Cálculo de idc_predict usando (n+1)/Fs]
    derivada_k_next = (Ipv_predict - idc_predict - Iarc) / Cdc;
    % Valor final corregido (Promedio de pendientes)
    if (n==1)
      vdc(n) = Vpv + (1/(2*Fs)) * (derivada_k + derivada_k_next);
    else
      vdc(n) = vdc(n-1) + (1/(2*Fs)) * (derivada_k + derivada_k_next);
    endif


    % Actualizamos variables de estado para el siguiente ciclo
    Vpv = vdc(n);
    Adcz1 = Vpv;

    vdc(n)=Kdc*xinaux+Adcz1;
    Adcz1=vdc(n);
    Vpv=vdc(n);       % Modificación de la tensión del bus por Ipv-Idc(n)

    %Esta tensión de bus impone un nuevo valor de corriente de panel Idc
    Vdc=Vpv/Npanels;
    %Idcaux=Idc_Panel(Vdc,Su,T,Iscpanel,Vocpanel,Vmpptpanel,Impptpanel,Ns,Np,alfa_isc,beta_vosc);
    Idcaux=Idc_Panel_Modelo(Vdc,Iscpanel,Vocpanel, Vmpptpanel, Impptpanel);
    Ipv=Idcaux*Npanelp;

    if (idc(n)>Idcmax && flag_fallo_Idc==0)
      flag_fallo_Idc=1;
      fprintf('Sobrecorriente DC Idc(%d)= %f\n', n, idc(n));
    endif

  else
    % Caso PCS
    if (flag_tipo_arco==0 && flag_fallo_Idc==0 && idc(n)>(Idcmax*sqrt(2)))
      flag_fallo_Idc=1;
      fprintf('Sobrecorriente DC Idc(%d)= %f\n', n, idc(n));
    endif
    if (flag_tipo_arco==1 && flag_fallo_Iac==0 && iacr(n)>Iacmax)
      flag_fallo_Iac=1;
      fprintf('Sobrecorriente Iacr(%d)= %f\n', n, iacr(n));
    endif
  endif


  n=n+1;

endwhile



