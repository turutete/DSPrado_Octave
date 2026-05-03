##
## @file NSDSP_campofv.m
## @brief Simulación de caída súbita de campo fotovoltaico en inversor de 4.5 MVA.
##
## Este script simula el comportamiento dinámico de un inversor fotovoltaico
## trifásico de 4.5 MVA conectado a red, con el objetivo de analizar el
## transitorio que se produce cuando el campo fotovoltaico sufre una caída
## súbita de generación. La simulación trabaja muestra a muestra a 49 kHz, lo
## que permite reproducir tanto la dinámica del bus DC (oscilaciones a 100/300
## Hz, transitorios de carga del condensador) como el rizado de conmutación
## debido al PWM a 2,45 kHz.
##
## @section arquitectura Arquitectura modelada
## El sistema se modela como un campo fotovoltaico (Npanels en serie x Npanelp
## en paralelo) representado como una fuente de tensión Vpv con una resistencia
## Rgen en serie. Esta fuente alimenta el bus DC (condensador Cdc), que a su
## vez alimenta un puente trifásico de dos niveles. La salida del puente pasa
## por un filtro inductivo Lac que la conecta a la red trifásica de 690 V /
## 50 Hz. La red se considera una fuente de tensión ideal (sin impedancia
## equivalente), a la que el inversor se sincroniza.
##
## @section bloques Bloques principales del script
## @par 1. Parámetros del equipo y red.
## Frecuencia de muestreo (Fs), frecuencia de control PWM (Fcontrol), red
## (fred, Vffrmsred), nominales del inversor (Snom, Vdcnom), filtro de salida
## (Lac), bus DC (Cdc), resistencias de modelo (Rgen, Rcorto), niveles
## máximos (Vdcmax, Idcmax, Vacmax, Iacmax) al 120 % del nominal.
##
## @par 2. Consignas de potencia.
## El inversor recibe Plim (límite de potencia activa, normalizado) y Qref
## (consigna de reactiva, normalizada). Se aplica una limitación que garantiza
## que la potencia aparente solicitada cumple S ≤ 1, ajustando Qref si es
## necesario.
##
## @par 3. Modelo del campo fotovoltaico.
## Cada panel se modela mediante la función Idc_Panel_Modelo, que es una
## aproximación lineal por tramos de la curva I-V: tramo izquierdo (de Iscpanel
## a Impptpanel para Vdc en [0, Vmpptpanel]) y tramo derecho (de Impptpanel a 0
## para Vdc en [Vmpptpanel, Vocpanel]).
##
## @par 4. Búsqueda del punto de trabajo Vdc.
## Si Plim = 1, el inversor opera en MPPT y la condición inicial es
## (Vmpptpanel, Impptpanel). Si Plim < 1, se realiza una búsqueda iterativa
## en la rama derecha de la curva P-V (Vmpptpanel a Vocpanel) hasta encontrar
## el Vdc por panel que iguala la potencia generada con la demandada. Este Vdc
## se generaliza al campo completo: Vpv = Vdc·Npanels e Ipv = Idcaux·Npanelp.
##
## @par 5. Cálculo de magnitudes teóricas.
## A partir de Plim y Qref se obtiene la amplitud de pico de la corriente de
## fase Im = (2/3)·S·Snom/(Vfn_pico) y su desfase respecto a la tensión de red
## phi = atan(Qref/Plim). Por aplicación de Kirchhoff fasorial sobre Lac se
## obtiene la amplitud de la tensión que debe sintetizar el inversor antes del
## filtro, Vinvvac, y el índice de modulación M = 2·Vinvvac/V0.
##
## @par 6. Generación de señales pre-bucle.
## Se generan vectorialmente la triangular v_tri (a Fcontrol, en fase con el
## reloj de muestreo) y las tensiones de red vacr, vacs, vact (sinusoides a
## fred, sincronizadas a v_tri). Estas señales son fijas durante toda la
## simulación.
##
## @par 7. Modelo dinámico del bus DC.
## El campo fotovoltaico se modela como una fuente de corriente no lineal
## gobernada por la curva I-V del panel: para cada tensión Vpanel a la que
## se obliga al panel a trabajar, éste entrega la corriente Ipanel dictada
## por su curva I-V. La rama serie-paralelo (Npanels x Npanelp) entrega una
## corriente total Ipv = Ipanel·Npanelp a la tensión total Vpanel·Npanels.
##
## La conexión al bus es: campo PV ─ Rgen ─ bus DC (con Cdc), de manera que
## la malla cumple Vpanel·Npanels = V0 + Ipv·Rgen y el balance de corrientes
## en el nodo del bus es Cdc·dV0/dt = Ipv - Idc.
##
## Aplicando la transformación bilineal s = 2·Fs·(z-1)/(z+1) sobre la ecuación
## del bus se obtiene la regla del trapecio:
##   V0(n) = V0(n-1) + Kbus·[(Ipv(n) - Idc(n)) + (Ipv(n-1) - Idc(n-1))]
## con Kbus = 1/(2·Fs·Cdc).
##
## En cada muestra se resuelve el sistema acoplado (regla del trapecio +
## malla + curva I-V) en forma cerrada, eligiendo el tramo de la curva I-V
## adecuado (izquierdo si Vpanel < Vmpptpanel, derecho en caso contrario).
## Esto permite que la corriente Ipv responda dinámicamente a la tensión del
## bus: cuando V0 supera Vmpptpanel·Npanels (operación con Plim<1), Ipv cae
## de forma controlada hasta equilibrar la potencia demandada por el inversor.
##
## @par 8. Bucle de simulación.
## Para cada muestra n se calcula: las moduladoras (mod_r,s,t), las señales
## PWM (Spx, Snx por comparación con v_tri), las corrientes de las ramas
## positiva y negativa de cada fase, las corrientes inyectadas a red
## (ir, is, it), la corriente total del bus Idc (suma de las ramas positivas),
## el sistema acoplado V0-Vpanel-Ipv mediante resolución cerrada con selección
## de tramo de la curva I-V, las corrientes del lado DC (ipv, idcin, icd) y
## se actualiza el índice de modulación cada Ncontrol muestras según
## M = 2·Vinvvac/V0.
##
## @section hipotesis Hipótesis del modelo
## - Sincronización ideal del inversor a la tensión de red (sin PLL real).
## - Operación en zona lineal de modulación (M ≤ 1). Cuando V0 cae por debajo
##   de 2·Vinvvac, M se satura y las corrientes reales dejan de coincidir con
##   las teóricas; este régimen no está aún modelado.
## - Tensión y frecuencia de red constantes y equilibradas. La red es una
##   fuente de tensión ideal sin impedancia equivalente.
## - Paneles operando en condiciones STC constantes (Su = 1, T = 25 °C). No se
##   contempla variación de irradiancia ni temperatura durante la simulación.
## - Inversor ideal: sin pérdidas de conmutación, sin tiempo muerto, sin caída
##   en los semiconductores.
## - Se desprecia el rizado de la corriente AC debido al filtro Lac: las
##   corrientes inyectadas se calculan a partir de las consignas teóricas.
##
## @section salidas Variables de salida principales
## Lado DC:
## - vdc(n)   : tensión instantánea del bus DC (V).
## - idc(n)   : corriente instantánea del bus DC hacia el puente (A).
## - ipv(n)   : corriente entregada por el campo fotovoltaico (A).
## - idcin(n) : corriente que entra al bus a través de Rgen (A).
## - icd(n)   : corriente por el condensador del bus, icd = idcin - idc (A).
##
## Lado AC:
## - ir(n), is(n), it(n)    : corrientes inyectadas a red en las tres fases (A).
## - vacr(n), vacs(n), vact(n): tensiones de red de referencia (V).
##
## @section pendiente Funcionalidad pendiente de implementar
## - Generación del evento de caída súbita de campo fotovoltaico (modificación
##   dinámica de Vpv y/o Ipv durante la simulación).
## - Modelo de arco DC en el bus (vector iarcdc, ya pre-reservado).
## - Modelo de arco AC en la salida (vector iarcac, ya pre-reservado).
## - Detección y modelado del régimen de saturación de M (cuando V0 < 2·Vinvvac).
## - Cálculo de las tensiones de fase a la salida del inversor antes de Lac
##   (vrn, vsn, vtn, ya pre-reservadas).
## - Análisis post-simulación: detección de superación de umbrales (Vdcmax,
##   Idcmax, Vacmax, Iacmax) y temporización de los disparos de protección.
##
## @author Dr. Carlos Romero Pérez
## @date Creación: 25/04/2026
## @date Última modificación: 02/05/2026
##

