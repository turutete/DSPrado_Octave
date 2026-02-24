#
# Dise\u00f1o de filtro LP para c\u00e1lculo de la DC en m\u00f3dulo de potencia
#
# Se dise\u00f1a primero un filtro IIR semilla el\u00edptico LP de orden 4, con frecuencia
# de paso normalizada Wn=0.1, rizado en banda de paso Rp=0.1dB y atenuaci\u00f3n
# en banda de rechazo Rs=40dB.
#
# Wp es la frecuencia mayor en la banda de paso dentro del rizado Rp.
#
# Despu\u00e9s usamos la transformaci\u00f3n de Constantinides para Lp a Lp, para calcular
# los coeficientes del filtro transformado, de forma que la frecuencia de paso
# objetivo sea wc2=Wp, siendo wc1=Wn.
#
# La transformaci\u00f3n es z^-1 -> (z^-1 -alfa)/(1-alfa*z^-1)
#
# siendo alfa=sin((wc1-wc2)/2)/sin((wc1+wc2)/2)
#
# Autor: Dr. Carlos Romero
# Fecha: 30/05/2025

pkg load signal;
% Especificaci\u00f3n
Fsampling=48000;
Fpass=10;
Fstop=15;

Rp=0.1;   % Rizado en banda de paso en dB Rp=20log(Rmax) Rmax valor en banda paso)
Rs=40;    % Atenuaci\u00f3n en banda de rechazo en dB

% C\u00e1lculos intermedios
Fnyquist=Fsampling/2;
Wn=0.1;
N=4;
[B,A]=ellip(N,Rp,Rs,Wn);

Wp=Fpass/Fnyquist;
Ws=Fstop/Fnyquist;

[H,W]=freqz(B,A,1024);

figure(1);
plot(W/pi*Fnyquist,20*log10(abs(H)));
title('Filtro patr\u00f3n');xlabel('F[Hz]');ylabel('dB');

% Transformaci\u00f3n Constantinides
wc1=Wn*pi;
wc2=Wp*pi;


alfa=sin((wc1-wc2)/2)/sin((wc1+wc2)/2);

% Descomponemos los polinomios de orden 4 en cascada de orden 2
Z=roots(B);
P=roots(A);

L=length(Z);

for l=1:L
  ceros(l,:)=[1 -Z(l)];
  polos(l,:)=[1 -P(l)];
endfor

N1=conv(ceros(1,:),ceros(2,:))*B(1);
D1=conv(polos(1,:),polos(2,:));
N2=conv(ceros(3,:),ceros(4,:));
D2=conv(polos(3,:),polos(4,:));

% Transformaci\u00f3n de cada Biquad
B10=N1(1)-alfa*N1(2)+alfa^2*N1(3);
A10=D1(1)-alfa*D1(2)+alfa^2*D1(3);
B11=N1(2)*(1+alfa^2)-2*alfa*(N1(1)+N1(3));
A11=D1(2)*(1+alfa^2)-2*alfa*(D1(1)+D1(3));
B12=N1(1)*alfa^2-N1(2)*alfa+N1(3);
A12=D1(1)*alfa^2-D1(2)*alfa+D1(3);


B20=N2(1)-alfa*N2(2)+alfa^2*N2(3);
A20=D2(1)-alfa*D2(2)+alfa^2*D2(3);
B21=N2(2)*(1+alfa^2)-2*alfa*(N2(1)+N2(3));
A21=D2(2)*(1+alfa^2)-2*alfa*(D2(1)+D2(3));
B22=N2(1)*alfa^2-N2(2)*alfa+N2(3);
A22=D2(1)*alfa^2-D2(2)*alfa+D2(3);

B1=[B10 B11 B12];
A1=[A10 A11 A12];

K1=A1(1);

B2=[B20 B21 B22];
A2=[A20 A21 A22];

K2=A2(1);

B1=B1/K1;
A1=A1/K1;
B2=B2/K2;
A2=A2/K2;


% Respuesta en frecuencia del nuevo filtro transformado
[H1,W]=freqz(B1,A1,32768);
[H2,W]=freqz(B2,A2,32768);

figure(2);
plot(W/pi*Fnyquist,20*log10(abs(H1.*H2)));
title('Filtro transformado');xlabel('F[Hz]');ylabel('dB');


% Ejemplo de filtrado de se\u00f1al

q=1:65536;
x(q)=100*sin(2*pi*50/Fsampling*(q-1))+10;

yf=filter(B2,A2,filter(B1,A1,x));

figure(3);
plot((q-1)/Fsampling,x);
title('Se\u00f1al de test');xlabel('t[s]');ylabel('x(t)');

figure(4);
plot((q-1)/Fsampling,yf);
title('Se\u00f1al filtrada');xlabel('t[s]');ylabel('xf(t)');











