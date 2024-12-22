#
# Arco_Dinamico.m
#
# Estudio de respuesta dinámica de arco eléctrico
#
# Autor: Dr. Carlos Romero
# Fecha: 22/12/2024

% Modelado de la curva estatica del arco
Rc=2221;
alfa=49.0874;
beta=1.4614;

dI=0.01;
It=(-512:511).*dI;
Vt=(alfa*Rc.*It)./(atan(beta.*It).*It.*Rc+alfa);

% Modelo de circuito de descarga
Rl=10;
Vg=75;

Vt2=Vg-It.*Rl;

figure(1);plot(It,Vt,It,Vt2);

% Cálculo rápido puntos corte
F=Vt2-Vt;
L=length(F);
F2=[F(1)^2 F(1:L-1).*F(2:L)];

index_cross=find(F2<0);


Iarc=It(index_cross);
Varc=(alfa*Rc.*Iarc)./(atan(beta.*Iarc).*Iarc.*Rc+alfa);









  

