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
## obtiene la amplitud de la tensión que debe sintetizar el inversor antes
## del filtro, Vinvvac, y su desfase delta respecto a la tensión de red.
## El índice de modulación es M = 2·Vinvvac/V0.
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
## Para cada muestra n se calcula: las moduladoras (mod_r,s,t) con desfase
## delta, las señales PWM (Spx, Snx por comparación con v_tri), las tensiones
## instantáneas sintetizadas por cada fase del inversor (vinv_x = (Spx-Snx)·V0/2),
## la tensión efectiva sobre Lac en cada fase (con corrección homopolar para
## sistema sin neutro), las corrientes reales inyectadas a red (ir, is, it)
## mediante la regla del trapecio sobre Lac·di/dt + RLac·i = vLx, las corrientes
## del bus DC ponderadas por el PWM con las corrientes reales (idcpx = Spx·ix),
## la corriente total del bus Idc, el sistema acoplado V0-Vpanel-Ipv mediante
## resolución cerrada con selección de tramo de la curva I-V, las corrientes
## del lado DC (ipv, idcin, icd) y, cada Ncontrol muestras, se actualizan
## delta (mediante feed-forward de potencia + PI sobre V0 con anti-windup) y
## M = 2·Vinvvac/V0 (saturado a Mmax).
##
## @section hipotesis Hipótesis del modelo
## - Sincronización ideal del inversor a la tensión de red (sin PLL real).
## - Operación en zona lineal de modulación (M ≤ Mmax). Cuando M se satura,
##   las corrientes reales calculadas dinámicamente reflejan el comportamiento
##   del filtro Lac frente a la tensión sintetizada saturada y la red.
## - Tensión y frecuencia de red constantes y equilibradas. La red es una
##   fuente de tensión ideal sin impedancia equivalente.
## - Sistema sin hilo de neutro: las corrientes cumplen ir+is+it=0 mediante
##   la corrección homopolar vNN = (vinv_r+vinv_s+vinv_t)/3.
## - Filtro de salida con bobina Lac y resistencia parásita serie RLac, que
##   amortigua el modo resonante LC formado con Cdc.
## - Control de bus DC mediante feed-forward de potencia + PI que ajusta
##   delta para regular V0 a la consigna V0_ref = Vpv. El feed-forward
##   calcula delta_ff = asin(2·wred·Lac·(P_pv - P_RLac) / (3·Vfn_pico·Vinvvac))
##   para inyectar a la red exactamente la potencia que dan los paneles
##   menos las pérdidas óhmicas reales en la bobina del filtro (estimadas
##   con las corrientes instantáneas ir, is, it). El PI corrige pequeñas
##   desviaciones. El control corre a Fcontrol = 2.45 kHz, con frecuencia
##   de corte del lazo cerrado de 1 Hz, y delta saturado en ±π/4 con
##   anti-windup por congelación del integrador.
## - Paneles operando en condiciones STC constantes (Su = 1, T = 25 °C). No se
##   contempla variación de irradiancia ni temperatura durante la simulación.
## - Inversor ideal: sin pérdidas de conmutación, sin tiempo muerto, sin caída
##   en los semiconductores.
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
## - Cálculo de las tensiones de fase a la salida del inversor antes de Lac
##   (vrn, vsn, vtn, ya pre-reservadas).
## - Análisis post-simulación: detección de superación de umbrales (Vdcmax,
##   Idcmax, Vacmax, Iacmax) y temporización de los disparos de protección.
##
## @author Dr. Carlos Romero Pérez
## @date Creación: 25/04/2026
## @date Última modificación: 20/05/2026
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
## @var Lac       Inductancia del filtro inductivo de salida del inversor (H).
## @var RLac      Resistencia parásita serie de Lac (ohm).
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
## @var delta    Desfase de la tensión sintetizada por el inversor respecto a la red (rad).
## @var delta_inicial  Valor inicial de delta (resultado del balance fasorial).
## @var M        Índice de modulación PWM, M = 2·Vinvvac/V0.
## @var Mmax     Índice de modulación máximo permitido (sobremodulación).
## @var control  Contador interno para disparar la actualización de M cada Ncontrol muestras.
##
## @par Control PI del bus DC
## @var V0_ref     Consigna de tensión del bus DC para el PI (V).
## @var Ts_ctrl    Periodo de muestreo del control, Ncontrol/Fs (s).
## @var fc_PI      Frecuencia de corte del lazo cerrado del PI (Hz).
## @var Kp_PI      Ganancia proporcional del PI (rad/V).
## @var Ki_PI      Ganancia integral del PI (rad/(V·s)).
## @var Kp_pot     Ganancia proporcional equivalente en potencia (W/V).
## @var dPac_ddelta  Sensibilidad potencia activa - delta (W/rad).
## @var delta_max  Saturación superior de delta (rad).
## @var delta_min  Saturación inferior de delta (rad).
## @var PI_int     Estado del integrador del PI (rad).
## @var err_V0     Error de tensión del bus, V0 - V0_ref (V).
## @var P_pv       Potencia DC instantánea de los paneles, V0·Ipv (W).
## @var P_RLac     Pérdidas óhmicas instantáneas en la bobina del filtro, RLac·(ir²+is²+it²) (W).
## @var P_ac_obj   Potencia activa objetivo a entregar a la red, P_pv - P_RLac (W).
## @var sin_arg    Argumento del asin para el feed-forward, saturado en [-1,1].
## @var delta_ff   Desfase de feed-forward para inyectar P_ac_obj (rad).
##
## @par Coeficientes del filtro discreto del bus DC y del modelo de panel
## @var Kbus      Coeficiente de la regla del trapecio del bus, 1/(2·Fs·Cdc).
## @var aLac      Coeficiente recursivo del filtro Lac (con RLac), (2·Fs·Lac-RLac)/(2·Fs·Lac+RLac).
## @var bLac      Coeficiente de entrada del filtro Lac, 1/(2·Fs·Lac+RLac).
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
## @var ir_act, is_act, it_act    Corrientes instantáneas que pasan por Lac en cada fase (A).
## @var irz1, isz1, itz1          Retardos z^-1 de las corrientes de fase (A).
## @var vinv_r, vinv_s, vinv_t    Tensiones sintetizadas por el inversor respecto al neutro DC (V).
## @var vNN_act                   Tensión entre el neutro DC y el neutro de red (V).
## @var vLr_act, vLs_act, vLt_act Tensiones efectivas sobre Lac en cada fase (V).
## @var vLrz1, vLsz1, vLtz1       Retardos z^-1 de las tensiones efectivas sobre Lac (V).
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
## @var ir, is, it  Corrientes medidas por los sensores AC en cada fase, después del filtro Lac (A).
## @var iarcdc Corriente de arco DC (A).
## @var iarcac Corriente de arco AC (A).
## @var vrn, vsn, vtn  Tensiones de fase a la salida del inversor (reservado, no usado todavía).
##

