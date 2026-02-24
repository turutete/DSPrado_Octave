#
# Estudio del procesado DC para MPPT en Inversor
#
#
# Autor: Dr. Carlos Romero
# Fecha: 03/07/2025

fsampling=49000;
Mcontrol=20;
Mpid=10;
Mmppt=10;

fmppt=fsampling/(Mcontrol*Mpid*Mmppt);

N=65536*2;
n=1:N;
noise=randn(1,N);
var=0.01;             # Varianza deseada

An=sqrt(var);

x=ones(1,N)+An*noise; #Se\u00f1al de entrada con ruido blanco


# Coeficiente filtros para Vdc e Idc

A1=[1.0 -1.991023294375916 0.9910642165212959];
B1=[1.023053634503178e-05 2.046107269006355e-05 1.023053634503178e-05];

A2=[1.0 -1.964088962480375 0.9647349589462809];
B2=[0.0001614991164765417 0.0003229982329530834 0.000161499116476542];

alfa=0.05;

A3=[1 (alfa-1)];
B3=alfa;

[H1,W]=freqz(B1,A1,1024);
[H2,W]=freqz(B2,A2,1024);
[H3,W]=freqz(B3,A3,1024);

figure(1);
plot(W/pi*fsampling/2,20*log10(abs(H1)));
xlabel('f[Hz]');ylabel('LP 50Hz');title('Filtro LP Vdc');


figure(2);
plot(W/pi*fsampling/2,20*log10(abs(H2)));
xlabel('f[Hz]');ylabel('LP 10Hz');title('Filtro LP Idc');

Vesc=filter(B1,A1,ones(1,N));
Iesc=filter(B2,A2,ones(1,N));


figure(3);
plot((n-1)/fsampling,Vesc);
xlabel('t[s]');ylabel('Vdc');title('Respuesta al escal\u00f3n Vdc');

figure(4);
plot((n-1)/fsampling,Iesc);
xlabel('t[s]');ylabel('Idc');title('Respuesta al escal\u00f3n Idc');


Vdc=filter(B1,A1,x);
Idc=filter(B2,A2,x);

figure(5);
plot((n-1)/fsampling,Vdc);
xlabel('t[s]');ylabel('Vdc');title('filtrado Vdc');

figure(6);
plot((n-1)/fsampling,Idc);
xlabel('t[s]');ylabel('Idc');title('filtrado Idc');


figure(7);
plot(W/pi*fmppt/2,20*log10(abs(H3)));
xlabel('f[Hz]');ylabel('LP Mppt');title('Filtro LP Mppt');

Mdecimation=Mcontrol*Mpid*Mmppt;
K=floor(N/Mdecimation);
k=1:K;
vmppt(k)=Vesc((k-1)*Mdecimation+1);
imppt(k)=Iesc((k-1)*Mdecimation+1);
pmppt=vmppt.*imppt;

vmppt1=filter(B3,A3,vmppt);
imppt1=filter(B3,A3,imppt);
pmppt1=filter(B3,A3,pmppt);


q=1:K-1;

dvmppt(q)=vmppt1(q+1)-vmppt1(q);
dimppt(q)=imppt1(q+1)-imppt1(q);
dpmppt(q)=pmppt1(q+1)-pmppt1(q);

dv2=filter(B3,A3,dvmppt);
di2=filter(B3,A3,dimppt);
dp2=filter(B3,A3,dpmppt);

figure(8);
plot((k-1)/fmppt,vmppt1);
xlabel('t[s]');ylabel('vmppt');title('Se\u00f1al Vdc filtrada en mppt');


figure(9);
plot((k-1)/fmppt,imppt1);
xlabel('t[s]');ylabel('imppt');title('Se\u00f1al Idc filtrada en mppt');

figure(10);
plot((k-1)/fmppt,pmppt1);
xlabel('t[s]');ylabel('pmppt');title('Se\u00f1al Pdc filtrada en mppt');

figure(11);
plot((q-1)/fmppt,dvmppt,(q-1)/fmppt,dv2);
xlabel('t[s]');ylabel('dvmppt');title('Se\u00f1al dVdc y filtrada en mppt');

figure(12);
plot((q-1)/fmppt,dimppt,(q-1)/fmppt,di2);
xlabel('t[s]');ylabel('dvmppt');title('Se\u00f1al dIdc y filtrada en mppt');

figure(13);
plot((q-1)/fmppt,dpmppt,(q-1)/fmppt,dp2);
xlabel('t[s]');ylabel('dvmppt');title('Se\u00f1al dPdc y filtrada en mppt');


xalfa=filter(B3,A3,ones(1,1024));
figure(14);
plot((0:1023)/fmppt, xalfa);
xlabel('t[s]');ylabel('alfa step');title('Respuesta escal\u00f3n filtro alfa');


% Filtrado 10Hz a 49kHz

bz =[4.106934343931592e-07   8.213868687863265e-07   4.106934343931569e-07];
az =[1.000000000000000  -1.998204772079749   0.998206414853487];

[Hz,W]=freqz(bz,az,65536);

figure(15);
plot(W/pi*fsampling/2,20*log10(abs(Hz)));
xlabel('f[Hz]');ylabel('H10hz(f)');title('Filtro LP 10Hz 49kHz');

xstep10=filter(bz,az,ones(1,32768));
figure(16);
r=0:32767;
plot(r/fsampling,xstep10);
xlabel('t[s]');ylabel('xstep10');title('Respuesta escal\u00f3n LP 10Hz');






