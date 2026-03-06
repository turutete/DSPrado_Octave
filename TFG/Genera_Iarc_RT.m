##
## Genera_Iarc_RT.m
##
## function iarco= Genera_Iarc_RT(V,Fs)
##
## Esta función utiliza el modelo de arco eléctrico de Jonathan Andrea
## en ResearchGate
##
## https://www.researchgate.net/publication/295251575
##
## La función utiliza como parámetros de entrada la muestra V(n) de la tensión
## en el conductor y la frecuencia de muestreo Fs
##
## Devuelve iarco que es la corriente del arco en el instante n
##
## Para resolver los puntos de corte de la recta de carga Vt=Vg-Rl*Id
## con la ecuación estática V-I del arco, al ser una curva con pendientes
## muy grandes cernano a cero y pendientes casi cero en la zona estable,
## se resuelve de forma aproximada:
##
## Se comprueba si la recta de carga tiene 1, 2 ó 3 cortes
##
## Si tiene un punto de corte, este punto estará en la zone Vt=V0.
## por lo que It=(V(n)-V0)/Rl
##
## Si tiene 2 puntos de corte, el primer punto será +/-(Vd,Id) y otro punto
## It=(V(n)-V0)/Rl
##
## Si tiene 3 puntos, el primero debe de estar en la interseción  de las
## rectas Vt=Vg-It Rl  y Vt=Rc It. Es decir It=Vg/(Rl+Rc)
##
## El tercer punto se obtiene mediante el algoritmo iterativo de punto fijo.

function iarco = Genera_Iarc_RT(V,Fs)

% Declaración de variables estáticas
persistent DenVz1;
persistent DenIz1;
persistent start_arc;
persistent Vt_corte;
persistent It_corte;
persistent Ptprev;
persistent Pnprev_vect;

 if (isnumeric(V)==false)
  error("V debe ser numérico");
 endif


 if (isscalar(V)==false)
  error("V debe ser escalar");
 endif

 % Inicialización de variables estáticas
 if (isempty(DenVz1)==true)
   DenVz1=0;
 endif

 if (isempty(DenIz1)==true)
   DenIz1=0;
 endif

 if (isempty(start_arc)==true)
   start_arc=1;   % para señalar que es el primer punto del arco
 endif

% Modelo de arco eléctrico
Rl_arco=10;             % Resistencia de carga del camino en ohms
Vd=450;                 % Tensión de avalancha en V
Id=0.1;                 % Corriente de inicio de avalancha en A
V0=25;                  % Tensión electromotriz del arco en V
alfa_arco=V0*pi/2;      % Parámetrso calculado del modelo de Jonathan Andrea
Rc_arco=Vd/Id;          % Resistencia del gas en zona luminiscente, Se calculado
                        % experimentalmente midienod Vd e Id
beta_arco=tan(alfa_arco/Vd)/Id; % Parámetro beta del modelo


% Modelo dinámico del arco eléctrico
tau_aval=100e-6;        % Tiempo experimental de formación/eliminación del canal en s
nest=tau_aval*Fs;
tau=1/(Fs*(e^(2.3/nest)-1));  % Parámetro de tiempo al discretizar

a0=1+tau*Fs;                % Filtros LP que modelan la dinámica del arco
a1=-tau*Fs;
Nom=1/a0;
Den=a1/a0;

% Curva Vt-I estática del arco. Se usa para cálculo de puntos de trabajo
% Sólo para grafivar V-I
%dI=0.01;
%It=(-32768:32767).*dI;
%Vt=(alfa_arco*Rc_arco.*It)./(atan(beta_arco.*It).*It.*Rc_arco+alfa_arco);

% Preparación de la simulación
verrormax=0.1;    % Error permitido en el cálculo de la tensión en V
ierrormax=0.001;  % Error peritido en el cálculo de corrientes en A
maxitera=10;      % Máximo número de iteraciones

if (abs(V)> Vd)
  % Sólo puede haber un punto de corte.
  Vt_corte=sign(V)*V0;
  It_corte=(V-Vt_corte)/Rl_arco;
elseif (abs(V)==Vd)
  % Hay 2 puntos de corte
  Vt_corte=sign(V)*[Vd V0];
  It_corte=[(V-Vt_corte(1)) (V-Vt_corte(2))]/Rl_arco;
else
  % Hay 3 puntos de corte
  % El primer punto de corte es la interseción de la recta de carga y
  % la recta (Vd,Id)
  It1=V/(Rc_arco+Rl_arco);
  Vt1=V-It1*Rl_arco;

  % El tercer punto de corte tiene Vt=V0
  It3=(V-V0)/Rl_arco;
  Vt3=sign(V)*V0;

  % Para calcular el segundo punto usamos el algoritmo iterativo de
  % punto fijo.
  %
  % Partimos de un valor de Vt en la curva entre Vd y V0. Por ejemplo
  % (Vd+V0)/2
  % Usamos este valor para calcular
  %
  % It=(V-Vt)/Rl
  %
  % Y usamos It para calcular de nuevo Vt
  %
  % Vt=(alfa_arco*Rc_arco*It)/(atan(beta_arco*It)*It*Rc_arco+alfa_arco);
  %
  % Se repite la iteración hasta que Vt e It entren dentro de un error
  % permitido.
  %

  flag_found=0;
  itera=0;
  Vaux=sign(V)*(Vd+V0)/2;  % Primer punto de tensión
  Iaux=(V-Vaux)/Rl_arco;   % Primer punto de corriente
  while (flag_found==0)
    Vaux2=(alfa_arco*Rc_arco*Iaux)/(atan(beta_arco*Iaux)*Iaux*Rc_arco+alfa_arco);
    Iaux2=(V-Vaux2)/Rl_arco;

    verror=abs(Vaux2-Vaux);
    ierror=abs(Iaux2-Iaux);

    Vaux=Vaux2;
    Iaux=Iaux2;

    itera=itera+1;

    if ((verror<= verrormax && ierror<=ierrormax) || itera==maxitera)
      flag_found=1;
    endif
  endwhile

  It_corte=[It1 Iaux It3];
  Vt_corte=[Vt1 Vaux Vt3];
endif

if (start_arc==1)
  % El primer punto, se escoge en zona de descarga luminiscente
  % si uno de los puntos de corte está en esta zona. Si no, se
  % escoge el de mayor corriente en zona de avalancha
  start_arc=0;
  [Itnmin,indtn]=min(abs(It_corte));
  Itn=It_corte(indtn);
  Vtn=Vt_corte(indtn);
  Vtprev=Vtn;
  Itprev=Itn;
  Ptprev=Vtn*Itn;
else
  Pn_vect=It_corte.*Vt_corte;
  Pnprev_vect=Ptprev*ones(size(It_corte));
  Pdif=abs(Pnprev_vect-Pn_vect);
  [Pdifmin,indmin]=min(Pdif);
  Vtn=Vt_corte(indmin);
  Itn=It_corte(indmin);
  Vtprev=Vtn;
  Itprev=Itn;
  Ptprev=Vtn*Itn;
endif

% Filtrado dinámico del arco
Varc=Vtn*Nom-DenVz1*Den;
DenVz1=Varc;
Iarc=Itn*Nom-DenIz1*Den;
DenIz1=Iarc;

iarco=Iarc;

endfunction