pkg load signal;

flag_tipo_arco= menu("CASO DE USO","DC","AC","ESTABLE","PREF VARIABLE","IM SÚBITA");

flag_tipo_arco=flag_tipo_arco-1;

% Inicialización de variables aleatorias
flag_aleatorio=0;                 % 0:No hay variables aleatorias 1: Hay aleatoriedad

# Inicialización de variables de entorno
Fs=49000 ;                        % Frecuencia de muestreo de las señales analógicas en Hz
Fcontrol=2450;                    % Frecuencia de control
fred=50;                          % Frecuencia de la red eléctrica en Hz
wred=2*pi*fred;
N=300000;                          % Número de muestras de la simulación
Vdcnom=1500;                      % Tensión nominal del bus DC en V
Vffrmsred=690;                    % Tensión RMS fase fase
Vfnrmsred=Vffrmsred/sqrt(3);      % Tensión RMS de red fase neutro
Snom=4.5e6;                       % Potencia aparente nominal del equipo
Lac=150e-6;                       % Inductancia del filtro inductivo de salida del inversor (H)
RLac=5e-3;                        % Resistencia parásita serie de la bobina Lac (ohm)
Cdc=53e-3;                        % Condensador del bus DC en F
Rcorto=0.001;                     % Resistencia de cortocircuito
Rgen=0.001;                       % Resistencia en serie de la fuente de corriente
Mmax=1.15;                        % Índice de modulación máximo (sobremodulación)
Tref=25;                          % Temperatura de referencia de los paneles

