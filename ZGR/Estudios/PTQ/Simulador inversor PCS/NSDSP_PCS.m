##
## @file NSDSP_PCS.m
## @brief Simulación de transitorios en PCS (Power Conversion System) de batería de 4.5 MVA.
##
## Este script simula el comportamiento dinámico de un inversor PCS (Power
## Conversion System) trifásico de 4.5 MVA conectado a red, asociado a una
## batería de 1500 V que puede operar tanto en descarga (potencia activa de
## inversor a red) como en carga (potencia activa de red a batería). La
## simulación trabaja muestra a muestra a 49 kHz, lo que permite reproducir
## tanto la dinámica del bus DC (oscilaciones a 100/300 Hz, transitorios de
## carga del condensador) como el rizado de conmutación debido al PWM a
## 2,45 kHz.
##
## @section arquitectura Arquitectura modelada
## El sistema se modela como una batería de tensión constante Vbat = 1500 V
## conectada al bus DC a través de una resistencia serie equivalente Rgen
## (cableado, contactos, ESR interna). El bus DC (condensador Cdc) alimenta
## un puente trifásico NPC de tres niveles. La salida del puente pasa por un
## filtro inductivo Lac que la conecta a la red trifásica de 690 V / 50 Hz.
## La red se considera una fuente de tensión ideal (sin impedancia
## equivalente), a la que el inversor se sincroniza.
##
## La batería se modela como una fuente de tensión ideal: siempre cargada,
## sin curva de descarga, sin limitación de corriente desde el modelo.
## Cualquier limitación física (corriente máxima del BMS, etc.) queda fuera
## del alcance de este simulador, salvo por el umbral de corriente inversa
## que sí está vigilado por la protección DC.
##
## @section bloques Bloques principales del script
## @par 1. Parámetros del equipo y red.
## Frecuencia de muestreo (Fs), frecuencia de control PWM (Fcontrol), red
## (fred, Vffrmsred), nominales del inversor (Snom, Vdcnom), filtro de salida
## (Lac, RLac), bus DC (Cdc), resistencias de modelo (Rgen, Rcorto), niveles
## máximos de protección al 120 % del nominal.
##
## @par 2. Consignas de potencia.
## El inversor recibe Plim (consigna de potencia activa, normalizada y con
## signo: positivo = descarga de batería hacia la red; negativo = carga de
## batería desde la red) y Qref (consigna de reactiva, normalizada). Se
## aplica una limitación que garantiza que la potencia aparente solicitada
## cumple S ≤ 1, ajustando Qref si es necesario.
##
## @par 3. Modelo de la batería.
## La batería se modela como una fuente de tensión ideal Vbat constante,
## en serie con la resistencia Rgen. La corriente que aporta al bus es
## Ipv = (Vbat - V0)/Rgen, donde V0 es la tensión instantánea del bus.
## Esta corriente puede ser positiva (descarga) o negativa (carga).
##
## @par 4. Cálculo de magnitudes teóricas.
## A partir de Plim y Qref se obtienen las consignas de corriente en
## coordenadas dq:
##   id_ref = (2/3)·Plim·Snom / Vfn_pico
##   iq_ref = (2/3)·Qref·Snom / Vfn_pico
## donde id es la componente en fase con la tensión de red (potencia activa)
## y iq la componente en cuadratura (potencia reactiva).
##
## @par 5. Generación de señales pre-bucle.
## Se generan vectorialmente la triangular v_tri (a Fcontrol, en fase con el
## reloj de muestreo) y las tensiones de red vacr, vacs, vact (sinusoides a
## fred, sincronizadas a v_tri). Estas señales son fijas durante toda la
## simulación.
##
## @par 6. Modelo dinámico del bus DC.
## El balance de corrientes en el nodo del bus es Cdc·dV0/dt = Ipv - Idc,
## con Ipv = (Vbat - V0)/Rgen.
##
## Sustituyendo y aplicando la transformación bilineal s = 2·Fs·(z-1)/(z+1)
## se obtiene la regla del trapecio en forma cerrada:
##   V0(n) = [V0(n-1)·(1 - Kbus/Rgen) + Kbus·(Vbat·2/Rgen - Idc(n) - Idc(n-1))
##            + Kbus·(Vbat - V0(n-1))/Rgen]
##           / (1 + Kbus/Rgen)
## con Kbus = 1/(2·Fs·Cdc). De manera equivalente, se resuelve el sistema
## acoplado V0-Ipv en forma cerrada en cada muestra.
##
## @par 7. Control vectorial dq.
## El control trabaja en coordenadas dq, con la tensión de red en eje d
## y la fase θ = wred·t obtenida de la sincronización ideal a la red
## (PLL ideal). El control tiene dos lazos PI independientes sobre id e iq,
## diseñados por cancelación de polo del filtro Lac+RLac, con frecuencia
## de corte fc_id = 300 Hz. Cada lazo incluye un término de feed-forward
## que añade la tensión de red en d (Vfn_pico) y el desacoplo cruzado d-q
## debido al filtro Lac:
##   vd_inv = vd_pi + Vfn_pico - wred·Lac·iqmed
##   vq_inv = vq_pi + wred·Lac·idmed
## La salida del control en dq se transforma de vuelta a abc mediante la
## Park inversa para generar las tensiones de referencia que el PWM debe
## sintetizar. Las moduladoras son mod_x = 2·vinv_ref_x / V0 saturadas a
## ±Mmax.
##
## @par 8. Bucle de simulación.
## Para cada muestra n se calcula: las señales PWM (Spx, Snx por comparación
## con v_tri), las tensiones instantáneas sintetizadas por cada fase
## (vinv_x = (Spx-Snx)·V0/2), la tensión efectiva sobre Lac en cada fase
## (con corrección homopolar para sistema sin neutro), las corrientes
## reales inyectadas a red (ir, is, it) mediante la regla del trapecio
## sobre Lac·di/dt + RLac·i = vLx, las corrientes del bus DC ponderadas
## por el PWM con las corrientes reales (idcpx = Spx·ix), la corriente
## total del bus Idc, el balance del bus V0-Ipv en forma cerrada, las
## corrientes del lado DC (ipv, idcin, icd) y, cada Ncontrol muestras,
## se actualizan las moduladoras a partir del control vectorial dq.
##
## @section hipotesis Hipótesis del modelo
## - Sincronización ideal del inversor a la tensión de red (sin PLL real).
##   La fase θ utilizada por las transformadas de Park se calcula
##   directamente como θ(n) = wred·(n-1)/Fs.
## - Batería como fuente de tensión ideal Vbat constante. No se modela la
##   dinámica de descarga ni la curva SOC-V.
## - Operación en zona lineal de modulación (|mod_x| ≤ Mmax). Cuando las
##   moduladoras saturan, se congela el integrador del lazo correspondiente
##   (anti-windup).
## - Tensión y frecuencia de red constantes y equilibradas. La red es una
##   fuente de tensión ideal sin impedancia equivalente.
## - Sistema sin hilo de neutro: las corrientes cumplen ir+is+it=0 mediante
##   la corrección homopolar vNN = (vinv_r+vinv_s+vinv_t)/3.
## - Filtro de salida con bobina Lac y resistencia parásita serie RLac, que
##   amortigua el modo resonante LC formado con Cdc.
## - Control vectorial dq con dos lazos PI independientes sobre id e iq,
##   diseñados por cancelación de polo: Kp = 2·π·fc_id·Lac y
##   Ki = 2·π·fc_id·RLac, con fc_id = 300 Hz. Cadencia del control:
##   Fcontrol = 2.45 kHz.
## - Inversor ideal: sin pérdidas de conmutación, sin tiempo muerto, sin
##   caída en los semiconductores.
##
## @section salidas Variables de salida principales
## Lado DC:
## - vdc(n)   : tensión instantánea del bus DC (V).
## - idc(n)   : corriente instantánea del bus DC hacia el puente (A).
## - ipv(n)   : corriente entregada por la batería al bus (A; positiva = descarga).
## - idcin(n) : corriente que entra al bus a través de Rgen (A).
## - icd(n)   : corriente por el condensador del bus, icd = idcin - idc (A).
##
## Lado AC:
## - ir(n), is(n), it(n)    : corrientes inyectadas a red en las tres fases (A).
## - vacr(n), vacs(n), vact(n): tensiones de red de referencia (V).
##
## @section pendiente Funcionalidad pendiente de implementar
## - Generación del evento de variación súbita de consigna Plim/Qref durante
##   la simulación.
## - Cálculo de las tensiones de fase a la salida del inversor antes de Lac
##   (vrn, vsn, vtn, ya pre-reservadas).
##
## @section protecciones Sistema de protecciones
## El inversor incluye protecciones por sobretensión y sobrecorriente DC y
## AC. En este caso, al ser una batería, sí es legítima la corriente inversa
## (modo carga), por lo que el umbral de corriente inversa se relaja al
## mismo valor que el umbral de sobrecorriente directa: Idc_inv_max =
## -Idcmax. El disparo se produce al cruzar uno cualquiera de los umbrales
## sobre las señales filtradas para protección (vdcprot, idcprot,
## irmed/ismed/itmed), registrando la muestra del disparo (n_trip) y el
## motivo (motivo_trip).
##
## Las señales del bus DC (vdc, idc) llevan un filtro adicional elíptico
## de orden 2 a Fmed=10 Hz, aplicado en cascada sobre el filtro de medida
## general a Fp=100 Hz. Este filtro adicional atenúa fuertemente (>40 dB) el
## rizado a 300 Hz típico del bus DC en un puente trifásico, evitando
## disparos espúrios. No se aplica a las corrientes AC (ir, is, it) porque
## un filtro a 10 Hz atenuaría también la fundamental a 50 Hz.
##
## Durante los primeros Tinhibicion_prot segundos desde el arranque las
## protecciones se inhiben para evitar disparos espúrios por el transitorio
## inicial del simulador (estabilización del filtro elíptico de medida y
## acomodación de las variables de estado).
##
## Tras el disparo se activan tres procesos en cascada:
##   1) Bloqueo de los IGBTs (Tbloqueo_igbts después del trip): se anulan
##      los PWM y los diodos de libre circulación rectifican pasivamente la
##      corriente residual del filtro Lac, devolviéndola al bus DC.
##   2) Apertura del disyuntor AC (Tabre_ac después del trip): las corrientes
##      del filtro se fuerzan a 0.
##   3) Apertura del disyuntor DC (Tabre_dc después del trip): la batería
##      se desconecta del bus, Ipv=0, y el bus queda con su dinámica natural
##      Cdc·dV0/dt = -Idc.
## Los tiempos de apertura son parametrizables (rangos min-max) y pueden
## tomarse aleatorios en cada simulación cuando flag_aleatorio=1. La
## simulación continúa hasta n=N tras el trip para registrar la dinámica
## post-disparo.
##
## @author Dr. Carlos Romero Pérez
## @date Creación: 31/05/2026
## @date Última modificación: 31/05/2026
##