##
## @par Variables principales del script
##
## @par Parámetros de simulación y temporización
## @var Fs        Frecuencia de muestreo de las señales analógicas (Hz).
## @var Fcontrol  Frecuencia portadora del PWM, igual a la frecuencia de la
##                triangular y a la cadencia de actualización del control (Hz).
## @var Ncontrol  Número de muestras entre actualizaciones de M, round(Fs/Fcontrol).
## @var fred      Frecuencia de la red eléctrica (Hz).
## @var wred      Pulsación de la red, 2·pi·fred (rad/s).
## @var N         Número total de muestras de la simulación.
## @var n         Índice temporal del bucle (t = (n-1)/Fs).
##
## @par Parámetros nominales del inversor y la red
## @var Snom      Potencia aparente nominal del inversor (VA).
## @var Vdcnom    Tensión nominal del bus DC (V).
## @var Idcnom    Corriente nominal del bus DC, Snom/Vdcnom (A).
## @var Vffrmsred Tensión RMS fase-fase de la red (V).
## @var Vfnrmsred Tensión RMS fase-neutro de la red (V).
## @var Lac       Inductancia del filtro de salida del inversor (H).
## @var Cdc       Capacidad del condensador del bus DC (F).
## @var Rgen      Resistencia serie equivalente entre paneles y bus DC (ohm).
## @var Rcorto    Resistencia de cortocircuito del bus (ohm).
##
## @par Umbrales de protección (al 120 % del nominal)
## @var Vdcmax    Umbral de sobretensión DC del equipo (V).
## @var Idcmax    Umbral de sobrecorriente DC del equipo (A).
## @var Vacmax    Umbral de sobretensión AC del equipo, en pico (V).
## @var Iacmax    Umbral de sobrecorriente AC del equipo, en pico (A).
##
## @par Modelo del campo fotovoltaico
## @var Iscpanel    Corriente de cortocircuito de un panel (A).
## @var Vocpanel    Tensión de circuito abierto de un panel (V).
## @var Vmpptpanel  Tensión del punto de máxima potencia de un panel (V).
## @var Impptpanel  Corriente del punto de máxima potencia de un panel (A).
## @var alfa_isc    Coeficiente de temperatura de Isc (no utilizado en el modelo lineal actual).
## @var beta_vosc   Coeficiente de temperatura de Voc (no utilizado en el modelo lineal actual).
## @var Ns          Número de células en serie por panel (información, no usado).
## @var Np          Número de ramas paralelo dentro del panel (información, no usado).
## @var Npanels     Número de paneles en serie por rama, round(Vdcnom/Vmpptpanel).
## @var Npanelp     Número de ramas paralelo del campo, round(Idcnom/Impptpanel).
## @var Su          Irradiancia normalizada (1 = STC). Constante en esta versión.
## @var T           Temperatura de célula (°C). Constante en esta versión.
##
## @par Consignas y punto de trabajo
## @var Plim     Consigna de límite de potencia activa, normalizada [0, 1].
## @var Qref     Consigna de potencia reactiva, normalizada y con signo.
## @var Sref     Consigna de potencia aparente, sqrt(Plim^2 + Qref^2).
## @var Vpv      Tensión del campo fotovoltaico en el punto de trabajo (V).
## @var Ipv      Corriente del campo fotovoltaico en el punto de trabajo (A).
## @var Vdc      Tensión por panel en el punto de trabajo (V).
## @var Idcaux   Corriente por panel en el punto de trabajo (A).
## @var Pdcobj   Potencia objetivo por panel para la búsqueda iterativa (W).
## @var dVdc     Paso relativo de la búsqueda iterativa de Vdc.
## @var dPdcmin  Mínimo error de potencia encontrado durante la búsqueda (W).
## @var flag_Pdc Bandera de fin de la búsqueda iterativa de Vdc.
##
## @par Magnitudes de control AC
## @var Im       Amplitud de pico de la corriente de fase inyectada (A).
## @var phi      Desfase de la corriente respecto a la tensión de red (rad).
## @var Vinvvac  Amplitud de la tensión de fase a sintetizar antes del filtro Lac (V).
## @var M        Índice de modulación PWM, M = 2·Vinvvac/V0.
## @var control  Contador interno para disparar la actualización de M cada Ncontrol muestras.
##
## @par Coeficientes del filtro discreto del bus DC y del modelo de panel
## @var Kbus      Coeficiente de la regla del trapecio, 1/(2·Fs·Cdc).
## @var mL_panel  Pendiente del tramo izquierdo de la curva I-V del panel.
## @var bL_panel  Ordenada en el origen del tramo izquierdo de la curva I-V.
## @var mR_panel  Pendiente del tramo derecho de la curva I-V del panel.
## @var bR_panel  Ordenada en el origen del tramo derecho de la curva I-V.
## @var V0        Tensión instantánea del bus DC, valor actual del filtro (V).
## @var Vpanel    Tensión instantánea por panel resultante del balance (V).
## @var Ipv_actual Corriente instantánea total del campo PV (A).
## @var V0z1      Retardo z^-1 de V0 (V).
## @var Ipvz1     Retardo z^-1 de Ipv (A).
## @var Idcz1     Retardo z^-1 de Idc (A).
##
## @par Señales generadas pre-bucle
## @var v_tri  Señal triangular portadora del PWM, normalizada en [-1, 1].
## @var vacr, vacs, vact  Tensiones de red de las tres fases (V).
##
## @par Señales internas del bucle (calculadas muestra a muestra)
## @var mod_r, mod_s, mod_t      Señales moduladoras de las tres fases.
## @var Spr, Sps, Spt            Estados PWM de la rama positiva.
## @var Snr, Sns, Snt            Estados PWM de la rama negativa.
## @var idcpr, idcps, idcpt      Corrientes en la rama positiva de cada fase (A).
## @var idcnr, idcns, idcnt      Corrientes en la rama negativa de cada fase (A).
## @var idcr, idcs, idct         Corriente total por fase (suma rama positiva + negativa).
## @var Idc                      Corriente instantánea total que entra al puente (A).
##
## @par Señales de salida (vectores de longitud N)
## @var vdc    Tensión instantánea del bus DC (V).
## @var idc    Corriente instantánea del bus DC hacia el puente (A).
## @var ipv    Corriente entregada por el campo fotovoltaico (A).
## @var idcin  Corriente instantánea que entra al bus a través de Rgen (A).
## @var icd    Corriente por el condensador del bus, idcin - idc (A).
## @var ir, is, it  Corrientes inyectadas a la red en cada fase (A).
## @var iarcdc Corriente de arco DC (reservado, no usado todavía).
## @var iarcac Corriente de arco AC (reservado, no usado todavía).
## @var vrn, vsn, vtn  Tensiones de fase a la salida del inversor (reservado, no usado todavía).
##

