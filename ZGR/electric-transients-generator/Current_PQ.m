## -*- texinfo -*-
##
##  Current_PQ.m
##
##  Esta funci�n genera la se�al de corriente i(t) correspondiente
##  a una l�nea el�ctrica trif�sica sometida a una tensi�n v(t) y por
##  la que se inyecta una potencia activa P y una reactiva Q.
##
##  La generaci�n de la se�al se hace de forma aproximada, suponiendo
##  que el arm�nico de mayor amplitud de la FFT de la se�al de tensi�n
##  es la correspondiente a la frecuencia de red.
##
## La componente espectral de la se�al de corriente se obtiene como
##
## I=conj(S)/abs(V)^2 *V
##
## siendo V la componente espectral de la tensi�n y S=P+jQ.
##
## La se�al de salida se obtiene como la IFFT del espectro calculado.
##
## Esta operaci�n se realiza para las 3 fases.
##
##  I: Es una matriz 3 X N, siendo N el n�mero de muestras de la se�al de tensi�n
##    La fila 1 es la corriente de fase Ir, la fila 2 Is y la fila 3 It
##  V: Tensi�n trif�sica Vr, Vs, Vt. Es una matriz 3 X N
##  P: Valor de potencia activa, en W, inyectada en la l�nea.
##  Q: Valor de potencia reactiva, en VA, inyectada en la l�nea
##
## @deftypefn {} {@var{I} =} Current_PQ (@var{V}, @var{P}, @var{Q})
##
## Author: Dr. Carlos Romero P�rez <cromero@@zigor.com>
## Created: 2024-11-01
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn


function I = Current_PQ (V,P,Q)
  
  if ( isnumeric(V)==false || isnumeric(P)==false || isnumeric(Q)==false)
    error("Los par�metros de entrada deben ser num�ricos");
  endif
  
  if( ismatrix(V)==false )
    error("El par�metro V debe ser una matriz 3 X N");
  endif
  
  if P<0
    error("La potencia activa debe ser positiva");
  endif
  
  [fila,N]=size(V);
  
  if fila!=3
    error("El par�metro V debe ser una matriz 3 X N");
  endif
 
  VR=fft(V(1,:)*2/N);
  VS=fft(V(2,:)*2/N);
  VT=fft(V(3,:)*2/N);
  
  M=round(N/2);
  
  q=1:M;
  
  [VRmax,indr]=max(abs(VR(q)));
  [VSmax,inds]=max(abs(VS(q)));
  [VTmax,indt]=max(abs(VT(q)));
  
  q=(M+1):N;
  
  [Vdummy,indr2]=max(abs(VR(q)));
  [Vdummy,inds2]=max(abs(VS(q)));
  [Vdummy,indt2]=max(abs(VT(q)));
  
  indr2=indr2+M;
  inds2=inds2+M;
  indt2=indt2+M;
  
  
  Sconj=P-j*Q;
  
  IR=(Sconj/VRmax^2)*VR(indr);
  IS=(Sconj/VSmax^2)*VS(inds);
  IT=(Sconj/VRmax^2)*VT(indt);
  
  %S�ntesis de se�ales de corriente
  Ir=zeros(1,N);
  Is=zeros(1,N);
  It=zeros(1,N);
  
  Ir(indr)=IR;
  Ir(indr2)=conj(IR);
  Is(inds)=IS;
  Is(inds2)=conj(IS);
  It(indt)=IT;
  It(indt2)=conj(IT);
  
  ir=real(ifft(Ir*N/2));
  is=real(ifft(Is*N/2));
  it=real(ifft(It*N/2));
  
  I=[ir;is;it];
  

endfunction
