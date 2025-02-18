##
##  Calcula_HPI
##
## Prototipo: Y = Calcula_HPI(Fs, F0, x1, x2, x3)
##
##  x1(n), x2(n) y x3(n) son 3 señales que forman un sistema trifásico.
##
##  Fs es la frecuencia de muestreo, y F0 es la frecuencia fundamental.
##
##  Y = [yh(n) yp(n) yn(n)]'
##
##  yh(n) es la secuencia homopolar
##  yp(n) es la secuencia directa
##  yn(n) es la secuencia inversa
##
## Copyright (C) 2022 Usuario
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.
## Author: Dr. Carlos Romero
## Created: 2022-04-06

function retval = Calcula_HPI (Fs, F0, input1, input2, input3)

pkg load signal;

L=min(length(input1),length(input2),length(input3));

n=1:L;
x1(n)=input1(n);
x2(n)=input2(n);
x3(n)=input3(n);

K=Fs/(2*pi*F0);

Kalfa=K*sin(2*pi/3);
Kalfa2=K*sin(4*pi/3);

Ralfa=[Kalfa+cos(2*pi/3) -Kalfa];
Ralfa2=[Kalfa2+cos(4*pi/3) -Kalfa2];

r2=filter(Ralfa,1,x2);
r3=filter(Ralfa,1,x3);
y2=filter(Ralfa2,1,x2);
y3=filter(Ralfa2,1,x3);

yh=1/3*(x1+x2+x3);
yp=1/3*(x1+y2+r3);
yn=1/3*(x1+r2+y3);

yh(1)=0;
yp(1)=0;
yn(1)=0;

retval=[yh;yp;yn];


endfunction