% Filtro LP para medidas de tensiones y corrientes
Fp=100;                          % Frecuencia de paso.
Rp=0.01;                          % Rizado en banda de paso
Rs=40;                            % Atenuación en banda de rechazo
Nel=2;                            % Orden de filtro elíptico

[B,A]=ellip(Nel,Rp,Rs,Fp*2/Fs);   % Coeficientes del filtro

% Filtro Vdc
vdcfz1=0;
vdcfz2=0;
vdcinz1=0;
vdcinz2=0;

% Filtro Idc
idcfz1=0;
idcfz2=0;
idcinz1=0;
idcinz2=0;

% Filtro Vr
vrfz1=0;
vrfz2=0;
vrinz1=0;
vrinz2=0;

% Filtro Vs
vsfz1=0;
vsfz2=0;
vsinz1=0;
vsinz2=0;

% Filtro Vt
vtfz1=0;
vtfz2=0;
vtinz1=0;
vtinz2=0;

% Filtro Ir
irfz1=0;
irfz2=0;
irinz1=0;
irinz2=0;

% Filtro Is
isfz1=0;
isfz2=0;
isinz1=0;
isinz2=0;

% Filtro It
itfz1=0;
itfz2=0;
itinz1=0;
itinz2=0;


# Consignas para casos de uso
Plim=1;
Qref=0;

# Control de S<=1
if ((Plim^2+Qref^2)>1)
  Qref=sign(Qref)*sqrt(1-Plim^2);
endif

# Este código define la irradiancia y la temperatura en la planta.
# Según se haya seleccionado usar o no aleatoriedad, se usa unos valores de
# irradiancia Su=1 y T=25ºC, o se escoge cierta aleatoriedad cada vez que se
# ejecuta el script

if (flag_aleatorio==0)
  % Condiciones ambientales
  Su=1;
  T=Tref;
  indarc=floor(N/2);    % El arco se inicia en la mitad de la simulación
  indeven=floor(N/2);   % Muestra en la que se produce el evento no arco
else
  Su=0.5+0.5*rand(1);    % Irradiancia por unidad S/Sref [0.5 - 1]
  T=Tref+15*(1-rand(1));   % Temperatura en ºC [25 - 40]
  indarc=floor(N/4+1/2*randn(1));   % El arco se inicia en algún punto [N/4 3N/4]
  indeven=floor(N/4+1/2*randn(1));  % El evento no arco se inicia en algún punto [N/4 3N/4]
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
Iscpanel_25=8.85;
Vocpanel_25=37.85;
alfa_isc=0.062;
beta_vosc=-0.33;
gamma_vosc=0.05;
epsilom_vosc=10e-5;
Vmpptpanel_25=30.12;
Impptpanel_25=8.3;
Rs=0.01;        % Resistencia serie de celda [ohms]
Npanels=round(Vdcnom/Vmpptpanel_25);
Npanelp=round(Idcnom/Impptpanel_25);

% Efecto de Su y T
Iscpanel=Iscpanel_25*Su*(1+alfa_isc*(T-Tref));
Vocpanel=(Vocpanel_25+beta_vosc*(T-Tref))*(1+gamma_vosc*log(Su+epsilom_vosc));
Impptpanel=Impptpanel_25*Su*(1+alfa_isc*(T-Tref));
Vmpptpanel=Vmpptpanel_25+beta_vosc*(T-Tref)+Rs*(Impptpanel_25-Impptpanel);;

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

% Formas de onda
vacr=[];               % Forma de onda teórica de la tensión de salida R
vacs=[];               % Forma de onda teórica de la tensión de salida S
vact=[];               % Forma de onda teórica de la tensión de salida T


ipv=[];                 % Corriente de salida de paneles
idc=[];                 % Corriente del bus DC
vdc=[];                 % Tensión del bus DC
idcin=[];               % Corriente de PV o Batería
icd=[];                 % Corriente por el condensador del bus

iarcdc=zeros(1,N);      % Corriente de arco DC
iarcac=zeros(1,N);      % Corriente de arco AC

% Formas de onda reales de Ir, Is, It (corrientes que pasan por Lac, medidas
% por los sensores AC en el embarrado, antes del disyuntor)
ir=[];
is=[];
it=[];

