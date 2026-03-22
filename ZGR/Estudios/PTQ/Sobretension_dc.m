%
% Estudio de protección de sobretensión DC
%
% Proyecto Torres Quevedo NSDSP
%
% Generador de señales de sobretensión
%
% Este script presenta diversos eventos de sobretensión en un bus DC.
% La opción escogida por el usuario se muestra en una gráfica, y al seleccionar
% la opción SALIR del menú la gráfica desaparece, pero la señal generada permanece
% en el espacio de trabajo, pudiéndola usar como entrada a otras funciones
%
% El número de muestras de la simulación se define mediante el parámetro N.
%
% Autor: Dr. Carlos Romero Pérez
% fecha: 28/12/2025

pkg load signal;


% Condiciones de la simulación
Fs=2450;        % Frecuencia de muestreo
Fred=50;        % Frecuencia de red
N=8192;         % Número de muestras de la simulación
Vdcnom=1500;    % Tensión nominal del bus de DC en v
Rampa=10;       % Rampa de subida de tensión en %pu/s
Duracion=0.02;  % Duración de la sobretensión
Nper=256;       % Índice de inicio de la perturbación
Vover=1.1;      % Sobretensión
Vmaxfallo=1.2;  % Fallo de sobretensión inmediato
Tovermax=0.015; % Tiempo máximo permitido en alerta de sobretensión


% Cálculos auxiliares
l=1:N;
t=(l-1)/Fs; % Base de tiempo en s
Ntotper=floor(Duracion*Fs); % Número de muestras de la perturbación
Noverfault=floor(Tovermax*Fs); % Número de muestras en alerta para fallo
Vdc=Vdcnom*ones(1,N);
Vper=zeros(1,N);

% Menu interactivo

flag_run=1;

while (flag_run==1)
  choice=menu("Escenarios","Súbita 1.15","Rampa 10pu","Oscilatorio",...
  "Rampa 600ms y subita 1.3","Salir");

  figure(1);

  switch (choice)
    case {1}
      % Escenario 1: 1.	Subida súbita de la tensión del bus DC de valor nominal
      % a 1.15 p.u
      Vsobre=1.15;    % Sobretensión de dc
      Vper=zeros(1,N);
      Vper(Nper:N)=(Vsobre-1)*Vdcnom;
      Vin=Vdc+Vper;
      plot(t,Vin);
      title("Sobretensión súbita 1.15 pu");

    case {2}
      % Escenario 2: 	Subida en rampa 10%pu/s de la tensión del bus DC de valor nominal
      % hasta 1.15 p.u.
      Vsobre=1.15;
      Vmaxover=Vdcnom*(Vsobre-1);
      delta=(Rampa*Vdcnom)/(100*Fs);
      Vper=zeros(1,N);

      ind=Nper;
      while(ind <=N)
        Vaux=Vper(ind-1)+delta;
        if (Vaux>=Vmaxover)
          Vaux=Vmaxover;
        endif
        Vper(ind)=Vaux;
        ind=ind+1;
      endwhile

      Vin=Vdc+Vper;
      plot(t,Vin);
      title("Sobretensión en rampa 10pu/s hasta 1.15 pu");

    case {3}
      % Escenario 3: 5.	Subida súbita de la tensión nominal a 1.05 p.u
      % mantenida 250ms. Ruido oscilatorio transitorio de 150Hz de amplitud
      % máxima 10V, tiempo de la oscilación 20ms.
      Vsobre=1.05;
      Tosc=0.25;
      Aosc=10;
      Fosc=150;
      Nosc=floor(Fs*Tosc);
      Vper=zeros(1,N);
      Vosc=zeros(1,N);
      Vper(Nper:(Nper+Ntotper))=(Vsobre-1)*Vdcnom;
      q=Nper:(Nper+Nosc);
      Vosc(q)=Aosc*cos(2*pi*(q-Nper).*Fosc./Fs).*e.^(-(q-Nper)./(Tosc*Fs));

      Vin=Vdc+Vper+Vosc;
      plot(t,Vin);
      title("Sobretensión súbita a 1.05 pu durante 250ms + transitorio 10 V 150Hz 20ms");

    case {4}
      % Escenario 4: Subida en rampa 10 %pu/s durante 600ms. Subida súbita a 1.3
      % tras los 600ms
      Vsobre=1.3;
      Vmaxover=0.15*Vdcnom;
      Vper=zeros(1,N);
      delta=(Rampa*Vdcnom)/(100*Fs);
      ind=Nper;
      Nrampa=floor(0.6*Fs);
      while (ind<=(Nper+Nrampa))
        Vaux=Vper(ind-1)+delta;
        if (Vaux>=Vmaxover)
          Vaux=Vmaxover;
        endif
        Vper(ind)=Vaux;
        ind=ind+1;
      endwhile
      Vper(ind:N)=(Vsobre-1)*Vdcnom;
      Vin=Vdc+Vper;
      plot(t,Vin);
      title("Rampa 10% pu/s 20ms + súbita a 1.3 pu a los 20ms");

    case {5}
      flag_run=0;
      close all;
    otherwise
      error("Caso no contemplado");
  endswitch

  xlabel("t [s]");
  ylabel("Vi(t)");
  grid;

endwhile

close all;



