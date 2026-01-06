%
% Estudio de protección de sobretensión DC
%
% Proyecto Torres Quevedo NSDSP
%
% Autor: Dr. Carlos Romero Pérez
% fecha: 28/12/2025


pkg load signal;


% Condiciones de la simulación
Fs=3000;        % Frecuencia de muestreo
Fred=50;        % Frecuencia de red
N=1024;         % Número de muestras de la simulación
Vdcnom=1500;    % Tensión nominal del bus de DC en v
var2_low=0.1;   % Varianza de bajo ruido
var2_high=1;    % Varianza de alto ruido
Rampa=10;      % Rampa de subida de tensión en p/u/s
Duracion=0.02;  % Duración de la sobretensión
Nper=256;       % Índice de inicio de la perturbación
Vover=1.1;      % Sobretensión
Vmaxfallo=1.2;  % Fallo de sobretensión inmediato


% Filtrado LP 10Hz Convencional
Wp=100*2/Fs;
[B,A]=ellip(2,0.1,40,Wp);
[H,W]=freqz(B,A,1024);

step=ones(1,1024);
ystep=filter(B,A,step);

%plot(W/pi*Fs/2,20*log10(abs(H)));
%xlabel("f[Hz]");ylabel("LP(f) dB");


% Cálculos auxiliares
l=1:N;
t=(l-1)/Fs; % Base de tiempo en s
Ntotper=floor(Duracion*Fs); % Número de muestras de la perturbación
Vdc=Vdcnom*ones(1,N);
noise=randn(1,N);
Vper=zeros(1,N);

%plot(t,step,t,ystep);
%xlabel("t[s]");ylabel("ystep");

% Menu interactivo

flag_run=1;

while (flag_run==1)
  choice=menu("Escenarios","Súbita 1.15 Var=0.1","Súbita 1.15 Var=1", ...
  "Rampa 10pu Var=0.1","Rampa 10pu Var=1","Oscilatorio","Salir");
  close("all");

  switch (choice)
    case {1}
      % Escenario 1: 1.	Subida súbita de la tensión del bus DC de valor nominal
      % a 1.15 p.u mantenida 20ms, Varianza del ruido=0.1.
      Vsobre=1.15;    % Sobretensión de dc
      Vper=zeros(1,N);
      Vper(Nper:(Nper+Ntotper))=(Vsobre-1)*Vdcnom;
      Vin=Vdc+Vper+sqrt(var2_low)*noise;
    case {2}
      % Escenario 2: 	Subida súbita de la tensión del bus DC de valor nominal
      % a 1.15 p.u mantenida 20ms, Varianza del ruido=1.
      Vsobre=1.15;    % Sobretensión de dc
      Vper=zeros(1,N);
      Vper(Nper:(Nper+Ntotper))=(Vsobre-1)*Vdcnom;
      Vin=Vdc+Vper+sqrt(var2_high)*noise;
    case {3}
      % Escenario 3: 	Subida en rampa 10pu/s de la tensión del bus DC de valor nominal
      % hasta 1.15 p.u. Varianza del ruido=0.1.
      Vmaxover=Vdcnom*(Vover-1);
      delta=Rampa*Vdcnom/Fs;
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

      Vin=Vdc+Vper+sqrt(var2_low)*noise;
    case {4}
      % Escenario 3: 	Subida en rampa 10pu/s de la tensión del bus DC de valor nominal
      % hasta 1.15 p.u. Varianza del ruido=1.
      Vmaxover=Vdcnom*(Vover-1);
      delta=Rampa*Vdcnom/Fs;
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

      Vin=Vdc+Vper+sqrt(var2_high)*noise;
    case {5}
      % Escenario 4: 5.	Subida súbita de la tensión nominal a 1.05 p.u
      % mantenida 250ms. Ruido oscilatorio transitorio de 150Hz de amplitud
      % máxima 10V, tiempo de la oscilación 20ms. Ruido var=1
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

      Vin=Vdc+Vper+sqrt(var2_high)*noise+Vosc;

    case {6}
      flag_run=0;

    otherwise
      error("Caso no contemplado");

  endswitch

  if (flag_run==1)
    % Detección convencional
    Vconv=filter(B,A,Vin);

    figure(1);
    plot(t,Vin,t,Vconv);
    xlabel("t[s]");ylabel("Vconv");

    flag=0;
    alerta=0;
    ind=1;
    count_pert=0;
    Valerta=Vover*Vdcnom;
    Vfallo=Vmaxfallo*Vdcnom;

    while(flag==0)
      if (Vconv(ind)>=Vfallo)
        flag=2;                       % Detección de fallo inmediato
      else
        if (Vconv(ind)>=Valerta)
          if (alerta==0)
            alerta=1;
            count_pert=0;
          else
            count_pert=count_pert+1;
            if (count_pert>=Ntotper)
              flag=1;                % Detección de fallo de sobretensión por tiempo
            endif
          endif
        endif
      endif

      if (flag==0)
        ind=ind+1;
        if (ind>N)
          flag=3;
        endif
      endif
    endwhile

    if (flag==3)
      disp("No se ha detectado fallo de sobretensión");
    endif

    if (flag==2)
      disp("Fallo inmediato de sobretensión t="); disp((ind-1)/Fs);
    endif

    if (flag==1)
      disp("Fallo de sobretensión t="); disp((ind-1)/Fs);
    endif


    % Método de Momentos estadísticos

    M=RT_Momentos(Vin,Fs/Fred);

    figure(2);
    subplot(2,2,1);
    plot(t,M(1,:));
    xlabel("t[s]");ylabel("Media");

    subplot(2,2,2);
    plot(t,M(2,:));
    xlabel("t[s]");ylabel("Varianza");

    subplot(2,2,3);
    plot(t,M(3,:));
    xlabel("t[s]");ylabel("Curtosis");

    subplot(2,2,4);
    plot(t,M(4,:));
    xlabel("t[s]");ylabel("Asimetría");


    % Método Wavelet DB4 M=3
    Wdb4=Wavelet_Db4(Vin,3);

    Wavelet_Visor(Wdb4,Fs,3);
  endif

endwhile