% Vectores de medida. Las usadas por el control y protecciones
vdcmed=[];
idcmed=[];
vrmed=[];
vsmed=[];
vtmed=[];
irmed=[];
ismed=[];
itmed=[];


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

% Reinicialización de los retardos de los filtros de medida en régimen
% permanente teórico. Esto evita un transitorio inicial del filtro elíptico
% (que tardaría unas decenas de muestras en estabilizarse desde 0).
%
% Vdc e Idc son DC nominalmente, así que todos los retardos se ponen al valor
% nominal. vacr/vacs/vact e ir/is/it son sinusoidales: ponemos los retardos a
% los valores teóricos en t = -1/Fs y t = -2/Fs (n-1 y n-2 respectivamente).

% Filtro Vdc (señal DC)
vdcfz1=Vpv; vdcfz2=Vpv; vdcinz1=Vpv; vdcinz2=Vpv;

% Filtro Idc (señal DC, valor inicial: Ipv en régimen permanente)
% Ipv inicial = (Vpv·Npanelp/Npanels) en MPPT, equivalente a Snom*Sref/Vpv
Ipv_init=Sref*Snom/Vpv;
idcfz1=Ipv_init; idcfz2=Ipv_init; idcinz1=Ipv_init; idcinz2=Ipv_init;

% Filtros Vac (tensiones de red sinusoidales con fase 0, -2π/3, +2π/3)
Vac_pico=Vfnrmsred*sqrt(2);
vrfz1=Vac_pico*cos(-wred/Fs);          vrfz2=Vac_pico*cos(-2*wred/Fs);
vrinz1=Vac_pico*cos(-wred/Fs);         vrinz2=Vac_pico*cos(-2*wred/Fs);
vsfz1=Vac_pico*cos(-wred/Fs-2*pi/3);   vsfz2=Vac_pico*cos(-2*wred/Fs-2*pi/3);
vsinz1=Vac_pico*cos(-wred/Fs-2*pi/3);  vsinz2=Vac_pico*cos(-2*wred/Fs-2*pi/3);
vtfz1=Vac_pico*cos(-wred/Fs+2*pi/3);   vtfz2=Vac_pico*cos(-2*wred/Fs+2*pi/3);
vtinz1=Vac_pico*cos(-wred/Fs+2*pi/3);  vtinz2=Vac_pico*cos(-2*wred/Fs+2*pi/3);

% Filtros Iac (corrientes sinusoidales con desfase phi respecto a vac)
irfz1=Im*cos(-wred/Fs+phi);            irfz2=Im*cos(-2*wred/Fs+phi);
irinz1=Im*cos(-wred/Fs+phi);           irinz2=Im*cos(-2*wred/Fs+phi);
isfz1=Im*cos(-wred/Fs+phi-2*pi/3);     isfz2=Im*cos(-2*wred/Fs+phi-2*pi/3);
isinz1=Im*cos(-wred/Fs+phi-2*pi/3);    isinz2=Im*cos(-2*wred/Fs+phi-2*pi/3);
itfz1=Im*cos(-wred/Fs+phi+2*pi/3);     itfz2=Im*cos(-2*wred/Fs+phi+2*pi/3);
itinz1=Im*cos(-wred/Fs+phi+2*pi/3);    itinz2=Im*cos(-2*wred/Fs+phi+2*pi/3);

% Cálculo de la tensión que debe sintetizar el inversor antes del filtro Lac.
%
% Por Kirchhoff fasorial sobre la rama serie RLac + j·wred·Lac (con la red
% a fase 0 como referencia, y la corriente Iac = Im·exp(j·phi) — phi
% positivo = capacitivo, corriente adelantada):
%
%   Vinv = Vred + (RLac + j·wred·Lac)·Iac
%        = Vfn_pico + (RLac + j·wred·Lac)·(Im·cos(phi) + j·Im·sin(phi))
%        = (Vfn_pico + RLac·Im·cos(phi) - wred·Lac·Im·sin(phi))
%          + j·(RLac·Im·sin(phi) + wred·Lac·Im·cos(phi))
%
% Vinvvac es el módulo de Vinv (amplitud de la tensión que el inversor debe
% sintetizar) y delta es su fase respecto a la tensión de red. El control
% del inversor utiliza ambas magnitudes: Vinvvac fija el índice de modulación
% M = 2·Vinvvac/V0, y delta fija el desfase de las moduladoras respecto a
% la tensión de red. delta_inicial se usa solo para inicializar delta antes
% del bucle; dentro del bucle, el control combina feed-forward con PI.