##
## @par Variables principales del script
##
## @par Parámetros de simulación y temporización
## @var Fs        Frecuencia de muestreo de las señales analógicas (Hz).
## @var Fcontrol  Frecuencia portadora del PWM, igual a la frecuencia de la
##                triangular y a la cadencia de actualización del control (Hz).
## @var Ncontrol  Número de muestras entre actualizaciones del control, round(Fs/Fcontrol).
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
## @var Rgen      Resistencia serie equivalente entre batería y bus DC (ohm).
## @var Rcorto    Resistencia de cortocircuito del bus (ohm).
##
## @par Umbrales de protección (al 120 % del nominal salvo corriente inversa)
## @var Vdcmax    Umbral de sobretensión DC del equipo (V).
## @var Idcmax    Umbral de sobrecorriente DC del equipo (A).
## @var Idc_inv_max Umbral de corriente inversa DC, -Idcmax (A).
## @var Vacmax    Umbral de sobretensión AC del equipo, en pico (V).
## @var Iacmax    Umbral de sobrecorriente AC del equipo, en pico (A).
##
## @par Configuración del sistema de protecciones
## @var Tabre_dc_min  Tiempo mínimo de apertura del disyuntor DC (s).
## @var Tabre_dc_max  Tiempo máximo de apertura del disyuntor DC (s).
## @var Tabre_ac_min  Tiempo mínimo de apertura del disyuntor AC (s).
## @var Tabre_ac_max  Tiempo máximo de apertura del disyuntor AC (s).
## @var Tbloqueo_igbts  Tiempo entre la detección del trip y el bloqueo efectivo de los IGBTs (s).
## @var Tinhibicion_prot Tiempo de inhibición de protecciones al arranque de la simulación (s).
## @var Tabre_dc      Tiempo efectivo de apertura del disyuntor DC en esta simulación (s).
## @var Tabre_ac      Tiempo efectivo de apertura del disyuntor AC en esta simulación (s).
## @var Nabre_dc      Tiempo Tabre_dc convertido a número de muestras.
## @var Nabre_ac      Tiempo Tabre_ac convertido a número de muestras.
## @var Nbloqueo_igbts Tiempo Tbloqueo_igbts convertido a número de muestras.
## @var Ninhibicion_prot Tiempo Tinhibicion_prot convertido a número de muestras.
## @var n_trip        Muestra del disparo (0 si no hay disparo).
## @var motivo_trip   Motivo del trip: "DC_overv", "DC_overc", "DC_invc", "AC_overc" o "NONE".
## @var igbts_activos Estado actual de los IGBTs (1=activos, 0=bloqueados).
## @var disy_dc_cerrado Estado actual del disyuntor DC (1=cerrado, 0=abierto).
## @var disy_ac_cerrado Estado actual del disyuntor AC (1=cerrado, 0=abierto).
## @var igbts_activos_v Vector con el estado de los IGBTs por muestra.
## @var disy_dc_cerrado_v Vector con el estado del disyuntor DC por muestra.
## @var disy_ac_cerrado_v Vector con el estado del disyuntor AC por muestra.
##
## @par Modelo de la batería
## @var Vbat      Tensión de la batería en bornes (V).
##
## @par Consignas y punto de trabajo
## @var Plim     Consigna de potencia activa, normalizada y con signo [-1, 1].
##               Positivo = descarga (batería → red); negativo = carga (red → batería).
## @var Qref     Consigna de potencia reactiva, normalizada y con signo.
## @var Sref     Consigna de potencia aparente, sqrt(Plim^2 + Qref^2).
##
## @par Magnitudes de control AC en dq
## @var id_ref    Consigna de corriente activa (eje d), (2/3)·Plim·Snom/Vfn_pico (A).
## @var iq_ref    Consigna de corriente reactiva (eje q), (2/3)·Qref·Snom/Vfn_pico (A).
## @var theta     Fase de la tensión de red, wred·(n-1)/Fs (rad).
## @var idmed     Corriente activa medida en eje d (A).
## @var iqmed     Corriente reactiva medida en eje q (A).
## @var err_id    Error en eje d, id_ref - idmed (A).
## @var err_iq    Error en eje q, iq_ref - iqmed (A).
## @var vd_pi     Salida del PI en eje d (V).
## @var vq_pi     Salida del PI en eje q (V).
## @var vd_inv    Tensión de referencia en eje d, con feed-forward y desacoplo (V).
## @var vq_inv    Tensión de referencia en eje q, con feed-forward y desacoplo (V).
## @var vinv_ref_r, vinv_ref_s, vinv_ref_t   Tensiones de referencia abc para el PWM (V).
## @var Mmax     Índice de modulación máximo permitido (sobremodulación).
## @var control  Contador interno para disparar la actualización del control cada Ncontrol muestras.
##
## @par Diseño del control PI en dq (cancelación de polo Lac+RLac)
## @var Ts_ctrl   Periodo de muestreo del control, Ncontrol/Fs (s).
## @var fc_id     Frecuencia de corte del lazo cerrado de corriente (Hz).
## @var Kp_id     Ganancia proporcional del PI de corriente, 2·π·fc_id·Lac (V/A).
## @var Ki_id     Ganancia integral del PI de corriente, 2·π·fc_id·RLac (V/(A·s)).
## @var PI_int_d  Estado del integrador del PI en eje d (V).
## @var PI_int_q  Estado del integrador del PI en eje q (V).
##
## @par Coeficientes del filtro discreto del bus DC
## @var Kbus      Coeficiente de la regla del trapecio del bus, 1/(2·Fs·Cdc).
## @var aLac      Coeficiente recursivo del filtro Lac (con RLac), (2·Fs·Lac-RLac)/(2·Fs·Lac+RLac).
## @var bLac      Coeficiente de entrada del filtro Lac, 1/(2·Fs·Lac+RLac).
## @var V0        Tensión instantánea del bus DC, valor actual (V).
## @var Ipv_actual Corriente instantánea que entrega la batería al bus (A).
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
## @var ipv    Corriente entregada por la batería al bus (A).
## @var idcin  Corriente instantánea que entra al bus a través de Rgen (A).
## @var icd    Corriente por el condensador del bus, idcin - idc (A).
## @var ir, is, it  Corrientes medidas por los sensores AC en cada fase, después del filtro Lac (A).
## @var iarcdc Corriente de arco DC (A).
## @var iarcac Corriente de arco AC (A).
## @var vrn, vsn, vtn  Tensiones de fase a la salida del inversor (reservado, no usado todavía).
##

