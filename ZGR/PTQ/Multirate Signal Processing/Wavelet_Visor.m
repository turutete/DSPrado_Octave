## -*- texinfo -*-
##
##  Wavelet_Visor
##
## Esta funci�n representa los coeficientes wavelets suministrados en forma
## de vector de entrada W, obtenidos mediante una transformada de M niveles
## (M=1, 2, ...). Siendo la frecuencia de muestreo original de la se�al Fs.
##
## El visor muestra la representaci�n de los coeficientes en gr�ficos independientes.
##
## Copyright (C) 2025 Zigor R&D AIE
##
## @deftypefn {} Wavelet_Visor (@var{W}, @var{Fs}, @var{M})
##
## @end deftypefn
##
## Author: Dr. Carlos Romero P�rez
## Created: 2025-03-29

function Wavelet_Visor (W, Fs, M)

  if (isnumeric(W)==false || isnumeric(Fs)==false || isnumeric(M)==false)
    error ("Los par�metros de entrada deben ser num�ricos");
  endif
  M=floor(M);

  if (Fs<=0 || M<=0)
    error ("La frecuencia de muestreo Fs y el n�mero de niveles M deben ser positivos");
  endif

  if (isvector(W)==false)
    error("El par�metros de entrada W debe ser un vector de coeficientes Wavelets");
  endif

  L=length(W);

  filas=M+1;
  columnas=floor(L/2);
  offset=0;
  nivel=0;
  N=columnas;
  R=zeros(filas,columnas);

  while (nivel<M)
    n=1:N;
    R(M+1-nivel,n)=W(offset+n);
    nivel=nivel+1;
    offset=offset+N;
    if (nivel<M)
      N=floor(N/2);
    endif
  endwhile

  R(1,n)=W(offset+n);

  % Representaci�n
  N=floor(L/2^M);
  n=1:N;
  fs=Fs/2^M;
  figure(1);
  plot(n/fs,R(1,n));
  fini=0;
  fnext=fs/2;

  titulotxt=strcat("W",mat2str(0,0)," Fini[Hz]=",mat2str(fini,8)," Ffin[Hz]= ",mat2str(fnext,8));
  xlabel('t[s]');ylabel('W');title(titulotxt);

  fini=fnext;
  fnext=fnext*2;

  for f=2:filas
    figure(f);
    plot(n/fs,R(f,n));

    titulotxt=strcat("W",mat2str(f-1,0)," Fini[Hz]=",mat2str(fini,8)," Ffin[Hz]= ",mat2str(fnext,8));
    xlabel('t[s]');ylabel('W');title(titulotxt);

    fini=fnext;
    fnext=fnext*2;

    fs=2*fs;
    N=2*N;
    n=1:N;

  endfor

endfunction
