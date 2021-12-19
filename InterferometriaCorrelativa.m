%
% InterferometriaCorrelativa
%
% Autor: Dr. Carlos Romero
%
% Script de an�lisis de interferometr�a correlativa.
%
% El objetivo es simular resultados de interferometr�a para diversos
% par�etros configurables del sistema, y estudio de mecanismos de 
% calibraci�n del sistema.
%
% Historial de Cambios
% |versi�n|fecha|Descripci�n|
% |1|28/11/2021| Primera edici�n|
%
%

% Par�metros configurables del sistema
% 

% Suponemos 4 antenas. La antena n�1 es la que est� m�s a la izquierda
%   1          2        3     4
%  ()---------()-------()----()
%    <-- D12--->
%    <---------D13----->
%    <-------------D14-------->
%               <--D23-->
%               <-----24------>
%                        <-D34->
%
% La elecci�n de estas longitudes hace que todos los Dij sean distintos

D12=0.5;
D13=0.8;
D14=0.9;
D23=D13-D12;
D24=D14-D12;
D34=D14-D13;

% Rango de frecuencias [GHz]
Fmax=40;
Fmin=0.5;
df=0.5;   %Precisi�n en frecuencia

% Rango de �ngulo de incidencia [�]
tetamin=-90;
tetamax=90;
dteta=1;    % Precisi�n en �ngulo

% 
%  �ngulos de inciencia por la izda son negativos. �ngulos 
%  por la derecha son positivos.
%
%  La ecuaci�n de onda es 
%
% y(x,t)=A sin(2 pi* x/landa - 2 pi v t/landa)
%
% siendo landa la longitud de onda y v la velocidad de propagaci�n de la 
% onda.
%
% f=v/landa
%
% En un istante dado t0, la diferencia de frecuencia instant�nea
% entre un antena i a la izda y otra j a la derecha, separadas Dij
% viene dada por la expresi�n
% 
% dwij= 2 pi Dij*f/v * sin (teta)
%





