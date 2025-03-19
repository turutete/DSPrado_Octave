## -*- texinfo -*-
##
##  Varc.m
##
##  Author: Dr. Carlos Romero Pérez
##  Date: 08/12/2024
##
##  Esta función utiliza la ecuación característica V-I de arco eléctrico
##  propuesto en The Electric Arc as a Circuit Component. Johnathan Andrea.
##
##  Vt=(alfa*Rc*It)/(atan(beta*It)*It*Rc+alfa)
##
##  Los parámetros característicos del modelom alfa, Rc y beta están definidos
##  al inicio del fichero. No son parámetros de llamada a la función.
##  
##  Para hacer otros ejemplos, hay que modificar estos parámetros
##
##  Vt: Tensión de arco
##  It: Corriente de arco
##   
## @deftypefn {} {@var{Vt} =} Varc (@var{It})
##
## @end deftypefn



function Vt = Varc (It)
  
  % Parámetros característicos del arco
  alfa=49.0874;
  beta=1.4614;
  Rc=2221;
  
  Vt=(alfa*Rc*It)/(atan(beta*It)*It*Rc+alfa);

endfunction
