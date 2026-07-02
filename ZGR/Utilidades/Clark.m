#
# Clark.m
#
# Esta función efectúa la transformada de Clark de 3 señales trifásicas
#
# Y= Clark(X)
#
# Donde X es una matriz [3 X 1] donde los elementos xi (i=1:3) son muestras
# en el instante 'n' de la señal xi(n) perteneciente a un sistema trifásico
#
# xi(n)= Xi cos(2 pi fred*n/Fs + phi - (i-1)*2pi/3)
#
# Y es la transformada de Clark, que es una matriz [3 X 1], siendo
#
# Y(1) la secuencia directa
# Y(2) la secuencia inversa
# Y(3) la componente homopolar
#
# La transformada de Clark es:
#
# Y = 2/3 [1 -1/2 -1/2;0 sqrt(3)/2 -sqrt(3)/2;1/2 1/2 1/2] * X
#

function Y=Clark(X)

  M=[1 -1/2 -1/2;0 sqrt(3)/2 -sqrt(3)/2;1/2 1/2 1/2];

  if (isnumeric(X)==false)
    error("X debe ser numérico");
  endif

  [fil,col]=size(X);

  if (fil!=3 || col!=1)
    if (fil!=1 || col!=3)
      error("X debe ser una matriz 3 x 1");
    else
      X=X';
    endif

  endif

  Y=M*X;

endfunction