Vinv_re = Vfnrmsred*sqrt(2) + RLac*Im*cos(phi) - wred*Lac*Im*sin(phi);
Vinv_im = RLac*Im*sin(phi) + wred*Lac*Im*cos(phi);
Vinvvac = sqrt(Vinv_re^2 + Vinv_im^2);
delta_inicial = atan2(Vinv_im, Vinv_re);
delta = delta_inicial;

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

% Coeficientes del filtro discreto del inductor Lac (con RLac en serie).
% Ecuación: Lac·di/dt + RLac·i = vL  (vL = vinv_x - vacx, con corrección homopolar)
% Regla del trapecio (bilineal s = 2·Fs·(z-1)/(z+1)):
%   i(n) = aLac·i(n-1) + bLac·[vL(n) + vL(n-1)]
% La presencia de RLac amortigua el modo resonante LC formado por Lac y Cdc.
aLac=(2*Fs*Lac-RLac)/(2*Fs*Lac+RLac);
bLac=1/(2*Fs*Lac+RLac);

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

% Inicialización de las corrientes AC y de sus retardos en régimen permanente
% teórico. Esto evita un transitorio inicial grande del filtro Lac.
% La corriente teórica es ir(t) = Im·cos(wred·t + phi), e igual con desfases
% trifásicos en s y t.
ir_act=Im*cos(phi);
is_act=Im*cos(phi-2*pi/3);
it_act=Im*cos(phi+2*pi/3);
% Retardos: valor en t = -1/Fs
irz1=Im*cos(-wred/Fs+phi);
isz1=Im*cos(-wred/Fs+phi-2*pi/3);
itz1=Im*cos(-wred/Fs+phi+2*pi/3);

% Retardos de las tensiones del filtro (vinv_x - vacx con corrección homopolar)
% en t = -1/Fs. En régimen permanente Vinv tiene fase delta y módulo Vinvvac;
% Vred tiene fase 0 y módulo Vfn_pico. Inicializamos los retardos a la
% diferencia teórica en régimen permanente para arrancar limpio.
vLrz1=Vinvvac*cos(-wred/Fs+delta) - Vfnrmsred*sqrt(2)*cos(-wred/Fs);
vLsz1=Vinvvac*cos(-wred/Fs+delta-2*pi/3) - Vfnrmsred*sqrt(2)*cos(-wred/Fs-2*pi/3);
vLtz1=Vinvvac*cos(-wred/Fs+delta+2*pi/3) - Vfnrmsred*sqrt(2)*cos(-wred/Fs+2*pi/3);

% Control PI del bus DC.
%
% El lazo de tensión regula V0 al valor de consigna V0_ref = Vpv (punto de
% trabajo calculado antes del bucle). La salida del PI ajusta delta (desfase
% de la tensión sintetizada por el inversor respecto a la tensión de red),
% que controla la potencia activa entregada a la red:
%   - Si V0 > V0_ref: hay exceso de carga -> aumentar delta -> más potencia
%     activa entregada -> V0 baja.
%   - Si V0 < V0_ref: el bus se descarga -> reducir delta -> menos potencia
%     activa entregada -> V0 sube.
%
% Diseño del PI:
%   - Frecuencia de corte deseada del lazo cerrado: 10 Hz (suficientemente
%     lenta para no excitar el rizado a 100/300 Hz, suficientemente rápida
%     para amortiguar el modo LC a ~56 Hz).
%   - Cadencia de cálculo: cada Ncontrol muestras (Fcontrol = 2.45 kHz),
%     periodo Ts_ctrl = Ncontrol/Fs.
%   - Sensibilidad dPac/ddelta ≈ 3·Vfn_pico·Vinvvac / (2·wred·Lac).
V0_ref=Vpv;
Ts_ctrl=Ncontrol/Fs;
fc_PI=3;                                     % Frecuencia de corte del lazo cerrado (Hz)
Kp_pot=2*pi*fc_PI*Cdc*V0_ref;                % Ganancia equivalente en W/V
dPac_ddelta=3*Vfnrmsred*sqrt(2)*Vinvvac/(2*wred*Lac);   % W/rad
Kp_PI=Kp_pot/dPac_ddelta;                    % rad/V
Ki_PI=Kp_PI*2*pi*fc_PI/5;                    % rad/(V·s)
delta_max=pi/4;                              % Saturación superior de delta (rad)
delta_min=-pi/4;                             % Saturación inferior de delta (rad)
PI_int=0;                                    % Estado del integrador (rad)



