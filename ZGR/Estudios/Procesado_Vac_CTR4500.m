%
% Análisis del procesado tensiones AC en CTR4500 UL 
%
% Autor: Dr. Carlos Romero
% Fecha: 28/11/2024
%

pkg load signal;

% Coeficientes de los filtros IEC
LP250a0 = 1.0;
LP250a1 = -1.8760874722;
LP250a2 = 0.88403511735;
LP250b0 = 0.095989976023;
LP250b1 = -0.18403230691;
LP250b2 = 0.095989976023;

LP100a0 = 1.0;
LP100a1 = -1.982045514211865;
LP100a2 = 0.9822084697244305;
LP100b0 = 4.073887814128872e-05;
LP100b1 = 8.147775628257749e-05;
LP100b2 = 4.073887814128868e-05;

LP60a0 = 1.0;
LP60a1 = -1.989227806225664;
LP60a2 = 0.9892866812405507;
LP60b0 = 1.471875372168466e-05;
LP60b1 = 2.943750744336933e-05;
LP60b2 = 1.471875372168469e-05;

LP49K50a0 = 1.0;
LP49K50a1 = -1.991023294375916;
LP49K50a2 = 0.9910642165212959;
LP49K50b0 = 1.023053634503178e-05;
LP49K50b1 = 2.046107269006355e-05;
LP49K50b2 = 1.023053634503178e-05;

LP49K10a0 = 1.0;
LP49K10a1 = -1.964088962480375;
LP49K10a2 = 0.9647349589462809;
LP49K10b0 = 0.0001614991164765417;
LP49K10b1 = 0.0003229982329530834;
LP49K10b2 = 0.000161499116476542;

HP40a0 = 1.0;
HP40a1 = -1.992818739576637;
HP40a2 = 0.9928449532702137;
HP40b0 = 0.9964159232117122;
HP40b1 = -1.992831846423425;
HP40b2 = 0.9964159232117131;


% Coeficientes de los filtros UL

LP_F2_300_a0 = 1.0;
LP_F2_300_a1 = -1.945012743353078;
LP_F2_300_a2 = 0.946513048825166;
LP_F2_300_b0 = 3.750763680218274e-04;
LP_F2_300_b1 = 7.501527360436549e-04;
LP_F2_300_b2 = 3.750763680218272e-04;

LP_F2_120_a0 = 1.0;
LP_F2_120_a1 = -1.978005312280513;
LP_F2_120_a2 = 0.978249353958423;
LP_F2_120_b0 =  6.101041947772203e-05;
LP_F2_120_b1 = 1.220208389554441e-04;
LP_F2_120_b2 = 6.101041947772208e-05;

LP_F2_70_a0 = 1.0;
LP_F2_70_a1 = -1.987170429073223;
LP_F2_70_a2 = 0.987253852414093;
LP_F2_70_b0 = 2.085583521742424e-05;
LP_F2_70_b1 = 4.171167043484850e-05;
LP_F2_70_b2 = 2.085583521742423e-05;

LP_48K_ACQ_F2_50_a0 = 1.0;
LP_48K_ACQ_F2_50_a1 = -1.990836266286518;
LP_48K_ACQ_F2_50_a2 = 0.990878907295200;
LP_48K_ACQ_F2_50_b0 = 1.066025217042817e-05;
LP_48K_ACQ_F2_50_b1 = 2.132050434085635e-05;
LP_48K_ACQ_F2_50_b2 = 1.066025217042814e-05;

LP_48K_ACQ_F2_10_a0 = 1.0;
LP_48K_ACQ_F2_10_a1 = -1.998167370831640;
LP_48K_ACQ_F2_10_a2 = 0.998169082735279;
LP_48K_ACQ_F2_10_b0 = 4.279759098346127e-07;
LP_48K_ACQ_F2_10_b1 = 8.559518196692244e-07;
LP_48K_ACQ_F2_10_b2 = 4.279759098346115e-07;

HP_F2_50_a0 = 1.0;
HP_F2_50_a1 = -1.990836266286518;
HP_F2_50_a2 = 0.990878907295200;
HP_F2_50_b0 = 0.995428793395430;
HP_F2_50_b1 = -1.990857586790859;
HP_F2_50_b2 = 0.995428793395430;


% Frecuencias de muestreo
fsampling_ul=48000;
fsampling_iec=49000;
fsampling_control=fsampling/16;


% Análisis de respuesta en frecuencia de los filtros IEC
B250=[LP250b0, LP250b1,LP250b2];
A250=[LP250a0, LP250a1,LP250a2];

