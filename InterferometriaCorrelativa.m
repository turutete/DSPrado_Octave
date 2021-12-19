%
% InterferometriaCorrelativa
%
% Autor: Dr. Carlos Romero
%
% Script de análisis de interferometría correlativa.
%
% El objetivo es simular resultados de interferometría para diversos
% paráetros configurables del sistema, y estudio de mecanismos de 
% calibración del sistema.
%
% Historial de Cambios
% |versión|fecha|Descripción|
% |1|28/11/2021| Primera edición|
%
%

% Parámetros configurables del sistema
% 

% Suponemos 4 antenas. La antena nº1 es la que está más a la izquierda
%   1          2        3     4
%  ()---------()-------()----()
%    <-- D12--->
%    <---------D13----->
%    <-------------D14-------->
%               <--D23-->
%               <-----24------>
%                        <-D34->
%
% La elección de estas longitudes hace que todos los Dij sean distintos

D12=0.5;
D13=0.8;
D14=0.9;
D23=D13-D12;
D24=D14-D12;
D34=D14-D13;

% Rango de frecuencias [GHz]
Fmax=40;
Fmin=0.5;
df=0.5;   %Precisión en frecuencia

% Rango de ángulo de incidencia [º]
tetamin=-90;
tetamax=90;
dteta=1;    % Precisión en ángulo

% 
%  Ángulos de inciencia por la izda son negativos. Ángulos 
%  por la derecha son positivos.
%
%  La ecuación de onda es 
%
% y(x,t)=A sin(2 pi* x/landa - 2 pi v t/landa)
%
% siendo landa la longitud de onda y v la velocidad de propagación de la 
% onda.
%
% f=v/landa
%
% En un istante dado t0, la diferencia de frecuencia instantánea
% entre un antena i a la izda y otra j a la derecha, separadas Dij
% viene dada por la expresión
% 
% dwij= 2 pi Dij*f/v * sin (teta)
%





