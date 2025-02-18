function filt_data= zgr_lp_prueba1(xin)
%
% Filtro LP usado en TPS500 para filtrar la medida de tensión Vdc
%
L=length(xin);
  
x0=0;
y0=0;
x1=0;
y1=0;
x2=0;
y2=0;
    
filt_data=zeros(size(xin));

% Coeficientes para un filtro eliptico de segundo orden con fpasobanda = 10kHz fs=400kHz (a0 = 1.0)

b0= 0.1274456288638496;
b1=-0.02366227031208316;
b2=0.1274456288638496;
a1=-1.272082627221519;
a2=0.505989120120477;

for l=1:L
  x0 = xin(l);
  y0 = x0*b0 + x1*b1+x2*b2- y1*a1-y2*a2;
  filt_data(l) =y0;

  x2=x1;
  x1=x0;
  y2=y1;
  y1=y0;
  
endfor

endfunction