B100=[LP100b0, LP100b1,LP100b2];
A100=[LP100a0, LP100a1,LP100a2];

B60=[LP60b0, LP60b1,LP60b2];
A60=[LP60a0, LP60a1,LP60a2];

B49K50=[LP49K50b0, LP49K50b1,LP49K50b2];
A49K50=[LP49K50a0, LP49K50a1,LP49K50a2];

B49K10=[LP49K10b0, LP49K10b1,LP49K10b2];
A49K10=[LP49K10a0, LP49K10a1,LP49K10a2];

B40=[HP40b0, HP40b1,HP40b2];
A40=[HP40a0, HP40a1,HP40a2];

% Análisis de respuesta en frecuencia de los filtros UL
fsampling=fsampling_ul;
B300=[LP_F2_300_b0, LP_F2_300_b1, LP_F2_300_b2];
A300=[LP_F2_300_a0, LP_F2_300_a1, LP_F2_300_a2];  

B120=[LP_F2_120_b0, LP_F2_120_b1, LP_F2_120_b2];
A120=[LP_F2_120_a0, LP_F2_120_a1, LP_F2_120_a1];  

B70=[LP_F2_70_b0, LP_F2_70_b1, LP_F2_70_b2];
A70=[LP_F2_70_a0, LP_F2_70_a1, LP_F2_70_a2];  

B48K50=[LP_48K_ACQ_F2_50_b0, LP_48K_ACQ_F2_50_b1, LP_48K_ACQ_F2_50_b2];
A48K50=[LP_48K_ACQ_F2_50_a0, LP_48K_ACQ_F2_50_a1, LP_48K_ACQ_F2_50_a2];

B48K10=[LP_48K_ACQ_F2_10_b0, LP_48K_ACQ_F2_10_b1, LP_48K_ACQ_F2_10_b2];
A48K10=[LP_48K_ACQ_F2_10_a0, LP_48K_ACQ_F2_10_a1, LP_48K_ACQ_F2_10_a2];

BHP50=[HP_F2_50_b0, HP_F2_50_b1, HP_F2_50_b2];
AHP50=[HP_F2_50_a0, HP_F2_50_a1, HP_F2_50_a2];

[H300,W]=freqz(B300,A300,1024);
[H120,W]=freqz(B120,A120,1024);
[H70,W]=freqz(B70,A70,1024);
[H48K50,W]=freqz(B48K50,A48K50,1024);
[H48K10,W]=freqz(B48K10,A48K10,1024);
[HHP50,W]=freqz(BHP50,AHP50,1024);

figure(1);
plot(W/pi*fsampling/2,20*log10(abs(H48K50)));
xlabel('f[Hz]');ylabel('Hacq(f) dB');title('LP 50 Acq 48kHz');

figure(2);
plot(W/pi*fsampling/2,20*log10(abs(H48K10)));
xlabel('f[Hz]');ylabel('Hacq(f) dB');title('LP 10 Acq 48kHz');

figure(3);
plot(W/pi*fsampling/2,20*log10(abs(H300)));
xlabel('f[Hz]');ylabel('H300(f) dB');title('LP 300');

figure(4);
plot(W/pi*fsampling/2,20*log10(abs(H120)));
xlabel('f[Hz]');ylabel('H120(f) dB');title('LP 120');

figure(5);
plot(W/pi*fsampling/2,20*log10(abs(H70)));
xlabel('f[Hz]');ylabel('H70(f) dB');title('LP 70');

figure(6);
plot(W/pi*fsampling/2,20*log10(abs(HHP50)));
xlabel('f[Hz]');ylabel('HP(f) dB');title('HP');


% Filtros BP UL

figure(7);
plot(W/pi*fsampling/2,20*log10(abs(H300.*HHP50)));
xlabel('f[Hz]');ylabel('BP300(f) dB');title('BP 300');


figure(8);
plot(W/pi*fsampling/2,20*log10(abs(H120.*HHP50)));
xlabel('f[Hz]');ylabel('BP120(f) dB');title('BP 120');

figure(9);
plot(W/pi*fsampling/2,20*log10(abs(H70.*HHP50)));
xlabel('f[Hz]');ylabel('BP70(f) dB');title('BP 70');

% Retardo de grupos UL

% HP50 - LP70
[GHP50,W]=grpdelay(BHP50,AHP50,1024);
[GLP70,W]=grpdelay(B70,A70,1024);

% LP300
[GLP300,W]=grpdelay(B300,A300,1024);
% LP 48KHz
[G48LP50,W]=grpdelay(B48K50,A48K50,1024);
[G48LP10,W]=grpdelay(B48K10,A48K10,1024);