# Inicialización de variables de entorno
Fs=49000 ;                        % Frecuencia de muestreo de las señales analógicas en Hz
Fcontrol=2450;                    % Frecuencia de control
fred=50;                          % Frecuencia de la red eléctrica en Hz
wred=2*pi*fred;
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
  Qref=sign(Qref)*sqrt(1-Plim^2);
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

% Filtro V0=f(Ipv,Idc,Cdc) - Regla del trapecio (bilineal de un integrador)
% Ecuación: Cdc·dV0/dt = Ipv - Idc
% V0(n) = V0(n-1) + Kbus·[(Ipv(n)-Idc(n)) + (Ipv(n-1)-Idc(n-1))]
Kbus=1/(2*Fs*Cdc);

% Coeficientes precalculados de la curva I-V del panel (lineal por tramos)
% Tramo izquierdo (Vpanel en [0, Vmpptpanel]):
%   Ipanel = mL·Vpanel + bL
mL_panel=(Impptpanel-Iscpanel)/Vmpptpanel;
bL_panel=Iscpanel;
% Tramo derecho (Vpanel en [Vmpptpanel, Vocpanel]):
%   Ipanel = mR·Vpanel + bR
mR_panel=Impptpanel/(Vmpptpanel-Vocpanel);
bR_panel=Impptpanel-mR_panel*Vmpptpanel;


