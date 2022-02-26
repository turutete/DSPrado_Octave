%
% LP_Configurable
%
% Autor: Dr. Carlos Romero
% 
% Historial
%
% 20/10/2021: Primera edición
%
% Descripción
%
% Estudio para diseño de filtro LP configurable para el proyecto STAMINA, bloque
% Noise Generator.
%
% La idea es diseñar un filtro patrón Hp(z), IIR y utilizar la transformación de
% Contastinides para modificar la banda de paso del filtro.

pkg load signal;

% Especificaciones del filtro patrón
fp=1/8;
Wp=1/64;
Rp=0.001;
Rs=91;

% Orden del filtro patrón IIR elíptico
Npatron=ellipord(fp,fp+Wp,Rp,Rs);

% Diseño filtro IIR elíptico
[B1,A1]=ellip(Npatron,Rp,Rs,fp);
[H1,W]=freqz(B1,A1,1024);
figure(1);plot(W/pi,20*log10(abs(H1)));grid;xlabel('f/fNyquist');
ylabel('|H1(f)| [dB]');title('Filtro LP patrón');


% Obtención de Biquads
K=B1(1);
B1n=B1./K;
Z1=roots(B1n);
P1=roots(A1);

N1=real(conv([1 -Z1(1)],[1 -Z1(2)]));
N2=real(conv([1 -Z1(3)],[1 -Z1(4)]));
N3=real(conv([1 -Z1(5)],[1 -Z1(6)]));
N4=real(conv([1 -Z1(7)],[1 -Z1(8)]));
N5=real(conv([1 -Z1(9)],[1 -Z1(10)]));
N6=real(conv([1 -Z1(11)],[1 -Z1(12)]));
N7=real(conv([1 -Z1(13)],[1 -Z1(14)]));

D1=real(conv([1 -P1(1)],[1 -P1(2)]));
D2=real(conv([1 -P1(3)],[1 -P1(4)]));
D3=real(conv([1 -P1(5)],[1 -P1(6)]));
D4=real(conv([1 -P1(7)],[1 -P1(8)]));
D5=real(conv([1 -P1(9)],[1 -P1(10)]));
D6=real(conv([1 -P1(11)],[1 -P1(12)]));
D7=real(conv([1 -P1(13)],[1 -P1(14)]));

[HB1,W]=freqz(N1,D1,1024);
[HB2,W]=freqz(N2,D2,1024);
[HB3,W]=freqz(N3,D3,1024);
[HB4,W]=freqz(N4,D4,1024);
[HB5,W]=freqz(N5,D5,1024);
[HB6,W]=freqz(N6,D6,1024);
[HB7,W]=freqz(N7,D7,1024);

HBT=K.*(HB1.*HB2.*HB3.*HB4.*HB5.*HB6.*HB7);

figure(2);plot(W/pi,20*log10(abs(HBT)));grid;xlabel('f/FNyqyst');
ylabel('|HT(f)| dB');title('Respuesta en frecuencia Biquads en Cascada');

% Gestión del escalado K1 para que las salidas de los biquad estén normalizados
%K1=1/abs(HB1(63));
%K2=1/abs(HB2(63));
%K3=1/abs(HB3(63));
%K4=1/abs(HB4(63));
%K5=1/abs(HB5(63));
%K6=1/abs(HB6(63));
%K7=K/(K1*K2*K3*K4*K5*K6);
K1=K;

% Cuantización coeficientes Q2.30
Nq1=round(N1*K1*2^30);
Dq1=round(D1*2^30);
Nq2=round(N2*K2*2^30);
Dq2=round(D2*2^30);
Nq3=round(N3*K3*2^30);
Dq3=round(D3*2^30);
Nq4=round(N4*K4*2^30);
Dq4=round(D4*2^30);
Nq5=round(N5*K5*2^30);
Dq5=round(D5*2^30);
Nq6=round(N6*K6*2^30);
Dq6=round(D6*2^30);
Nq7=round(N7*K7*2^30);
Dq7=round(D7*2^30);


NQ1=Nq1./2^30;
DQ1=Dq1./2^30;
NQ2=Nq2./2^30;
DQ2=Dq2./2^30;
NQ3=Nq3./2^30;
DQ3=Dq3./2^30;
NQ4=Nq4./2^30;
DQ4=Dq4./2^30;
NQ5=Nq5./2^30;
DQ5=Dq5./2^30;
NQ6=Nq6./2^30;
DQ6=Dq6./2^30;
NQ7=Nq7./2^30;
DQ7=Dq7./2^30;


[HQB1,W]=freqz(NQ1,DQ1,1024);
[HQB2,W]=freqz(NQ2,DQ2,1024);
[HQB3,W]=freqz(NQ3,DQ3,1024);
[HQB4,W]=freqz(NQ4,DQ4,1024);
[HQB5,W]=freqz(NQ5,DQ5,1024);
[HQB6,W]=freqz(NQ6,DQ6,1024);
[HQB7,W]=freqz(NQ7,DQ7,1024);