figure(10);
plot(W/pi*fsampling/2,GHP50+GLP70);
xlabel('f[Hz]');ylabel('Nª muestras');title('Retraso grupo BP 50-70');

figure(11);
plot(W/pi*fsampling/2,GLP300);
xlabel('f[Hz]');ylabel('Nª muestras');title('Retraso grupo LP 300');

figure(12);
plot(W/pi*fsampling/2,G48LP50);
xlabel('f[Hz]');ylabel('Nª muestras');title('Retraso grupo LP 48KHz 50');

figure(13);
plot(W/pi*fsampling/2,G48LP10);
xlabel('f[Hz]');ylabel('Nª muestras');title('Retraso grupo LP 48KHz 10');


% Respuestas a Escalón DC o AC UL
n=1:4096;
xin(n)=sin(2*pi*(n-1)*60/fsampling);
xindc=ones(1,4096);

yf_bp5070=filter(BHP50,AHP50,filter(B70,A70,xin));
figure(14);
plot((n-1)/fsampling,yf_bp5070);
xlabel('t[s]');ylabel('yf_bp5070(t)');
title('Respuesta filtro BP50-70 a senoide 60Hz');

yf_lp300=filter(B300,A300,xin);
figure(15);
plot((n-1)/fsampling,yf_lp300);
xlabel('t[s]');ylabel('yf_lp300(t)');
title('Respuesta filtro LP300 a senoide 60Hz ');


yf_lp50=filter(B48K50,A48K50,xindc);
figure(16);
plot((n-1)/fsampling,yf_lp50);
xlabel('t[s]');ylabel('yf_lp50(t)');
title('Respuesta filtro LP50 al escalon ');


yf_lp10=filter(B48K10,A48K10,xindc);
figure(17);
plot((n-1)/fsampling,yf_lp10);
xlabel('t[s]');ylabel('yf_lp10(t)');
title('Respuesta filtro LP10 al escalon ');

% Clarke Park

xcos(n)=cos(2*pi*(n-1)*60/48000);
xcos4(n)=cos(2*pi*(n-1)*60/48000-2*pi/3);
xcos2(n)=cos(2*pi*(n-1)*60/48000+2*pi/3);
xsin(n)=sin(2*pi*(n-1)*60/48000);
xsin4(n)=sin(2*pi*(n-1)*60/48000-2*pi/3);
xsin2(n)=sin(2*pi*(n-1)*60/48000+2*pi/3);

Vrs(n)=sin(2*pi*(n-1)*60/48000);
Vst(n)=0.99*sin(2*pi*(n-1)*60/48000-2*pi/3);
Vtr(n)=1.01*sin(2*pi*(n-1)*60/48000+2*pi/3);

Kcp=2/3;
Kh=1/2;

Vd=Kcp*((xcos.*Vrs).+ (xcos4.*Vst) .+ (xcos2.*Vtr));
Vq=Kcp*((-xsin.*Vrs).- (xsin4.*Vst) .- (xsin2.*Vtr));
Vh=Kcp*Kh*(Vrs+Vst+Vtr);

figure(18);
plot((n-1)/48000,Vd);
xlabel('t[s]');ylabel('Vd(t)');title('Vd');

figure(19);
plot((n-1)/48000,Vq);
xlabel('t[s]');ylabel('Vq(t)');title('Vq');

figure(20);
plot((n-1)/48000,Vh);
xlabel('t[s]');ylabel('Vh(t)');title('Vh');


  
% Prueba hueco

hueco=[ones(1,2048) 0.1*ones(1,2048)];

Vrsh=Vrs.*hueco;
Vsth=0.99*Vst.*hueco;
Vtrh=1.01*Vtr.*hueco;

Vdh=Kcp*((xcos.*Vrsh).+ (xcos4.*Vsth) .+ (xcos2.*Vtrh));
Vqh=Kcp*((-xsin.*Vrsh).- (xsin4.*Vsth) .- (xsin2.*Vtrh));
Vhh=Kcp*Kh*(Vrsh+Vsth+Vtrh);

figure(21);
plot((n-1)/48000,Vdh);
xlabel('t[s]');ylabel('Vdh(t)');title('Vdh');

figure(22);
plot((n-1)/48000,Vqh);
xlabel('t[s]');ylabel('Vqh(t)');title('Vqh');

figure(23);
plot((n-1)/48000,Vhh);
xlabel('t[s]');ylabel('Vhh(t)');title('Vhh');