pkg load signal;

flag_tipo_arco= menu("CASO DE USO","DC","AC","ESTABLE");

flag_tipo_arco=flag_tipo_arco-1;

% Inicialización de variables aleatorias
flag_aleatorio=0;                 % 0:No hay variables aleatorias 1: Hay aleatoriedad

# Inicialización de variables de entorno
Fs=49000 ;                        % Frecuencia de muestreo de las señales analógicas en Hz
Fcontrol=2450;                    % Frecuencia de control
fred=50;                          % Frecuencia de la red eléctrica en Hz
wred=2*pi*fred;
N=150000;                          % Número de muestras de la simulación
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

% Filtro LP para medidas de tensiones y corrientes
Fp=100;                          % Frecuencia de paso.
Rp=0.01;                          % Rizado en banda de paso
Rs=40;                            % Atenuación en banda de rechazo
Nel=2;                            % Orden de filtro elíptico

[B,A]=ellip(Nel,Rp,Rs,Fp*2/Fs);   % Coeficientes del filtro

% Filtro LP adicional para las medidas DC que usan las protecciones. Se aplica
% en cascada sobre la salida del filtro anterior (vdcmed, idcmed). Frecuencia
% de paso muy baja (10 Hz) para atenuar fuertemente (>40 dB) el rizado a
% 300 Hz típico del bus DC en un puente trifásico, y evitar disparos espúrios
% por rizado. NO se aplica a las corrientes AC (irmed, ismed, itmed), que
% se vigilan directamente sobre el filtro de medida principal, porque un
% filtro a 10 Hz atenuaría también la componente fundamental a 50 Hz.
Fmed=10;                          % Frecuencia de paso del filtro de protecciones (Hz)
Rpmed=0.01;                       % Rizado en banda de paso
Rsmed=20;                         % Atenuación en banda de rechazo (dB)
Nmed=2;                           % Orden del filtro elíptico

