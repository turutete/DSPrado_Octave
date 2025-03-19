%
% Matriz_Calibra_LCL.m
%
% Autor: Dr. Carlos Romero P�rez
% 21/05/2024
%
% Script demostrador de c�lculo de matriz de calibraci�n de la rotaci�n
% del filtro LCL del inversor
%

theta=pi/20;      % 9 grados
R=50;             % Carga en ohms
N=64;
l=1:N;

% Matriz Rotaci�n
MR=[cos(theta) -sin(theta); sin(theta) cos(theta)];

vr(l)=cos(2*pi*(l-1)/N);   % 1 ciclo vr(t)
vs(l)=cos(2*pi*(l-1)/N+2*pi/3);
vt(l)=cos(2*pi*(l-1)/N-2*pi/3);

ir=vr./R;
is=vs./R;
it=vt./R;

VR=goertzel(vr,N,1);
VS=goertzel(vs,N,1);
VT=goertzel(vt,N,1);

IR=goertzel(ir,N,1);
IS=goertzel(is,N,1);
IT=goertzel(it,N,1);

Srinv=1/2*(VR*IR');
Ssinv=1/2*(VS*IS');
Stinv=1/2*(VT*IT');

% En forma matricial
MSrinv=[real(Srinv);imag(Srinv)];
MSsinv=[real(Ssinv);imag(Ssinv)];
MStinv=[real(Stinv);imag(Stinv)];

% Rotaci�n causada por el filtro LCL
MSrout=MR*MSrinv;
MSsout=MR*MSsinv;
MStout=MR*MStinv;


SRout=MSrout(1)+j*MSrout(2);
polar(arg(SRout),abs(SRout),'o');

% Generaci�n de se�ales compuestas
vrs=vr-vs;
vst=vs-vt;
vtr=vt-vr;

% Algoritmo de calibraci�n
Pset=real(Srinv);
Qset=0;

Pmeas=MSrout(1);
Qmeas=MSrout(2);

r1=(Pset*Pmeas+Qset*Qmeas)/(Pset^2+Qset^2);
r2=(Pset*Qmeas-Qset*Pmeas)/(Pset^2+Qset^2);

Rcal=[r1 r2;-r2 r1];

% Uso de la calibraci�n
Scal=Rcal*[Pset;Qset];
Sout=MR*Scal;

Scout=Sout(1)+j*Sout(2);

figure(2);
polar(arg(Scout),abs(Scout),'*');
