## -*- texinfo -*-
##
## Arc_Generator.m
##
## Esta función genera las señales de tensión y corriente de arco eléctrico
## al aplicar una diferencia de potencial V entre dos conductores, separados una
## distancia, en un medio aislante.
##
## El tiempo que tarda en formarse el canal de descarga es tau.
##
## Los parámetros característicos del medio aislante, que definen su
## comportamiento estático Vt-It son Rc, alfa y beta, de acuerdo con el modelo
## propuesto por Jonathan Andrea, "The Electric Arc as a Circuit Component".
##
##
## @seealso{https://www.researchgate.net/publication/295251575}
## @deftypefn {@var{VIarc} =} Arc_generator (@var{V}, @var{Rc}, @var{alfa}, @var{beta}, @var{tau}, @var{Rl}, @var{Fs} )
##
## V: Es el vector V(n), diferencia de potencial entre conductores [1 x N]
## Rc: Resistencia del arco en la fase de descarga luminiscente [1x1]
## alfa: Coeficiente del modelo característico del medio [1x1]
## beta: Coeficiente del modelo característico del medio [1x1]
## tau: Tiempo de formación del canal de descarga [1x1]
## Rl: Resistencia del circuito de descarga [1x1]
## VIarc: Matriz 2 X N donde VIarc(1,:) es la tensión del arco Varc(n) y VIarc(2,:)
##        es la corriente del arco Iarc.
##
## Author: Dr. Carlos Romero
## Created: 2024-12-14
## Copyright (C) 2024 Zigor R&D AIE
## @end deftypefn

function VIarc = Arc_Generator (V,Rc,alfa,beta,tau,Rl,Fs)

  % Parámetros
  Itmax=100;      % Corriente máxima curva [A]
  Fs=12500;       % Frecuencia de muestreo [Hz]
  deltaI=0.1;     % Precisión de amplitud en corriente [A]


  % Validación de parámetros de entrada
  if(isnumeric(V)==false || isnumeric(Rc)==false || isnumeric(alfa)==false || isnumeric(beta)==false || isnumeric(tau)==false || isnumeric(Rl)==false || isnumeric(Fs)==false)
   error("Los parámetros de entrada deben ser numéricos");
  endif

  if(isvector(V)==false || isscalar(V)==true)
    error("V debe ser un vector");
  endif

  if(isscalar(Rc)==false||isscalar(alfa)==false||isscalar(beta)==false||isscalar(tau)==false||isscalar(Rl)==false||isscalar(Fs)==false)
    error("Todos los parámetros, excepto V, deben ser escalares");
  endif

  if(Rl<=0 || alfa<0 || beta<0 || tau<0 || Fs<=0)
    error("Los parámetros de entrada escalares deben ser mayor que cero");
  endif


  [fil, col]=size(V);
  if fil>col
    V=V';
   endif

   N=max(fil,col);
   NI=round(Itmax/deltaI);

   q=-NI:(NI-1);

   It=q*deltaI;
   Vt=(alfa*Rc.*It)./(atan(beta.*It)*Rc.*It+alfa);


   % Cálculo de puntos de trabajo posibles
   for n=1: N
     % Recta de Carga
     Vcarga=V(n)-Rl*It;
     cortes=Puntos_Corte(Vt,Vcarga);

     if (n==1)
       % El primer punto se supone estable. El punto es el de mayor corriente
       [fil,col]=size(cortes);

       Itreal(n)=(cortes(fil,1)-NI-1)*deltaI;
       Vtreal(n)=cortes(fil,2);
       P1=Itreal(n)*Vtreal(n);
     endif

     if(n>1)
      [fil,col]=size(cortes);

      % Cálculo de potencias
      clear DifP;
      for q=1:fil
        Vnew=cortes(q,2);
        Inew=(cortes(q,1)-NI-1)*deltaI;
        DifP(q)=abs((Vnew*Inew)-P1);
      endfor
      % Selección del nuevo punto de trabajo
      [difpmin,indmin]=min(DifP);
      Vtreal(n)=cortes(indmin,2);
      Itreal(n)=(cortes(indmin,1)-NI-1)*deltaI;
      P1=Itreal(n)*Vtreal(n);
     endif

   endfor

  t=1:N;

  figure(1); plot((t-1)/Fs,Vtreal);
  figure(2);plot((t-1)/Fs,Itreal);

  VIarc=[Vtreal;Itreal];

endfunction
