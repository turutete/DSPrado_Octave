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
It=(-2048:2047).*dI;
Vt=(alfa*Rc.*It)./(atan(beta.*It).*It.*Rc+alfa);

% Modelo de circuito de descarga
Rl=10;

% Ejemplo de Arco DC
Fs=12500;
%Vg_vector=[75*ones(1,512) 150*ones(1,512)];
n=1:1024;
Vg_vector(n)=150*sin(2*pi*50*n/Fs);



Vt_vector=[];
It_vector=[];

for index=1:length(Vg_vector)
  
  % Cálculo de puntos de trabajo
  Vt2=Vg_vector(index)-It.*Rl;

  % Cálculo rápido puntos corte
  index_corte=Puntos_Corte(Vt,Vt2);
  if length(index_corte)==0
    error("El modelo V-I estático tiene pocos puntos");
  endif
  
  It_corte=(index_corte-2049).*dI;
  Vt_corte=Vg_vector(index)-It_corte.*Rl;
  
  if index==1
    [Itn,indimax]=max(It_corte);
    Vtn=Vt_corte(indimax);
    Vtprev=Vtn;
    Itprev=Itn;
    Ptprev=Vtn*Itn;
  else
    Pn_vect=It_corte.*Vt_corte;
    Pnprev_vect=Ptprev*ones(size(index_corte));
    Pdif=abs(Pnprev_vect-Pn_vect);
    [Pdifmin,indmin]=min(Pdif);
    Vtn=Vt_corte(indmin);
    Itn=It_corte(indmin);
    Vtprev=Vtn;
    Itprev=Itn;
    Ptprev=Vtn*Itn;
  endif
  
  Vt_vector(index)=Vtn;
  It_vector(index)=Itn;
  
endfor

% Modelo dinámico del arco eléctrico
tau=100e-6;

A=1+2*tau*Fs;
B=1-2*tau*Fs;

Nom=[1 1];
Den=[A B];

Iarc=filter(Nom,Den,It_vector);
Varc=filter(Nom,Den,Vt_vector);

figure(1);plot(Varc);
figure(2);plot(Iarc);



  














  

