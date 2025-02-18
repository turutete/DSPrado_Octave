## -*- texinfo -*-
##
##  Puntos_Corte.m
##
## Esta función tiene como parámetros de entrada 2 señales temporales, x1(n)
## y x2(n) de longitud arbitraria pero iguales.
##
## La función calcula los puntos de interescción entre ambas señales,
## devolviendo una matriz Cx2, siendo cada fila el punto (y,x) de intersección.
##
## Si ambas secuencias no se cortan en ningún punto, la función retorna -1.
##
## @deftypefn {} {@var{retval} =} Puntos_Corte (@var{input1}, @var{input2})
##
## Copyright (C) 2024 Zifor R&D AIE
## Author: Dr. Carlos Romero
## Created: 2024-12-15
## @end deftypefn

function retval = Puntos_Corte (input1, input2)
  
  % Validaciones
  if(isnumeric(input1)==false || isnumeric(input2)==false)
    error("Las secuencias de entrada deben ser numéricas");
  endif
  
  if(isvector(input1)==false || isvector(input2)==false)
    error("Las secuencias de entrada deben ser vectores");
  endif
  
  if (size(input1)!=size(input2))
    error("La lingitude de ambas secuencias de entrada debe ser igual");
  endif
  
  % Algoritmo
  N=length(input1);
  retval=[];
  index=1;
  estado=0;
  flag_cross=0;
    
  while (index<=N)    
    switch (estado)
      case {0}
        if (input1(index)==input2(index))
          retval=[retval;[index input1(index)]];
        elseif (input1(index)>input2(index))
          estado=1;
        else
          estado=-1;
        endif
      case{1}
        if (input1(index)<input2(index))
          estado=-1;
          flag_cross=1;
        endif
           
        if (input1(index)==input2(index))
          estado=0;
          retval=[retval;[index input1(index)]];
        endif 
      case {-1}
         if (input1(index)>input2(index))
          estado=1;
          flag_cross=1; 
         endif
           
         if (input1(index)==input2(index))
          estado=0;
          retval=[retval;[index input1(index)]];
         endif        
    endswitch
    
    if (flag_cross==1)
      flag_cross=0;
      x1=index-1;
      y1=input1(index-1);
      ya=input1(index);
      y2=input2(index-1);
      yb=input2(index);
      
      xc=x1+(ya-y1)/(y2+ya-y1-yb);
      yc=y1+(xc-index+1)*(y2-y1);
      retval=[retval;[xc yc]];
    endif
    index=index+1;
  endwhile 
  if (size(retval)==[0 0])
    retval=-1;
  endif

endfunction