[Bmed,Amed]=ellip(Nmed,Rpmed,Rsmed,Fmed*2/Fs);

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

% Retardos del filtro adicional para protecciones, aplicado en cascada
% sobre vdcmed e idcmed. Se inicializan a 0 aquí y se reinicializan luego
% en régimen permanente.
vdcprot_fz1=0; vdcprot_fz2=0; vdcprot_inz1=0; vdcprot_inz2=0;
idcprot_fz1=0; idcprot_fz2=0; idcprot_inz1=0; idcprot_inz2=0;

% Retardos del filtro paso-bajo sobre las componentes dq (predeclaración).
% Se reinicializan después en régimen permanente.
idmedfz1=0; idmedfz2=0; idmedinz1=0; idmedinz2=0;
iqmedfz1=0; iqmedfz2=0; iqmedinz1=0; iqmedinz2=0;


# Consignas para casos de uso
Plim=1;
Qref=0;

# Control de S<=1
if ((Plim^2+Qref^2)>1)
  Qref=sign(Qref)*sqrt(1-Plim^2);
endif

# Definición del instante del evento (inicio del arco o de la perturbación).
# Con flag_aleatorio=0 se fija en N/2. Con flag_aleatorio=1 se toma aleatorio
# dentro del primer cuarto de la simulación.

if (flag_aleatorio==0)
  indarc=floor(N/2);    % El arco se inicia en la mitad de la simulación
  indeven=floor(N/2);   % Muestra en la que se produce el evento no arco
else
  indarc=floor(N/4+1/2*randn(1));   % El arco se inicia en algún punto [N/4 3N/4]
  indeven=floor(N/4+1/2*randn(1));  % El evento no arco se inicia en algún punto [N/4 3N/4]
endif


%Niveles máximos eléctricos del equipo
Idcnom=Snom/Vdcnom;
Vdcmax=Vdcnom*1.2;                % Umbral de sobretensión DC del equipo
Idcmax=Snom/Vdcnom*1.2;           % Umbral de sobrecorriente DC del equipo
Idc_inv_max=-Idcmax;              % Umbral de corriente inversa DC. En batería el modo carga (Idc<0) es legítimo, hasta -Idcmax.

Iacmax=2*(Snom/3)/(Vfnrmsred*sqrt(2))*1.2;    % Umbral de sobrecorriente AC del equipo
Vacmax=Vfnrmsred*sqrt(2)*1.2;                 % Umbral de sobretensión AC del equipo

% Configuración del sistema de protecciones.
%
% Tiempos de apertura de disyuntores (mecánicos, en segundos). Si
% flag_aleatorio==1, se toma un valor aleatorio entre min y max; si no,
% se usa el valor min.
Tabre_dc_min=30e-3;               % Tiempo mínimo de apertura disyuntor DC (s)
Tabre_dc_max=80e-3;               % Tiempo máximo de apertura disyuntor DC (s)
Tabre_ac_min=20e-3;               % Tiempo mínimo de apertura disyuntor AC (s)
Tabre_ac_max=60e-3;               % Tiempo máximo de apertura disyuntor AC (s)
Tbloqueo_igbts=1e-6;              % Tiempo de bloqueo de IGBTs tras detección del trip (s)
Tinhibicion_prot=50e-3;           % Tiempo de inhibición de protecciones al arranque (s)

if (flag_aleatorio==0)
  Tabre_dc=Tabre_dc_min;
  Tabre_ac=Tabre_ac_min;
else
  Tabre_dc=Tabre_dc_min+(Tabre_dc_max-Tabre_dc_min)*rand(1);
  Tabre_ac=Tabre_ac_min+(Tabre_ac_max-Tabre_ac_min)*rand(1);
endif

% Pasar tiempos a número de muestras
Nabre_dc=round(Tabre_dc*Fs);
Nabre_ac=round(Tabre_ac*Fs);
Nbloqueo_igbts=max(1,round(Tbloqueo_igbts*Fs));
Ninhibicion_prot=round(Tinhibicion_prot*Fs);

% Estado del sistema de protecciones (variables de estado)
n_trip=0;                         % Muestra del disparo (0 = no hay disparo todavía)
motivo_trip="NONE";               % Motivo del disparo (cadena)
igbts_activos=1;                  % 1=IGBTs operativos, 0=bloqueados
disy_dc_cerrado=1;                % 1=disyuntor DC cerrado, 0=abierto
disy_ac_cerrado=1;                % 1=disyuntor AC cerrado, 0=abierto

% Modelo de la batería
Vbat=1500;                        % Tensión de batería en bornes (V), constante

