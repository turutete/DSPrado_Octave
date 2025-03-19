## -*- texinfo -*-
##
##  Varc.m
##
##  Author: Dr. Carlos Romero P�rez
##  Date: 08/12/2024
##
##  Esta funci�n utiliza la ecuaci�n caracter�stica V-I de arco el�ctrico
##  propuesto en The Electric Arc as a Circuit Component. Johnathan Andrea.
##
##  Vt=(alfa*Rc*It)/(atan(beta*It)*It*Rc+alfa)
##
##  Los par�metros caracter�sticos del modelom alfa, Rc y beta est�n definidos
##  al inicio del fichero. No son par�metros de llamada a la funci�n.
##  
##  Para hacer otros ejemplos, hay que modificar estos par�metros
##
##  Vt: Tensi�n de arco
##  It: Corriente de arco
##   
## @deftypefn {} {@var{Vt} =} Varc (@var{It})
##
## @end deftypefn



function Vt = Varc (It)
  
  % Par�metros caracter�sticos del arco
  alfa=49.0874;
  beta=1.4614;
  Rc=2221;
  
  Vt=(alfa*Rc*It)/(atan(beta*It)*It*Rc+alfa);

endfunction
