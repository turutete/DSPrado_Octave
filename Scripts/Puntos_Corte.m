## -*- texinfo -*- 
##
## Puntos_Corte.m
##
## Esta funci�n admite como par�metros de entrada 2 secuencias, input1 e
## input2. Ambas secuencias deben ser numericas de igua longitud.
##
## Esta funci�n detecta los �ndices en el que ambas secuencias tienen cruces 
## por cero.
##
## input1: Secuencia num�rica 1 1 X L
## input2: Secuencia num�rica 2 1 X L
## retval: Vector 1 X C de �ndices de corte, siendo C el n�mero de puntos de
##          corte entre ambas secuencias. Si es [], no tienen puntos de corte.
##
## Author: Dr. Carlos Romero
## Created: 2024-12-26
## 
## -*- texinfo -*- 
## @deftypefn {} {@var{retval} =} Puntos_Corte (@var{input1}, @var{input2})
##
## Copyright (C) 2024 ZGR R&D AIE
## @end deftypefn



function retval = Puntos_Corte (input1, input2)
  
  if (isnumeric(input1)==false || isnumeric(input2)==false)
    error("Los vectores de entrada deben ser num�ricos");
  endif
  
  if ( isvector(input1)==false || isvector(input2)==false)
    error("Los par�metros de entrada deben ser vectores");
  endif
  
  if (length(input1)!=length(input2))
    error("Los vectores de entrada deben ser de la misma longitud");
  endif
  
  % C�lculo r�pido puntos corte
  retval=[];
  F=input2-input1;
  L=length(F);
  F2=[F(1)^2 F(1:L-1).*F(2:L)];
  index_cross=find(F2<0);
  
  veces=length(index_cross);
  index=1;
  
  while veces>0
    y1=input1(index_cross(index)-1);
    y2=input1(index_cross(index));
    g1=input2(index_cross(index)-1);
    g2=input2(index_cross(index));
    
    x=index_cross(index)+(y1-g1)/(g2-g1-y2+y1);
    
    retval(index)=x;
    index=index+1;
    veces=veces-1;
  endwhile
  
endfunction
