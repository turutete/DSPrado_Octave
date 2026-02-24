
## Puntos_Corte.m
##
## retval = Puntos_Corte (input1, input2)
##
## Esta función admite como parámetros de entrada 2 secuencias, input1 e
## input2. Ambas secuencias deben ser numericas de igual longitud.
##
## Esta función detecta los índices en el que ambas secuencias tienen cruces
## por cero.
##
## input1: Secuencia numérica 1 1 X L
##
## input2: Secuencia numérica 2 1 X L
##
## retval: Vector 1 X C de índices de corte, siendo C el número de puntos de
##          corte entre ambas secuencias. Si es [], no tienen puntos de corte.
##



function retval = Puntos_Corte (input1, input2)

  if (isnumeric(input1)==false || isnumeric(input2)==false)
    error("Los vectores de entrada deben ser numéricos");
  endif

  if ( isvector(input1)==false || isvector(input2)==false)
    error("Los parámetros de entrada deben ser vectores");
  endif

  if (length(input1)!=length(input2))
    error("Los vectores de entrada deben ser de la misma longitud");
  endif

  % Cálculo rápido puntos corte
  retval=[];
  F=input2-input1;
  L=length(F);
  cross=[];
  indcross=1;

  ind=1;
  flag=0;
  signoprev=sign(F(1));

  while (flag==0)
    signo=sign(F(ind));
    if (signo==0)
      cross(indcross)=ind;
      indcross=indcross+1;
      signoprev=signo;
    else
      if (signo!=signoprev && signoprev!=0)
        y1=input1(ind-1);
        y2=input1(ind);
        g1=input2(ind-1);
        g2=input2(ind);
        x=(ind-1)+(y1-g1)/(g2-g1-y2+y1);
        cross(indcross)=x;
        signoprev=signo;
        indcross=indcross+1;
      else
        signoprev=signo;
      endif
    endif

    ind=ind+1;

    if (ind>L)
      flag=1;
    endif

  endwhile

  retval=cross;

endfunction