HQBT=HQB1.*HQB2.*HQB3.*HQB4.*HQB5.*HQB6.*HQB7;

figure(3);plot(W/pi,20*log10(abs(HQBT)));grid;xlabel('f/FNyqyst');
ylabel('|HQT(f)| dB');title('Respuesta en frecuencia Biquads Cuantizados en Cascada');

% Error Cuantización
figure(4);plot(W/pi,20*log10(abs(HQBT-H1)));grid;xlabel('f/FNyqyst');
ylabel('|HQT(f)-H1(f)| dB');title('Error de cuantización Q2.30');

% Muestra en pantalla los coeficientes Q2.30
%Kq1
%[Nq1 Dq1;Nq2 Dq2;Nq3 Dq3;Nq4 Dq4;Nq5 Dq5;Nq6 Dq6;Nq7 Dq7]


% Prueba de transformación LP a LP
Fsampling=200e6;
W=50e6;

FC=W/2;             % Frecuencia de paso analógico filtro transformado
F0=Fsampling*fp/2;  % Frecuencia de paso analógica filtro patrón

alfa=sin((F0-FC)/(2*Fsampling))/sin((F0+FC)/(2*Fsampling));

MT=[1 -alfa alfa^2;-2*alfa 1+alfa^2 -2*alfa;alfa^2 -alfa 1];

BT1=MT*NQ1';
AT1=MT*DQ1';
BT2=MT*NQ2';
AT2=MT*DQ2';
BT3=MT*NQ3';
AT3=MT*DQ3';
BT4=MT*NQ4';
AT4=MT*DQ4';
BT5=MT*NQ5';
AT5=MT*DQ5';
BT6=MT*NQ6';
AT6=MT*DQ6';
BT7=MT*NQ7';
AT7=MT*DQ7';


[HT1,W]=freqz(BT1,AT1,1024);
[HT2,W]=freqz(BT2,AT2,1024);
[HT3,W]=freqz(BT3,AT3,1024);
[HT4,W]=freqz(BT4,AT4,1024);
[HT5,W]=freqz(BT5,AT5,1024);
[HT6,W]=freqz(BT6,AT6,1024);
[HT7,W]=freqz(BT7,AT7,1024);

HT=HT1.*HT2.*HT3.*HT4.*HT5.*HT6.*HT7;
figure(5);plot(W/pi,20*log10(abs(HT)));grid;xlabel('f/FNyqyst');
ylabel('|HT(f)| dB');title('Filtro Transformado');


% Prueba de filtrado de señales
l=1:1024;
f1=1/4-1/16;

%x1(l)=sin(2*pi*(l-1)*f1/2);

x1=randn([1 1024]);


xf1=filter(NQ1,DQ1,x1);
xf2=filter(NQ2,DQ2,xf1);
xf3=filter(NQ3,DQ3,xf2);
xf4=filter(NQ4,DQ4,xf3);
xf5=filter(NQ5,DQ5,xf4);
xf6=filter(NQ6,DQ6,xf5);
xf7=filter(NQ7,DQ7,xf6);

yf1=filter(BT1,AT1,x1);
yf2=filter(BT2,AT2,yf1);
yf3=filter(BT3,AT3,yf2);
yf4=filter(BT4,AT4,yf3);
yf5=filter(BT5,AT5,yf4);
yf6=filter(BT6,AT6,yf5);
yf7=filter(BT7,AT7,yf6);

[X,W]=freqz(x1/512,1,1024);
[XF,W]=freqz(xf7/512,1,1024);
[YF,W]=freqz(yf7/512,1,1024);

figure(6);plot(W/pi,20*log10(abs(X)));grid;xlabel('f/Nyquist');
ylabel('|X(f)| dB');title('Señal de test');

figure(7);plot(W/pi,20*log10(abs(XF)));grid;xlabel('f/Nyquist');
ylabel('|XF(f)| dB');title('Señal Filtrado Patrón');

figure(8);plot(W/pi,20*log10(abs(YF)));grid;xlabel('f/Nyquist');
ylabel('|X(f)| dB');title('Señal Filtrado Transformado');

figure(9);plot(l-1,xf1);grid;xlabel('n');
ylabel('xf1');title('Salida filtro 1');

figure(10);plot(l-1,xf2);grid;xlabel('n');
ylabel('xf2');title('Salida filtro 2');

figure(11);plot(l-1,xf3);grid;xlabel('n');
ylabel('xf3');title('Salida filtro 3');

figure(12);plot(l-1,xf4);grid;xlabel('n');
ylabel('xf4');title('Salida filtro 4');

figure(13);plot(l-1,xf5);grid;xlabel('n');
ylabel('xf5');title('Salida filtro 5');

figure(14);plot(l-1,xf6);grid;xlabel('n');
ylabel('xf6');title('Salida filtro 6');

figure(15);plot(l-1,xf7);grid;xlabel('n');
ylabel('xf7');title('Salida filtro 7');