% Simulador
n=1;                  % Índice temporal (t=n/Fs)
flag_Pdc=0;           % Se usa en el cálculo de Vdc de trabajo
dVdc=0.001;           % Intervalo de búsqueda de Vdc
dPdcmin=100;          % Valor inicial alto para primer punto de búsqueda
Ncontrol=round(Fs/Fcontrol);
control=0;            % Contador para lanzar el control

% Condiciones ambientales
Su=1;
T=25;

% Formas de onda
vacr=[];               % Forma de onda teórica de la tensión de salida R
vacs=[];               % Forma de onda teórica de la tensión de salida S
vact=[];               % Forma de onda teórica de la tensión de salida T

vrn=[];                 % Tensión fase r de salida del inversor
vsn=[];                 % Tensión fase s de salida del inversor
vtn=[];                 % Tensión fase t de salida del inversor

ipv=[];                 % Corriente de salida de paneles
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
  Pdcobj=Plim*Snom/(Npanels*Npanelp);     % Potencia objetivo por panel individual

  while (flag_Pdc==0)
    % Usamos la función Idc_Panel_Modelo para calcular la corriente del panel para
    % cada uno de los valores de Vdc que vamos a analizar.
    % Vdc tomará valores en el intervalo [Vmpptpanel Vocpanel], recorriéndolo
    % en sentido creciente. Deben ser incrementos pequeños, ya que la curva
    % decrece a 0 muy rápidamente
    Vdc=Vdc*(1+dVdc);
    if (Vdc>=Vocpanel)
      Vdc=Vocpanel;
      flag_Pdc=1;             % Alcanzada la tensión de circuito abierto del panel
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
Ipv=Idcaux*Npanelp;

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