% Filtro V0=f(Ipv,Idc,Cdc) - Regla del trapecio (bilineal de un integrador)
% Ecuación: Cdc·dV0/dt = Ipv - Idc, con Ipv = (Vbat - V0)/Rgen
% V0(n) = V0(n-1) + Kbus·[(Ipv(n)-Idc(n)) + (Ipv(n-1)-Idc(n-1))]
Kbus=1/(2*Fs*Cdc);


% Simulador
n=1;                  % Índice temporal (t=n/Fs)
Ncontrol=round(Fs/Fcontrol);
control=0;            % Contador para lanzar el control

% Formas de onda
vacr=[];               % Forma de onda teórica de la tensión de salida R
vacs=[];               % Forma de onda teórica de la tensión de salida S
vact=[];               % Forma de onda teórica de la tensión de salida T


ipv=[];                 % Corriente entregada por la batería al bus
idc=[];                 % Corriente del bus DC
vdc=[];                 % Tensión del bus DC
idcin=[];               % Corriente de PV o Batería
icd=[];                 % Corriente por el condensador del bus

iarcdc=zeros(1,N);      % Corriente de arco DC
iarcac=zeros(1,N);      % Corriente de arco AC

% Vectores de estado de las protecciones (0/1 por muestra)
igbts_activos_v=ones(1,N);     % 1=IGBTs operativos, 0=bloqueados
disy_dc_cerrado_v=ones(1,N);   % 1=disyuntor DC cerrado, 0=abierto
disy_ac_cerrado_v=ones(1,N);   % 1=disyuntor AC cerrado, 0=abierto

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

% Vectores de medida adicional (filtro DC en cascada) que usan las
% protecciones para evitar disparos espúrios por el rizado a 300 Hz del bus.
vdcprot=[];
idcprot=[];


% Generamos las tensiones AC.
%
% La tensión de red no la podemos modificar desde el inversor. Nos sincronizamos
% a ella.
%
q=1:N;
vacr(q)=Vfnrmsred*sqrt(2)*cos(wred*(q-1)/Fs);
vacs(q)=Vfnrmsred*sqrt(2)*cos(wred*(q-1)/Fs-2*pi/3);
vact(q)=Vfnrmsred*sqrt(2)*cos(wred*(q-1)/Fs+2*pi/3);

% En este caso de batería, el punto de trabajo es trivial:
%   Ipv en régimen permanente = potencia activa entregada / V0
% En el arranque, asumimos que el bus está cargado a Vbat (sin corriente
% circulando todavía), por lo que V0_inicial = Vbat e Ipv_inicial = 0.
% Durante el control, el bus se desplaza ligeramente respecto a Vbat según
% la corriente que esté circulando: V0 = Vbat - Ipv·Rgen.
Vpv=Vbat;
Ipv=0;


Sref=sqrt(Plim^2+Qref^2);

% Conocida la potencia aparente demandada, calculamos las consignas de
% corriente en coordenadas dq y la corriente de fase teórica que
% inyectará el inversor en régimen permanente.
%
% id_ref es la componente activa (eje d, en fase con la tensión de red),
% iq_ref es la componente reactiva (eje q, en cuadratura). Plim positivo
% = descarga (corriente saliendo del inversor hacia la red), Plim negativo
% = carga (corriente entrando al inversor desde la red).
%
% La amplitud Im y el desfase phi de la corriente trifásica en régimen
% permanente se obtienen de id_ref e iq_ref:
%   Im = sqrt(id_ref^2 + iq_ref^2)
%   phi = atan2(iq_ref, id_ref)
% Con la convención de ir(t) = Im·cos(wred·t + phi).

id_ref = (2/3)*Plim*Snom/(Vfnrmsred*sqrt(2));
iq_ref = (2/3)*Qref*Snom/(Vfnrmsred*sqrt(2));
Im     = sqrt(id_ref^2 + iq_ref^2);
phi    = atan2(iq_ref, id_ref);

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
% Ipv inicial = potencia activa entregada / Vpv = Plim·Snom / Vbat
Ipv_init=Plim*Snom/Vpv;
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

% Filtros de protección (DC, cascada sobre vdcmed e idcmed). Inicialización
% en régimen permanente: todos los retardos al valor DC nominal, porque
% en régimen permanente vdcmed≈Vpv e idcmed≈Ipv_init.
vdcprot_fz1=Vpv;        vdcprot_fz2=Vpv;
vdcprot_inz1=Vpv;       vdcprot_inz2=Vpv;
idcprot_fz1=Ipv_init;   idcprot_fz2=Ipv_init;
idcprot_inz1=Ipv_init;  idcprot_inz2=Ipv_init;

% Retardos del filtro paso-bajo sobre las componentes dq (idmed, iqmed).
% La Park se aplica sobre las corrientes sin filtrar (ir(n), is(n), it(n));
% el filtrado se hace después de la transformación para no perder magnitud
% ni fase de la fundamental a 50 Hz. Reutilizamos los coeficientes [B,A]
% del filtro elíptico de medida (Fp=100 Hz), válido aquí porque las
% componentes en dq son DC en régimen permanente.
% Inicialización en régimen permanente: idmed≈id_ref, iqmed≈iq_ref.
idmedfz1=id_ref;  idmedfz2=id_ref;
idmedinz1=id_ref; idmedinz2=id_ref;
iqmedfz1=iq_ref;  iqmedfz2=iq_ref;
iqmedinz1=iq_ref; iqmedinz2=iq_ref;

% Tensión teórica que sintetiza el inversor antes del filtro Lac.
%
% Por Kirchhoff fasorial sobre la rama RLac + j·wred·Lac:
%   Vinv = Vred + (RLac + j·wred·Lac)·Iac
% con Iac = id_ref + j·iq_ref expresado en el referencial de la red. El
% módulo Vinvvac es la amplitud teórica de la tensión que el inversor
% debe sintetizar; sirve para verificación y para inicialización de los
% retardos del filtro Lac. La fase delta no se utiliza en el control
% vectorial (la fase de las moduladoras se obtiene de la Park inversa).
Vinv_re = Vfnrmsred*sqrt(2) + RLac*id_ref - wred*Lac*iq_ref;
Vinv_im =                      RLac*iq_ref + wred*Lac*id_ref;
Vinvvac = sqrt(Vinv_re^2 + Vinv_im^2);
delta_inicial = atan2(Vinv_im, Vinv_re);

