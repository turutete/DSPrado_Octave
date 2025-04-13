## -*- texinfo -*-##
##
## Bank_Lagrange
##
## Esta funci�n retorna las se�ales resultantes de utilizar la descomposici�n
## de una se�al de entrada x(n) de N muestras mediante un banco de filtros
## miltitasa, siendo el filtro de an�lisis un filtro half band de Lagrange,
## y el filtro HP su conjugado.
##
## Los par�metros de entrada son:
##
## x: Es la se�al de entrada x(n)
## M: Es el nivel de descomposici�n
## R: Es el n�mero de coeficientes del filtro hanf band distinto de cero. El
##    orden del filtro es 4*R-2
##
## La funci�n retorna las secuencias de salida de cada nivel de descomposici�n
## en un �nico vector.
## La longitud del vector de salida es id�ntico al vector de entrada x(n),
## pero su interpretaci�n debe hacerse del siguiente modo.
##
## Si se efectuan M niveles de descomposici�n la salida tiene M+1 se�ales,
## c0, c1, ..., CM.
##
## Si M>0, la se�al CM la componen N/2 muestras. CM-1 tiene N/4 muestras, en general
## la se�al Cj, con j=0:M-1, tendr� N/2^(M-j)
##
## El vector de salida W=[CM CM-1 ...C2 C1 C0]
##
## Author: Dr. Carlos Romero P�rez
## Created: 2025-04-01
## Copyright (C) 2025 Zigor R&D AIE
##
## @deftypefn {} {@var{W} =} Bank_Lagrange (@var{x}, @var{M}, @var{R})
## @end deftypefn

function W = Bank_Lagrange (x, M, R)

  MAX_NIVELES=8;    % M�ximo n�mero de niveles de descomposici�n

  if (isnumeric(x)==false || isnumeric(M)==false || isnumeric(R)==false)
    error("Los par�metros de entrada deben ser num�ricos");
  endif

  if (isvector(x)==false)
    error("x debe ser un vector");
  endif

  if (isscalar(M)==false || isscalar(R)==false )
    error("M y R deben ser escalares");
  endif

  M=round(M);
  R=round(R);

  if (M<=0 || R<=0)
    error("M y R deben ser enteros positivos");
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


  % Coeficientes Filtro Half Band de Lagrange
  H=lagrange_halfband(R);

  L=length(H);

  for i=1:L
    G(i)=(-1)^(L-i+1)*H(L-(i-1));
  endfor

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
