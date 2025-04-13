## -*- texinfo -*-##
##
## Wavelet_Db8
##
## Esta función retorna los coeficientes de la transformada wavelet de la señal
## de entrada x(n) de N muestras, para un nivel de descomposición M (M=0, 1, 2, ..).
##
## La wavelet utilizada es Daubechies 8.
##
## La función retorna los coeficientes de la transformada en un único vector.
## La longitud del vector de salida es idéntico al vector de entrada x(n),
## pero su interpretación debe hacerse del siguiente modo.
##
## Si se efectuan M niveles de descomposición la transformada tiene M+1 coeficientes,
## c0, c1, ..., CM.
##
## Si M>0, el coeficiente CM lo componen N/2 muestras. CM-1 tiene N/4 muestras, en general
## el coeficiente Cj, con j=0:M-1, tendrá N/2^(M-j)
##
## El vector de salida W=[CM CM-1 ...C2 C1 C0]
##
## Author: Dr. Carlos Romero Pérez
## Created: 2025-03-29
## Copyright (C) 2025 Zigor R&D AIE
##
## @deftypefn {} {@var{W} =} Wavelet_Db4 (@var{x}, @var{M})
## @end deftypefn

function W = Wavelet_Db8 (x, M)

  MAX_NIVELES=8;    % Máximo número de niveles de descomposición

  if (isnumeric(x)==false || isnumeric(M)==false)
    error("Los parámetros de entrada deben ser numéricos");
  endif

  if (isvector(x)==false)
    error("x debe ser un vector");
  endif

  if (isscalar(M)==false)
    error("M debe ser un escalar");
  endif

  M=round(M);

  if (M<=0)
    error("M debe ser un entero positivo");
  endif

  if (M>MAX_NIVELES)
    errormsg="El máximo número de niveles de descomposición es ";
    errormsg=cstrcat(errormsg,mat2str(MAX_NIVELES));
    error(errormsg);
  endif

  if (length(x)<2^(M-1))
    errormsg="La longitud del vector de entrada debe ser al menos ";
    errormsg=ctrscat(errormsg,mat2str(2^(M-1)));
    error(errormsg);
  endif


  % Coeficientes Daubechies Db4
  h0 =  0.0544158422;
  h1 =  0.3128715909;
  h2 =  0.6756307363;
  h3 =  0.5853546837;
  h4 = -0.0158291053;
  h5 = -0.2840155430;
  h6 =  0.0004724846;
  h7 =  0.1287474266;


  H=[h0 h1 h2 h3 h4 h5 h6 h7];
  G=[h7 -h6 h5 -h4 h3 -h2 h1 -h0];

  % Algoritmo

  itera=M;
  W=zeros(size(x));
  xaux=x;
  offset=0;

  while (itera>0)
    xlp=filter(H,1,xaux);
    xhp=filter(G,1,xaux);
    L=floor(length(xlp)/2);
    l=1:L;

    clear xlp2;
    clear xhp2;

    xlp2(l)=xlp(2*l-1);
    xhp2(l)=xhp(2*l-1);

    W(l+offset)=xhp2(l);
    xaux=xlp2;
    itera=itera-1;
    offset=offset+L;

  endwhile

  W(l+offset)=xaux(l);

endfunction
