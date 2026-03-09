#
# Clark_Secuencia.m
#
# Esta función calcula la transformada de Clark de 3 secuencias trifásicas.
#
# Y=Clark_Secuencia(X)
#
# Siendo X una matriz 3 X N, donde cada fila de la matriz X es una de las
# señales trifásicas, siendo N el número de muestras
#
# Y es una matriz 3 X 1, donde la fila 1 es la componente alpha, la segunda es
# la componente beta y la tercera la homopolar.
#


function Y=Clark_Secuencia(X)

  [fil,L]=size(X);

  Y=zeros(3,L);

  for n=1:L
    yaux=Clark([X(1,n);X(2,n);X(3,n)]);
    Y(1,n)=yaux(1);
    Y(2,n)=yaux(2);
    Y(3,n)=yaux(3);
  endfor

endfunction
