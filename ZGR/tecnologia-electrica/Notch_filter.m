##
## Notch_Filter.m
##
## Prototipo: [B,A]=Notch_filter(F0,B,Fs)
##
## Esta función calcula los coeficientes del filtro Notch centrado en la
## frecuencia F0, con ancho de banda B, muestreando a Fs.
##
## La salida [B,A] son los coeficientes del numerador (B) y del denominador (A)
##
## Copyright (C) 2023 ZGR R&D
##
## Author: Carlos Romero
## Created: 2023-07-20

function [B,A] = Notch_filter (F0, B, Fs)
 
 % The digital all pass filter. Regaila, Mitra and Vaidyanathan
 
  w0=2*pi*F0/Fs;
  B2=2*pi*B/Fs;
  
  k1=-cos(w0);
  k2=(1-tan(B2/2))/(1+tan(B2/2));
  
  An=[k2 k1*(1+k2) 1];
  Ad=[1 k1*(1+k2) k2];
  
    
  B=1/2*(Ad+An);
  A=Ad;
  
endfunction