while (n<=N)

  % Generamos la corriente de arco, según sea el tipo de arco seleccionado.
  %
  % Topología modelada:
  %   - Arco DC: arco entre el polo positivo del bus DC y un conductor con
  %     resistencia de carga (modelada dentro de Genera_Iarc_RT). La tensión
  %     aplicada al lazo es V0. La corriente del arco sale del polo positivo,
  %     descarga el bus DC, y se suma al balance del bus en idc.
  %   - Arco AC: arco entre la fase R y tierra, en el embarrado AC del
  %     inversor, después del filtro Lac y antes de los sensores de corriente
  %     y del disyuntor AC. La tensión aplicada al lazo es vacr(n). La
  %     corriente del arco se desvía del embarrado a tierra, restándose de
  %     la corriente del lado red en lo que mide el sensor: ir(n) = ir_Lac - Iarcac.
  if (n>=indarc)
    if (flag_tipo_arco==0)
      Iarcdc=Genera_Iarc_RT(V0,Fs);
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

  % Generación de las señales moduladoras.
  %
  % Las moduladoras llevan amplitud M (índice de modulación) y desfase delta
  % respecto a la tensión de red. delta es el adelanto angular de la tensión
  % sintetizada por el inversor respecto a la red, calculado a partir del
  % balance fasorial Vinv = Vred + j·wL·Iac.
  %
  % El control actualiza M cada Ncontrol muestras según M = 2·Vinvvac/V0,
  % saturándolo a Mmax (sobremodulación). delta se mantiene constante en
  % esta versión, ya que Plim, Qref y por tanto el balance fasorial no
  % varían durante la simulación.
  mod_r= M*cos(wred*(n-1)/Fs+delta);
  mod_s= M*cos(wred*(n-1)/Fs+delta-2*pi/3);
  mod_t= M*cos(wred*(n-1)/Fs+delta+2*pi/3);


  % Generación de las señales PWM de cada fase y rama (positiva y negativa)
  % por comparación de la moduladora con la triangular reescalada (modulación
  % level-shifted de tres niveles).

  Spr = (mod_r > 0) .* (mod_r >= (v_tri(n) + 1) / 2);
  Snr = (mod_r < 0) .* (mod_r <= (v_tri(n) - 1) / 2);

  Sps = (mod_s > 0) .* (mod_s >= (v_tri(n) + 1) / 2);
  Sns = (mod_s < 0) .* (mod_s <= (v_tri(n) - 1) / 2);

  Spt = (mod_t > 0) .* (mod_t >= (v_tri(n) + 1) / 2);
  Snt = (mod_t < 0) .* (mod_t <= (v_tri(n) - 1) / 2);

  % Tensiones instantáneas sintetizadas por el inversor (respecto al neutro
  % del bus DC). En un puente NPC de tres niveles:
  %   - (Spx-Snx)=+1 → +V0/2  (rama positiva conduce)
  %   - (Spx-Snx)= 0 →   0     (estado de clamp al neutro)
  %   - (Spx-Snx)=-1 → -V0/2  (rama negativa conduce)
  % Se usa V0z1 (V0 de la muestra anterior) por simplicidad: el retraso de
  % una muestra a 49 kHz es despreciable frente a la dinámica del bus.
  vinv_r=(Spr-Snr)*V0z1/2;
  vinv_s=(Sps-Sns)*V0z1/2;
  vinv_t=(Spt-Snt)*V0z1/2;

  % Cálculo de las corrientes reales que pasan por el filtro Lac mediante
  % la dinámica del filtro inductivo, con corrección homopolar.
  %
  % En un sistema sin hilo de neutro, las corrientes deben cumplir
  % ir+is+it=0. La tensión efectiva sobre Lac en cada fase es:
  %   vLx = vinv_x - vacx - vNN
  % donde vNN es la tensión entre el neutro del bus DC y el neutro de red,
  % impuesta por la condición de no-corriente-homopolar:
  %   vNN = (vinv_r + vinv_s + vinv_t)/3   (vacr+vacs+vact = 0)
  vNN_act=(vinv_r+vinv_s+vinv_t)/3;
  vLr_act=vinv_r-vacr(n)-vNN_act;
  vLs_act=vinv_s-vacs(n)-vNN_act;
  vLt_act=vinv_t-vact(n)-vNN_act;

  % Regla del trapecio sobre Lac·di/dt + RLac·i = vLx:
  %   ix(n) = aLac·ix(n-1) + bLac·[vLx(n) + vLx(n-1)]
  ir_act=aLac*irz1+bLac*(vLr_act+vLrz1);
  is_act=aLac*isz1+bLac*(vLs_act+vLsz1);
  it_act=aLac*itz1+bLac*(vLt_act+vLtz1);

  % Almacenamiento de las corrientes medidas por los sensores AC.
  % El sensor está en el embarrado AC, después del filtro Lac y antes del
  % disyuntor. En la fase R, si hay arco AC, parte de la corriente que
  % viene de Lac se desvía a tierra por el arco antes de llegar al sensor:
  %   i_sensor = i_Lac - i_arco
  % En las fases S y T no hay arco, así que i_sensor = i_Lac.
  ir(n)=ir_act-Iarcac;
  is(n)=is_act;
  it(n)=it_act;

  % Corrientes del bus DC: la contribución al bus es la corriente que pasa
  % por Lac (lado inversor), ponderada por la señal de la rama positiva del
  % PWM. Las ramas positivas vierten corriente al bus visto como Cdc
  % completo; las negativas solo afectan al desbalance interno entre C+ y C-.
  % El arco AC NO afecta a Idc, porque está después de Lac: la corriente
  % que sale del puente sigue siendo ir_act (lo que se va por el arco lo
  % aporta el inversor a través de Lac, no el bus DC directamente).
  % El arco DC sí descarga el bus directamente: se suma a Idc como corriente
  % adicional que sale del bus por un camino paralelo a tierra/conductor.
  idcpr=Spr*ir_act;
  idcnr=Snr*ir_act;
  idcr=idcpr+idcnr;

  idcps=Sps*is_act;
  idcns=Sns*is_act;
  idcs=idcps+idcns;

  idcpt=Spt*it_act;
  idcnt=Snt*it_act;
  idct=idcpt+idcnt;

  Idc=idcpr+idcps+idcpt+Iarcdc;
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
  irz1=ir_act;
  isz1=is_act;
  itz1=it_act;
  vLrz1=vLr_act;
  vLsz1=vLs_act;
  vLtz1=vLt_act;

  % Filtrado de la medida Vdc
  vdcmed(n)=V0*B(1)+vdcinz1 *B(2)+vdcinz2*B(3)-vdcfz1*A(2)-vdcfz2*A(3);
  vdcinz2=vdcinz1;
  vdcinz1=V0;
  vdcfz2=vdcfz1;
  vdcfz1=vdcmed(n);

  % Filtrado de medida Idc
  idcmed(n)=Idc*B(1)+idcinz1*B(2)+idcinz2*B(3)-idcfz1*A(2)-idcfz2*A(3);
  idcinz2=idcinz1;
  idcinz1=Idc;
  idcfz2=idcfz1;
  idcfz1=idcmed(n);

  % Filtrado de medidas Vac
  vrmed(n)=vacr(n)*B(1)+vrinz1*B(2)+vrinz2*B(3)-vrfz1*A(2)-vrfz2*A(3);
  vrinz2=vrinz1;
  vrinz1=vacr(n);
  vrfz2=vrfz1;
  vrfz1=vrmed(n);

  vsmed(n)=vacs(n)*B(1)+vsinz1*B(2)+vsinz2*B(3)-vsfz1*A(2)-vsfz2*A(3);
  vsinz2=vsinz1;
  vsinz1=vacs(n);
  vsfz2=vsfz1;
  vsfz1=vsmed(n);

  vtmed(n)=vact(n)*B(1)+vtinz1*B(2)+vtinz2*B(3)-vtfz1*A(2)-vtfz2*A(3);
  vtinz2=vtinz1;
  vtinz1=vact(n);
  vtfz2=vtfz1;
  vtfz1=vtmed(n);

  % Filtrado de medidas Iac
  irmed(n)=ir(n)*B(1)+irinz1*B(2)+irinz2*B(3)-irfz1*A(2)-irfz2*A(3);
  irinz2=irinz1;
  irinz1=ir(n);
  irfz2=irfz1;
  irfz1=irmed(n);

  ismed(n)=is(n)*B(1)+isinz1*B(2)+isinz2*B(3)-isfz1*A(2)-isfz2*A(3);
  isinz2=isinz1;
  isinz1=is(n);
  isfz2=isfz1;
  isfz1=ismed(n);

  itmed(n)=it(n)*B(1)+itinz1*B(2)+itinz2*B(3)-itfz1*A(2)-itfz2*A(3);
  itinz2=itinz1;
  itinz1=it(n);
  itfz2=itfz1;
  itfz1=itmed(n);



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

  % Actualización del control cada Ncontrol muestras.
  %
  % 1) Feed-forward de potencia: el delta requerido para inyectar la potencia
  %    que están entregando los paneles (P_pv = V0·Ipv) se calcula de forma
  %    explícita a partir del balance fasorial. Esto elimina la necesidad de
  %    que el PI descubra el balance a través de la deriva de V0, y permite
  %    un arranque limpio y una respuesta inmediata a caídas de campo.
  %
  %    Fórmula: Pac ≈ (3·Vfn_pico·Vinvvac / (2·wred·Lac))·sin(delta_ff)
  %    => sin(delta_ff) = 2·wred·Lac·Pac / (3·Vfn_pico·Vinvvac)
  %    Se satura el argumento a [-1, 1] por seguridad numérica.
  %
  % 2) PI sobre V0: ajusta delta como corrección sobre el feed-forward para
  %    regular V0 al valor de consigna V0_ref. El integrador se congela cuando
  %    delta está saturado (anti-windup).
  %
  % 3) Índice de modulación M = 2·Vinvvac/V0, saturado a Mmax (sobremodulación).
  %    Si V0 cae por debajo de 2·Vinvvac/Mmax, el inversor satura.
  control=control+1;
  if (control>=Ncontrol)
    control=0;

    % Feed-forward: delta requerido para entregar la potencia neta que sale
    % del puente, descontando las pérdidas en la bobina del filtro.
    %
    % Balance de potencia (régimen permanente):
    %   P_pv (del bus DC) = P_ac_red (a la red) + P_RLac (pérdidas en Lac)
    %
    % donde:
    %   P_pv      = V0·Ipv (potencia que aportan los paneles al bus)
    %   P_RLac    = (3/2)·RLac·Im² = RLac·(ir² + is² + it²) en valor
    %               instantáneo, equivalente a la media en régimen sinusoidal
    %   P_ac_red  = P_pv - P_RLac
    %
    % Se usan las corrientes instantáneas ir_act, is_act, it_act para estimar
    % las pérdidas sin asumir régimen permanente.
    P_pv=vdcmed(n)*idcmed(n);
    P_RLac=RLac*(irmed(n)^2+ismed(n)^2+itmed(n)^2);
    P_ac_obj=P_pv-P_RLac;
    sin_arg=2*wred*Lac*P_ac_obj/(3*Vfnrmsred*sqrt(2)*Vinvvac);
    if (sin_arg>1)
      sin_arg=1;
    elseif (sin_arg<-1)
      sin_arg=-1;
    endif
    delta_ff=asin(sin_arg);

    % PI sobre el bus DC: corrección sobre el feed-forward. err positivo si
    % V0 supera la consigna.
    err_V0=vdcmed(n)-V0_ref;
    delta_unsat=delta_ff+Kp_PI*err_V0+PI_int+Ki_PI*Ts_ctrl*err_V0;
    if (delta_unsat>delta_max)
      delta=delta_max;
    elseif (delta_unsat<delta_min)
      delta=delta_min;
    else
      delta=delta_unsat;
      PI_int=PI_int+Ki_PI*Ts_ctrl*err_V0;     % Integrador solo si no saturado
    endif

    % Índice de modulación
    M=2*Vinvvac/V0;
    if (M>Mmax)
      M=Mmax;
    endif
  endif

  % Cálculo de la corriente de paneles


  n=n+1;

endwhile

