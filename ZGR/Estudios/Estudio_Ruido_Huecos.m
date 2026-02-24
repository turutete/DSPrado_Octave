## -*- texinfo -*-
##
## Estudio_Ruido_Huecos.m
##
## Script de an\u00e1lisis del ruido en el m\u00f3dulo de potencia UL en la se\u00f1al
## usada para detectar huecos
##
## Esta se\u00f1al es la amplitud del vector de tensi\u00f3n, obtenida mediante
## transformaci\u00f3n Clark-Park de las se\u00f1ales de tensi\u00f3n complejas de red.
##
## El objetivo del estudio es analizar las componentes espectrales que componentes
## la se\u00f1al para poder dise\u00f1ar un filtro digital que proporcione una se\u00f1al que
## facilite la detecci\u00f3n de huecos.
##
## Las se\u00f1ales que se usan de an\u00e1lisis han sido muestreadas 1 Fs=1KhZ.
## Esta frecuencia de muestreo es muy inferior a la frecuencia de muestreo real
## utilizado en el procesado del m\u00f3dulo de potencia.
##
## No obstante, servir\u00e1 para identificar el ruido, dise\u00f1ar filtros que lo
## eliminen, y proponer filtros similares para usarlo a mayor feccuencia de
## muestreo.
##
## Autor: Dr. Carlos Romero P\u00e9rez
## Fecha: 26/02/2025
##
## Copyright: Zigor R&D AIE
##

pkg load signal;


x=load("fast_amp_dir_sec.txt");
sogi=load("sogi_data.txt");

Fs=1000;

[X,W]=freqz(x/8192,1,16384);

figure(1);
%plot(W/pi*Fs/2,20*log10(abs(X)));
%xlabel("f[Hz]");ylabel("X(f)");title("Se\u00f1al de interes raw");

[B,A]=ellip(4,0.1,40,30/500);

[H,W]=freqz(B,A,16384);


yf=filter(B,A,x*1.012);

[Yf,W]=freqz(yf/8192,1,16384);
[S,W]=freqz(sogi/8192,1,16384);

l=1:length(x);

%figure(2);
%plot(l-1,x,l-1,sogi,l-1,yf);
%xlabel("t[s]");ylabel("x(n),sogi(n) yf(n)");title("Comparaci\u00f3n sogi, raw y filtrada");

%figure(3);
%plot(W/pi*Fs/2,20*log10(abs(Yf)));
%xlabel("f[Hz]");ylabel("Yf(f)");title("Se\u00f1al de interes filtrada");

%figure(4);
%plot(W/pi*Fs/2,20*log10(abs(S)));
%xlabel("f[Hz]");ylabel("S(f)");title("Se\u00f1al de Sogi");



%figure(5);
%plot(W/pi*Fs/2,20*log10(abs(H)));
%xlabel("f[Hz]");ylabel("H(f)");title("Filtro");


% C\u00e1lculo de filtros Rechazo Banda
K=9;         % Arm\u00f3nicos de la fundamental
f0=54.16;   % Frecuencia notch fundamental (k=1)
BW=20;      % Ancho banda (-3dB)

MB=zeros(K,3);
MA=zeros(K,3);

OT=2*pi*BW/Fs;
a2=(1-tan(OT/2))/(1+tan(OT/2));

for k=1:K

  wT=2*pi*f0*k/Fs;
  a1=2*cos(wT)/(1+tan(OT/2));

  MB(k,:)=1/2*[(1+a2) -2*a1 (1+a2)];
  MA(k,:)=[1 -a1 a2];
endfor

% Filtrado en cascada
yfn1=filter(MB(1,:),MA(1,:),x);
yfn2=filter(MB(2,:),MA(2,:),yfn1);
yfn3=filter(MB(3,:),MA(3,:),yfn2);
yfn4=filter(MB(4,:),MA(4,:),yfn3);
yfn5=filter(MB(5,:),MA(5,:),yfn4);
yfn6=filter(MB(6,:),MA(6,:),yfn5);
yfn7=filter(MB(7,:),MA(7,:),yfn6);
yfn8=filter(MB(8,:),MA(8,:),yfn7);
yfn9=filter(MB(9,:),MA(9,:),yfn8);





