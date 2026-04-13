#
# IntegDeriv.m
#
# Este script analiza la resolución integro diferencial:
#                                          t1
# (Vbat-V0)/Rbat= Cbus * dV0/dt + 1/Lac Intg (V0-Vred) dt
#                                          t0
#
# Autor: Dr. Carlos Romero Pérez
# Fecha: 28/03/2026
#

% Definición de variables iniciales
N=65536;          % Duración de la simulación
Fs=49000;         % Frecuencia de muestreo de las señales
Fc=2450;          % Frecuencia de control
Vbat=1500;        % Tensión de la batería
Rbat=5e-3;        % Impedancia de salida de la batería
Lac=150e-6;       % Inductancia del filtro LC en H
Cbus=53e-3;       % Condensador del bus DC en F
Fred=50;          % Frecuencia de red
Plim=1;           % Consigna de potencia activa
Qref=0;           % Consigna de potencia ra
Snom=4.5e6;       % Potencia aparente nominal del equipo
Vffrmsred=630;    % Tensión RMS compuesta de la red


% Condición Inicial
V0=0;
Integral=0;
phi=pi/6;
n=1:N;
I0=sqrt(Plim*Snom/Rbat);    % Es la corriente inicial
Vpvref=Vbat-I0*Rbat;        % Vpv es la referencia inicial del valor del bus
Nc=Fs/Fc;                   % Número de muestras en cada ciclo de control

Sref=sqrt(Plim^2+Qref^2); % Cálculo de Sref, con prioridad P
if (Sref>Snom)
  Qref=sqrt(Snom^2-Plim^2);
  Sref=Snom;
endif


wred=2*pi*Fred;
Vfnrmsred=Vffrmsred/sqrt(3);

% Tensión Vr(t)
Vred=Vfnrmsred*sqrt(2)*cos(2*pi*(n-1)*Fred/Fs);

% Señal triangular moduladora
v_tri = 2*abs(2*mod(Fc*(n-1)/Fs, 1) - 1) - 1;

K=1/((1/Rbat)+(1/Lac*Fs));

Vbus=zeros(1,N);

% Simulación
n=1;
q=1;

while (n<=N)
  if (q==1)
    % Cálculos que se realizan en cada ciclo de control
    % Cálculo de la amplitud de la corriente de AC para suministrar Sref
    Im=2/3*Sref*Snom/(Vfnrmsred*sqrt(2));
    phi=atan(Qref/Plim);
    % Cáculo de la tensión de salida del inversor para suministrar Sref
    Vinvvac=sqrt((Vfnrmsred*sqrt(2)-wred*Lac*Im*sin(phi))^2+(wred*Lac*Im*cos(phi))^2);

    % Cálculo del índice de modulación
    M=2*Vinvvac/Vpvref;
    if (M>1.15)
      M=1.15;         % Saturación que se pone al índice de modulación para no aumentar THD
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
  endif

  % Cálculos que se efectuan a Fs

  % Las señales Spx, Snx son 1 ó 0. Si vale '1' conduce. Si '0' no conduce

  % Corriente idcr

  q=q+1;
  if (q==(Nc+1))
    q=1;
  endif
  n=n+1;
endwhile



