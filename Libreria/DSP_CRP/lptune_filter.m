function [B,A]=lptune_filter(Fp,Fs)
##
##  lptune_filter.m
##
##  Author: Dr. Carlos Romero Pérez
##
##  [B,A]=lptune_filter(Fp,Fs)
##
##  Fp: Analog pass band frequency (Hz)
##  Fs: Sampling frequecy (Hz)
##  [B,A]: Numerator (B) and denominator (A) coefficients of the IIR filter
##
##  Description
##  ===========
##  This function computes the IIR elliptic filter coefficients, with pass band
##  Fp, using as sampling frequency Fs.
##
##  It's used the frequency transformation [1]. An elliptic filter LP prototype
##  order N=5, bandpass frequency 0.25, bandpass ripple 0.01, and -40dB
##  attenuation is used.
##
##  The sustitution z^-1 -> (z^-1 - alpha)/(1 - alpha z^-1) in the H(z) is done,
##  being alpha=(sin((Wpro-Wtar)/2)/sin((Wpro+Wtar)/2)
##
##  Wpro= Digital cutoff frequency of the prototype filter [0 pi]
##  Wtar= Digital cutoff frequency of the target LP fiter [0 pi]
##
##  The digital cutoff frequency of the prototype is Wpro=0.25.
##
##  The N=5 order filter is implemented as a cascade of two second order filters
##  and a single order IIR filter with real zero and pole. The frequency
##  transformation is done in each of these filters. The Contastinide's 
##  equations are:
##  
##  Biquads:
##
##        b0 + z^-1 b1 + z^-2 b2            B0 + z^-1 B1 + z^-2 B2
##  H(z)= ----------------------    Ht(z)=  ----------------------
##        a0 + z^-1 a1 + z^-2 a2            A0 + z^-1 A1 + z^-2 A2
##
##  B0=b0- alpha b1+alpha^2 b2          A0=a0- alpha a1+alpha^2 a2
##  B1=(alpha^2+1) b1 - 2 alpha (b0+b2) A1=(alpha^2+1) a1 - 2 alpha (a0+a2)
##  B2= alpha^2 b0 - alpha b1 + b2      A2= alpha^2 a0 - alpha a1 + a2
##
##  1st order IIR:
##
##        b0 + z^-1 b1                        B0 + z^-1 B1
##  H(z)= ------------                Ht(z)=  ------------
##        a0 + z^-1 a1                        A0 + z^-1 A1
##
##  B0= b0- alpha b1                  A0= a0 - alpha a1
##  B1= b1 - alpha b0                 A1= a1 - alpha a0
##
##  
##
##  Reference
##  =========
##  [1] Spectral transformation for digital filters. Proceedigs IEE Vol 117,
##      Num 8. A.G. Constantinides. 1970.
##  Logger
##  ======
##  23/08/2020: First edition
##  
## Copyright (C) 2020
## 
## This program is free software: you can redistribute it and/or modify it
## under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
## 
## This program is distributed in the hope that it will be useful, but
## WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
## 
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see
## <https://www.gnu.org/licenses/>.

pkg load signal;
# Checking the correctness of input arguments
if Fp<=0 || Fs<=0
  error("Input arguments must be positive and non zero");
endif

if length(Fp)>1 || length(Fs)>1
  error("Input arguments must be scalars");
endif

if imag(Fp)!=0 || imag(Fs)!=0
  error("Input arguments must be real");
endif

if Fp*2>Fs
  error("Nyquist criteria is not met");
endif

# Filter prototype
fp=0.25;
Norder=5;
Rp=20*log10(abs(1.01));
Rs=-20*log10(abs(0.01));

[Bp,Ap]=ellip(Norder,Rp,Rs,fp);
[Hp,W]=freqz(Bp,Ap,1024);
figure(1);
plot(W/pi,20*log10(abs(Hp)));grid;xlabel("fdigital");ylabel("Hp(f) dB");
title("Prototype filter");

##  Cascade implementation
bp0=Bp(1);
ap0=Ap(1);
Z=roots(Bp);
P=roots(Ap);

N1=bp0*[1 -Z(1)];
D1=ap0*[1 -P(5)];

N2=conv([1 -Z(2)],[1 -Z(3)]);
D2=conv([1 -P(1)],[1 -P(2)]);

N3=conv([1 -Z(4)],[1 -Z(5)]);
D3=conv([1 -P(3)],[1 -P(4)]);

# Transformation
Wpro=pi*fp;
Wtar=Fp*pi*2/Fs;

alpha=sin((Wpro-Wtar)/2)/sin((Wpro+Wtar)/2);

Mb=[1 -alpha alpha^2;-2*alpha alpha^2+1 -2*alpha;alpha^2 -alpha 1];
Mo1=[1 -alpha;-alpha 1];

Nt1=(Mo1*N1')';
Dt1=(Mo1*D1')';
Nt2=(Mb*N2')';
Dt2=(Mb*D2')';
Nt3=(Mb*N3')';
Dt3=(Mb*D3')';

B=conv(Nt1,conv(Nt2,Nt3));
A=conv(Dt1,conv(Dt2,Dt3));

[H,W]=freqz(B,A,1024);

figure(2);
plot((W*Fs)/(2*pi),20*log10(abs(H)));grid;xlabel("f [Hz]");ylabel("H(f) dB");
title("Required filter");

endfunction