% Calculamos la señal triangular completa para toda la simulación. Es una
% señal de -1 a 1, de frecuencia Fcontrol, con Fs/Fcontrol muestras por
% ciclo. Sirve para comparar con las moduladoras y generar el PWM.
v_tri = 2*abs(2*mod(Fcontrol*(q-1)/Fs, 1) - 1) - 1;


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
% cumple Vbat = V0 + Ipv·Rgen, con Vbat constante.
Idc=Ipv;
V0=Vbat-Ipv*Rgen;         % Tensión inicial del bus DC
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
% en t = -1/Fs. En régimen permanente Vinv tiene fase delta_inicial y módulo
% Vinvvac; Vred tiene fase 0 y módulo Vfn_pico.
vLrz1=Vinvvac*cos(-wred/Fs+delta_inicial) - Vfnrmsred*sqrt(2)*cos(-wred/Fs);
vLsz1=Vinvvac*cos(-wred/Fs+delta_inicial-2*pi/3) - Vfnrmsred*sqrt(2)*cos(-wred/Fs-2*pi/3);
vLtz1=Vinvvac*cos(-wred/Fs+delta_inicial+2*pi/3) - Vfnrmsred*sqrt(2)*cos(-wred/Fs+2*pi/3);

% Diseño del control vectorial dq por cancelación de polo del filtro Lac+RLac.
%
% Planta vista por el lazo de corriente (en cada eje d, q, tras desacoplo):
%   G(s) = 1 / (Lac·s + RLac)
%
% PI por cancelación de polo: el cero del PI cancela el polo de la planta,
% dejando solo un polo en el origen. El lazo cerrado tiene un único polo
% en s = -2π·fc_id.
%
% PI(s) = Kp·(1 + Ki_norm/s) con cero en s = -Ki_norm.
% Para cancelar el polo en s = -RLac/Lac: Ki_norm = RLac/Lac.
% Ki = Kp·Ki_norm = Kp·RLac/Lac.
%
% La ganancia del lazo abierto resulta = Kp/(Lac·s). Para lazo cerrado con
% fc_id: Kp = 2·π·fc_id·Lac. Y por tanto Ki = 2·π·fc_id·RLac.
%
% Cadencia de cálculo: cada Ncontrol muestras, Ts_ctrl = Ncontrol/Fs.
Ts_ctrl=Ncontrol/Fs;
fc_id=300;                                   % Frecuencia de corte del lazo de corriente (Hz)
Kp_id=2*pi*fc_id*Lac;                        % Ganancia proporcional (V/A)
Ki_id=2*pi*fc_id*RLac;                       % Ganancia integral (V/(A·s))
PI_int_d=0;                                  % Estado del integrador en eje d (V)
PI_int_q=0;                                  % Estado del integrador en eje q (V)

% Inicialización de las tensiones de referencia en dq con su valor de régimen
% permanente teórico. En el referencial de la red (Vred en eje d, fase 0),
% el fasor Vinv = Vinv_re + j·Vinv_im se proyecta directamente:
%   vd_inv ← componente en fase con la red, Vinv_re
%   vq_inv ← componente en cuadratura, Vinv_im
vd_inv = Vinv_re;
vq_inv = Vinv_im;

% Inicialización de moduladoras en régimen permanente teórico. En la primera
% muestra del bucle aún no se ha calculado el control, por lo que las
% moduladoras tienen estos valores aproximados (deducidos del balance
% fasorial), que coinciden con lo que devolvería la Park inversa de vd_inv,
% vq_inv en régimen.
mod_r = (2*Vinvvac/Vpv)*cos(delta_inicial);
mod_s = (2*Vinvvac/Vpv)*cos(delta_inicial-2*pi/3);
mod_t = (2*Vinvvac/Vpv)*cos(delta_inicial+2*pi/3);



