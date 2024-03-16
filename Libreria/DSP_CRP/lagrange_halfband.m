##
## lagrange_halfband.m
##
## Prototipo: h0= lagrange_halfband(m)
##
## Esta función retorna los coeficientes del filtro de media banda
##             m
## H0(z)=1/2+ Sum hm(2n-1) (z^(-2n+1) + z^(2n-1))
##             n=1
##
## siendo 
##                                                 2m
##  hm(2n-1)=(-1)^(n+m-1)/((m-n)!(m-1+n)!(2n-1))*PROD(m-k+1/2)
##                                                 k=1
##
## El orden del filtro es 4*m-2. Es decir, son 4m-1 coeficientes
##
## Copyright (C) 2024 Dr. Carlos Romero
## 
## Author: Dr. Carlos Romero
## Created: 2024-02-25

function h0 = lagrange_halfband (m)
  
    
  orden=4*m-1;
  
  h0=zeros(1,orden);
  h0(2*m)=1/2;
  
  for l=1:m
    productorio=1;
    for k=1:2*m
      productorio=productorio*(m-k+1/2);
    endfor
    
    hm=(-1)^(l+m-1)/(factorial(m-l)*factorial(m-1+l)*(2*l-1))*productorio;
    h0(2*m+(2*l-1))=hm;
    h0(2*m-(2*l-1))=hm;
  endfor
  

endfunction