% Cálculo para inicialización de la simulación
M=2*Vinvvac/Vpv;

% Inicialización del filtro V0 y de los retardos.
%
% En régimen permanente, el balance de corrientes en el bus es Ipv = Idc
% (el condensador no se carga ni descarga). La tensión del bus en ese punto
% cumple Vpanel·Npanels = V0 + Ipv·Rgen, con Vpanel·Npanels = Vpv calculado
% antes del bucle.
Idc=Ipv;
V0=Vpv-Ipv*Rgen;          % Tensión inicial del bus DC
V0z1=V0;
Ipvz1=Ipv;
Idcz1=Idc;



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

  % Corrientes reales inyectadas en la red.
  %
  % Mientras el inversor opere en zona lineal de modulación (M<=1), el control
  % mantiene Vinvvac constante ajustando M = 2·Vinvvac/V0 en cada ciclo, y la
  % corriente inyectada coincide con la teórica de amplitud Im y desfase phi.
  % El cálculo se hace muestra a muestra para poder extender el modelo cuando
  % se introduzcan eventos (caída del bus DC, faltas AC) que rompan esa
  % condición.
  ir(n)=Im*cos(wred*(n-1)/Fs+phi);
  is(n)=Im*cos(wred*(n-1)/Fs+phi-2*pi/3);
  it(n)=Im*cos(wred*(n-1)/Fs+phi+2*pi/3);

  % Solo sumamos las positivas. Las negativas son iguales pero de sentido contrario
  %
  Idc=idcpr+idcps+idcpt;
  idc(n)=Idc;

  % Cálculo acoplado de V0(n), Vpanel(n), Ipanel(n) e Ipv(n).
  %
  % El sistema acopla tres ecuaciones en el instante n:
  %
  %   1) Regla del trapecio sobre Cdc·dV0/dt = Ipv - Idc:
  %      V0(n) = V0(n-1) + Kbus·[Ipv(n) - Idc(n) + Ipv(n-1) - Idc(n-1)]
  %
  %   2) Balance de tensiones en la malla campo-Rgen-bus:
  %      Vpanel(n)·Npanels = V0(n) + Ipv(n)·Rgen
  %
  %   3) Curva I-V del panel (lineal por tramos):
  %      Ipanel(n) = m·Vpanel(n) + b   (pendiente m y ordenada b según tramo)
  %      Ipv(n)    = Ipanel(n)·Npanelp
  %
  % Combinando las tres ecuaciones se obtiene una expresión cerrada para
  % Ipv(n). Llamando H = V0z1 + Kbus·(Ipvz1 - Idcz1 - Idc(n)) y
  % alpha = Npanelp·m/Npanels, beta = Npanelp·b, queda:
  %
  %   Ipv(n) = (alpha·H + beta) / [1 - alpha·(Kbus + Rgen)]
  %
  % La selección de tramo se hace probando primero el tramo derecho (que es
  % el habitual en operación normal con Plim<=1). Si el Vpanel resultante
  % cae por debajo de Vmpptpanel, se recalcula con el tramo izquierdo.

  H = V0z1 + Kbus*(Ipvz1 - Idcz1 - Idc);

  % Tramo derecho: Vpanel en [Vmpptpanel, Vocpanel]
  alpha = Npanelp*mR_panel/Npanels;
  beta  = Npanelp*bR_panel;
  Ipv_actual = (alpha*H + beta) / (1 - alpha*(Kbus + Rgen));
  V0 = H + Kbus*Ipv_actual;
  Vpanel = (V0 + Ipv_actual*Rgen)/Npanels;

  if (Vpanel < Vmpptpanel)
    % Tramo izquierdo: Vpanel en [0, Vmpptpanel]
    alpha = Npanelp*mL_panel/Npanels;
    beta  = Npanelp*bL_panel;
    Ipv_actual = (alpha*H + beta) / (1 - alpha*(Kbus + Rgen));
    V0 = H + Kbus*Ipv_actual;
    Vpanel = (V0 + Ipv_actual*Rgen)/Npanels;
  endif

  vdc(n)=V0;

  % Actualización de los retardos de los filtros
  V0z1=V0;
  Ipvz1=Ipv_actual;
  Idcz1=Idc;

  % Almacenamiento de las corrientes del lado DC
  %
  % ipv:   corriente entregada por el campo fotovoltaico, calculada a partir
  %        de la curva I-V evaluada en Vpanel(n).
  % idcin: corriente que entra al bus desde el campo. En este modelo, al estar
  %        Rgen en serie sin derivaciones intermedias, idcin = ipv.
  % icd:   corriente por el condensador del bus, por balance en el nodo:
  %        icd = idcin - Idc.
  ipv(n)=Ipv_actual;
  idcin(n)=Ipv_actual;
  icd(n)=Ipv_actual-Idc;

  % Cálculo del nuevo índice de modulación cada Ncontrol muestras
  control=control+1;
  if (control>=Ncontrol)
    control=0;
    M=2*Vinvvac/V0;
  endif

  % Cálculo de la corriente de paneles


  n=n+1;

endwhile