while (n<=N)

  % Sistema de protecciones.
  %
  % Vigila cuatro umbrales sobre señales filtradas (vdcmed, idcmed, irmed,
  % ismed, itmed) y dispara el trip si alguno se supera. Tras el trip se
  % activan tres procesos en cascada:
  %   1) Bloqueo de IGBTs (Nbloqueo_igbts muestras tras el trip)
  %   2) Apertura del disyuntor AC (Nabre_ac muestras tras el trip)
  %   3) Apertura del disyuntor DC (Nabre_dc muestras tras el trip)
  %
  % Una vez disparado, n_trip queda fijo y la lógica no vuelve a reevaluar
  % los umbrales. La simulación continúa hasta n=N para registrar la
  % dinámica post-trip.
  if (n>Ninhibicion_prot)   % Inhibición de protecciones durante el arranque
    if (n_trip==0)
      % Vigilar umbrales sólo si no ha habido trip todavía
      if (vdcprot(n-1)>Vdcmax)
        n_trip=n;
        motivo_trip="DC_overv";
      elseif (idcprot(n-1)>Idcmax)
        n_trip=n;
        motivo_trip="DC_overc";
      elseif (idcprot(n-1)<Idc_inv_max)
        n_trip=n;
        motivo_trip="DC_invc";
      elseif (abs(irmed(n-1))>Iacmax || abs(ismed(n-1))>Iacmax || abs(itmed(n-1))>Iacmax)
        n_trip=n;
        motivo_trip="AC_overc";
      endif
    endif
  endif

  % Actualización del estado de los actuadores de protección
  if (n_trip>0)
    if (n>=n_trip+Nbloqueo_igbts)
      igbts_activos=0;
    endif
    if (n>=n_trip+Nabre_ac)
      disy_ac_cerrado=0;
    endif
    if (n>=n_trip+Nabre_dc)
      disy_dc_cerrado=0;
    endif
  endif

  % Registro del estado por muestra
  igbts_activos_v(n)=igbts_activos;
  disy_dc_cerrado_v(n)=disy_dc_cerrado;
  disy_ac_cerrado_v(n)=disy_ac_cerrado;

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

  % Generación de las señales moduladoras mediante Park inversa.
  %
  % El control vectorial mantiene en (vd_inv, vq_inv) las tensiones de
  % referencia en coordenadas dq (que son aproximadamente constantes en
  % régimen permanente). La transformada inversa de Park reconstruye las
  % tensiones trifásicas de referencia a cada muestra, usando la fase
  % instantánea de la red theta = wred·(n-1)/Fs. Las moduladoras se
  % normalizan por V0/2 (necesario para que el PWM sintetice la tensión
  % correcta), y se saturan a ±Mmax.
  theta = wred*(n-1)/Fs;
  vinv_ref_r = vd_inv*cos(theta)         - vq_inv*sin(theta);
  vinv_ref_s = vd_inv*cos(theta-2*pi/3)  - vq_inv*sin(theta-2*pi/3);
  vinv_ref_t = vd_inv*cos(theta+2*pi/3)  - vq_inv*sin(theta+2*pi/3);

  mod_r = 2*vinv_ref_r / V0z1;
  mod_s = 2*vinv_ref_s / V0z1;
  mod_t = 2*vinv_ref_t / V0z1;

  % Saturación de moduladoras (sobremodulación máxima ±Mmax).
  sat_r = (abs(mod_r) > Mmax);
  sat_s = (abs(mod_s) > Mmax);
  sat_t = (abs(mod_t) > Mmax);
  if (sat_r) mod_r = Mmax*sign(mod_r); endif
  if (sat_s) mod_s = Mmax*sign(mod_s); endif
  if (sat_t) mod_t = Mmax*sign(mod_t); endif
  sat_any = sat_r || sat_s || sat_t;


  % Generación de las señales PWM de cada fase y rama (positiva y negativa)
  % por comparación de la moduladora con la triangular reescalada (modulación
  % level-shifted de tres niveles).
  %
  % Si los IGBTs están bloqueados (post-trip), los PWM se fuerzan a 0 y la
  % tensión sintetizada queda definida por los diodos de libre circulación
  % (free-wheeling) según el signo de la corriente de fase.

  if (igbts_activos==1)
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
  else
    % IGBTs bloqueados. PWM = 0. La tensión vinv_x queda determinada por
    % los diodos free-wheeling según el signo de la corriente que viene
    % de Lac (usamos la corriente de la muestra anterior, irz1):
    %   - i_x > 0  → diodo de la rama negativa conduce → vinv_x = -V0/2
    %   - i_x < 0  → diodo de la rama positiva conduce → vinv_x = +V0/2
    %   - i_x = 0  → ambos cortados, vinv_x = 0
    Spr=0; Snr=0; Sps=0; Sns=0; Spt=0; Snt=0;
    if (irz1>0)
      vinv_r=-V0z1/2;
    elseif (irz1<0)
      vinv_r=V0z1/2;
    else
      vinv_r=0;
    endif
    if (isz1>0)
      vinv_s=-V0z1/2;
    elseif (isz1<0)
      vinv_s=V0z1/2;
    else
      vinv_s=0;
    endif
    if (itz1>0)
      vinv_t=-V0z1/2;
    elseif (itz1<0)
      vinv_t=V0z1/2;
    else
      vinv_t=0;
    endif
  endif

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

  % Si el disyuntor AC está abierto, las corrientes que pasan por Lac
  % se fuerzan a 0. (Simplificación: no se modela el arco de corte del
  % disyuntor; se asume corte limpio una vez completada la apertura).
  if (disy_ac_cerrado==0)
    ir_act=0;
    is_act=0;
    it_act=0;
  endif

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
  %
  % Con IGBTs bloqueados, los diodos de libre circulación rectifican
  % pasivamente la corriente de Lac. La contribución al bus DC es |i_x|
  % (siempre positiva: la corriente "rectificada" carga Cdc).
  if (igbts_activos==1)
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
  else
    % Rectificador pasivo: cada fase aporta |i_x| al bus si pasa corriente.
    % Si la corriente i_x>0, el diodo superior conduce (corriente sale del
    % bus por la rama positiva). Si i_x<0, el diodo inferior conduce
    % (corriente entra al bus por la rama negativa). En ambos casos, el
    % bus pierde corriente positiva neta.
    idcpr=0; idcnr=0; idcr=abs(ir_act);
    idcps=0; idcns=0; idcs=abs(is_act);
    idcpt=0; idcnt=0; idct=abs(it_act);
    Idc=abs(ir_act)+abs(is_act)+abs(it_act)+Iarcdc;
  endif
  idc(n)=Idc;



  % Cálculo acoplado de V0(n) e Ipv(n) para batería.
  %
  % El sistema acopla dos ecuaciones en el instante n:
  %
  %   1) Regla del trapecio sobre Cdc·dV0/dt = Ipv - Idc:
  %      V0(n) = V0z1 + Kbus·[Ipv(n) - Idc(n) + Ipvz1 - Idcz1]
  %
  %   2) Ley de Ohm en la batería (Vbat constante, Rgen serie):
  %      Ipv(n) = (Vbat - V0(n))/Rgen
  %
  % Sustituyendo (2) en (1) y despejando V0(n):
  %   V0(n) = [V0z1 + Kbus·(Vbat/Rgen - Idc(n) + Ipvz1 - Idcz1)] / (1 + Kbus/Rgen)
  % y después Ipv(n) se calcula a partir de la ley de Ohm.

  if (disy_dc_cerrado==1)
    V0 = (V0z1 + Kbus*(Vbat/Rgen - Idc + Ipvz1 - Idcz1)) / (1 + Kbus/Rgen);
    Ipv_actual = (Vbat - V0)/Rgen;
  else
    % Disyuntor DC abierto: batería desconectada del bus. Ipv=0 y el bus
    % queda con su propia dinámica Cdc·dV0/dt = -Idc, que en regla del
    % trapecio da:
    %   V0(n) = V0(n-1) + Kbus·(-Idc(n) - Idcz1)
    Ipv_actual = 0;
    V0 = V0z1 + Kbus*(-Idc - Idcz1);
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

  % Filtrado adicional de Vdc para protecciones (cascada sobre vdcmed)
  vdcprot(n)=vdcmed(n)*Bmed(1)+vdcprot_inz1*Bmed(2)+vdcprot_inz2*Bmed(3) ...
            -vdcprot_fz1*Amed(2)-vdcprot_fz2*Amed(3);
  vdcprot_inz2=vdcprot_inz1;
  vdcprot_inz1=vdcmed(n);
  vdcprot_fz2=vdcprot_fz1;
  vdcprot_fz1=vdcprot(n);

  % Filtrado de medida Idc
  idcmed(n)=Idc*B(1)+idcinz1*B(2)+idcinz2*B(3)-idcfz1*A(2)-idcfz2*A(3);
  idcinz2=idcinz1;
  idcinz1=Idc;
  idcfz2=idcfz1;
  idcfz1=idcmed(n);

  % Filtrado adicional de Idc para protecciones (cascada sobre idcmed)
  idcprot(n)=idcmed(n)*Bmed(1)+idcprot_inz1*Bmed(2)+idcprot_inz2*Bmed(3) ...
            -idcprot_fz1*Amed(2)-idcprot_fz2*Amed(3);
  idcprot_inz2=idcprot_inz1;
  idcprot_inz1=idcmed(n);
  idcprot_fz2=idcprot_fz1;
  idcprot_fz1=idcprot(n);

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
  % ipv:   corriente entregada por la batería al bus, Ipv = (Vbat-V0)/Rgen.
  % idcin: corriente que entra al bus desde la batería. Al estar Rgen en
  %        serie sin derivaciones intermedias, idcin = ipv.
  % icd:   corriente por el condensador del bus, por balance en el nodo:
  %        icd = idcin - Idc.
  ipv(n)=Ipv_actual;
  idcin(n)=Ipv_actual;
  icd(n)=Ipv_actual-Idc;

  % Medida en coordenadas dq de las corrientes de fase (cada muestra).
  %
  % La Park abc→dq se aplica sobre las corrientes SIN FILTRAR ir(n), is(n),
  % it(n). Hacerla sobre las corrientes filtradas con el filtro de medida
  % a 100 Hz atenuaría y desfasaría la fundamental a 50 Hz, introduciendo
  % un error sistemático en la magnitud y dirección de las componentes dq.
  %
  % Después se aplica un filtro paso-bajo sobre idmed_raw, iqmed_raw para
  % suavizar el rizado de PWM (que en dq aparece como armónicos de alta
  % frecuencia). En régimen permanente las componentes dq son DC, así que
  % el filtro PB no penaliza la respuesta. Reutilizamos los coeficientes
  % [B,A] del filtro elíptico de medida (Fp=100 Hz). IMPORTANTE: este
  % filtro se aplica a cada muestra (Fs=49 kHz, igual que para el resto
  % de medidas) y no cada Ncontrol; de lo contrario, los polos del filtro
  % se desplazan respecto al diseño y desestabilizan el lazo.
  theta = wred*(n-1)/Fs;
  idmed_raw =  (2/3)*( ir(n)*cos(theta) + is(n)*cos(theta-2*pi/3) + it(n)*cos(theta+2*pi/3) );
  iqmed_raw = -(2/3)*( ir(n)*sin(theta) + is(n)*sin(theta-2*pi/3) + it(n)*sin(theta+2*pi/3) );

  idmed = idmed_raw*B(1) + idmedinz1*B(2) + idmedinz2*B(3) - idmedfz1*A(2) - idmedfz2*A(3);
  idmedinz2=idmedinz1; idmedinz1=idmed_raw;
  idmedfz2=idmedfz1;   idmedfz1=idmed;

  iqmed = iqmed_raw*B(1) + iqmedinz1*B(2) + iqmedinz2*B(3) - iqmedfz1*A(2) - iqmedfz2*A(3);
  iqmedinz2=iqmedinz1; iqmedinz1=iqmed_raw;
  iqmedfz2=iqmedfz1;   iqmedfz1=iqmed;

  % Actualización del control vectorial dq cada Ncontrol muestras.
  %
  % Pasos:
  %   1) Errores de seguimiento respecto a las consignas id_ref, iq_ref,
  %      usando las componentes dq filtradas que se actualizan a cada
  %      muestra antes de este bloque.
  %   2) PI por eje (cancelación de polo del filtro Lac+RLac).
  %   3) Desacoplo cruzado d-q y feed-forward de tensión de red:
  %      vd_inv = vd_pi + Vfn_pico - wred·Lac·iqmed
  %      vq_inv = vq_pi               + wred·Lac·idmed
  %   4) Las tensiones en dq se almacenan; la Park inversa se aplica
  %      muestra a muestra al inicio del bucle siguiente.
  %   5) Anti-windup: si las moduladoras se han saturado en la última
  %      muestra, se congela el integrador de los dos ejes (sat_any).
  control=control+1;
  if (control>=Ncontrol && igbts_activos==1)
    control=0;

    % Errores
    err_id = id_ref - idmed;
    err_iq = iq_ref - iqmed;

    % PI por eje. Integrador con anti-windup si las moduladoras saturaron.
    if (sat_any==0)
      PI_int_d = PI_int_d + Ki_id*Ts_ctrl*err_id;
      PI_int_q = PI_int_q + Ki_id*Ts_ctrl*err_iq;
    endif
    vd_pi = Kp_id*err_id + PI_int_d;
    vq_pi = Kp_id*err_iq + PI_int_q;

    % Desacoplo cruzado d-q y feed-forward de tensión de red:
    %   eje d incluye la tensión de red (Vfn_pico) y resta el término de
    %                acoplamiento del eje q (wred·Lac·iqmed).
    %   eje q solo suma el término de acoplamiento del eje d.
    vd_inv = vd_pi + Vfnrmsred*sqrt(2) - wred*Lac*iqmed;
    vq_inv = vq_pi                     + wred*Lac*idmed;
  endif


  n=n+1;

endwhile

