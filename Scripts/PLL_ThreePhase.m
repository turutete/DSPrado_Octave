%
% PLL_ThreePhase.m
%
% Autor: Dr. Carlos Romero
%
% Descripción:
% ------------
%
% Este script implementa, y permite simular, un PLL digital para
% sistemas de generación trifásico, en el que la señal de tensión
% trifásica generada debe estar en fase con la señal de red.
%
% El script está basado en el documento [1].
%
% Bibliografía:
%
% [1] https://www.ti.com/lit/sprabt4
%
% Historial de cambios
%
% 12/03/2022: Primera versión.    Dr. Carlos Romero
%
% This program is free software: you can redistribute it and/or modify it
% under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
%(at your option) any later version.
% 
% This program is distributed in the hope that it will be useful, but
% WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see
% <https://www.gnu.org/licenses/>.

% Explicación Técnica
% -------------------
%
% En [1] se explica cómo la señal vq(t), que es la componente en cuadratura
% obtenida al efectuar las transformadas de Clarke y Park a la señal 
% trifásica Va(t), Vb(t) y Vc(t), es proporcional al error de fase
%
% Vq(t) = Vgrid*(teta_grid(t) - teata_pll(t)
%
% La señal Vq(t) es la función de error, que se quiere minimizar a 0.
% Esta señal de error es la entrada a un PI en cascada con un VCO
%
% Vq(t)--->(Kp+Ki/s)-->(+)-->(1/s)----(sin())-->
%                       ^           |-(cos())-->
%                       |Fn                   |
%                                             |
%   cos(teta_pll(t)) <-------------------------
%   sin(teta_pll(t)) <------------------------|
%
%        TETA_pll(s)     (Kp s + Ki)* Vgrid
% H0(s)=------------- = ----------------------------
%        TETA_grid(s)    s^2 + Kp Vgrid s + Ki Vgrid
%
% Si llamamos:
%   Ki=Kp/Ti
%   Wn^2= Kp/Ti Vgrid
%   chi=sqrt(Ti*Vgrid*Kp/4)
%
%        2*chi*Wn*s+ Wn^2
% H0(s)= ---------------------
%         s^2+2*chi*Wn*s+Wn^2
%
% Lo pasamos a discreto H(z) haciendo s=2/T ((z-1)/(z+1)), T=tiempo muestreo.
%
%      B2 z^-2 + B1 z^-1 + B0
% H(z)=----------------------
%       z^-2 + A1 z^-1 + A0
%
% Den(z)=4-4 chi Wn + Wn^2 T^2
% B2=(T^2 Wn^2 - 4 chi Wn T)/Den(z)
% B1=(2 T^2 Wn^2)/Den(z)
% B0=(4 chi Wn T + T^2 Wn^2)/Den(z)
% A1=(2 Wn^2 T^2 - 8)/Den(z)
% A0=(4 + 4 chi Wn^2 + Wn^2 T^2)/Den(z)
%
% teta_pll(n)= B0 Vq(n)+B1 Vq(n-1) + B2 Vq(n-1)-A1 teta_pll(n-1)-A2 teta_pll(n-2)
%
% 

% Condiciones iniciales aleatorias
phi_red=2*pi*randn();   % Desfase inicial de la señal de red es aleatorio
phi_pll=2*pi*randn();   % Desfase inicial del pll aleatorio
df_red=0.001*randn();   % Error de frecuencia señal red arbitario <=1mHz
df_pll=0.005*randn();   % Error de frecuencia oscilador pll aleaorio <=5mHz

% Condiciones de red no aleatorias, aunque podrán serlo. Amplitud tras ADC
Vred=1/1.2;   % Ajustamos para que el Vmax=1 es 20% de sobretensión.
fred_teo=50;  % Ejemplo a 50Hz de red
fpll_teo=fred_teo;  % Se supone que el equipo está configurado correctamente

% Diseño del PLL
Mp=1;         % Máximo overshoot en %

