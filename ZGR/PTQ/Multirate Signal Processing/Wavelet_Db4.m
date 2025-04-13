## -*- texinfo -*-##
##
## Wavelet_Db4
##
## Esta funci�n retorna los coeficientes de la transformada wavelet de la se�al
## de entrada x(n) de N muestras, para un nivel de descomposici�n M (M=0, 1, 2, ..).
##
## La wavelet utilizada es Daubechies 4.
##
## La funci�n retorna los coeficientes de la transformada en un �nico vector.
## La longitud del vector de salida es id�ntico al vector de entrada x(n),
## pero su interpretaci�n debe hacerse del siguiente modo.
##
## Si se efectuan M niveles de descomposici�n la transformada tiene M+1 coeficientes,
## c0, c1, ..., CM.
##
## Si M>0, el coeficiente CM lo componen N/2 muestras. CM-1 tiene N/4 muestras, en general
## el coeficiente Cj, con j=0:M-1, tendr� N/2^(M-j)
##
## El vector de salida W=[CM CM-1 ...C2 C1 C0]
##
## Author: Dr. Carlos Romero P�rez
## Created: 2025-03-25
## Copyright (C) 2025 Zigor R&D AIE
##
## @deftypefn {} {@var{W} =} Wavelet_Db4 (@var{x}, @var{M})
## @end deftypefn

function W = Wavelet_Db4 (x, M)

  MAX_NIVELES=8;    % M�ximo n�mero de niveles de descomposici�n

  if (isnumeric(x)==false || isnumeric(M)==false)
    error("Los par�metros de entrada deben ser num�ricos");
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
    errormsg="El m�ximo n�mero de niveles de descomposici�n es ";
    errormsg=cstrcat(errormsg,mat2str(MAX_NIVELES));
    error(errormsg);
  endif

  if (length(x)<2^(M-1))
    errormsg="La longitud del vector de entrada debe ser al menos ";
    errormsg=ctrscat(errormsg,mat2str(2^(M-1)));
    error(errormsg);
  endif

  % Coeficientes Daubechies Db4

  h0=(1+sqrt(3))/(4*sqrt(2));
  h1=(3+sqrt(3))/(4*sqrt(2));
  h2=(3-sqrt(3))/(4*sqrt(2));
  h3=(1-sqrt(3))/(4*sqrt(2));

  H=[h0 h1 h2 h3];
  G=[h3 -h2 h1 -h0];

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
