#
# Arco_AC.m
#
# Ejemplo de arco AC en el equipo.
#
# Este ejemplo usa los datos de un panel comercial.
#
# Simula, para unas condiciones ambientales de irradiancia Su, y temperatura T
# y una referencia de potencia activa Pref por unidad, la forma de onda de
# corriente Idc que mide el sensor de medida de corriente DC del equipo, antes
# y despu�s de producirse un evento de arco DC
#
# Autor: Dr. Carlos Romero P�rez
# Fecha: 16/03/2025
#

addpath('../Libreria/FISICA_CRP');
addpath('../ZGR/electric-transients-generator');


% Condiciones de trabajo
Msampling=5;          % Hay Msampling puntos en cada ciclo de control
fswitch=2500;
Fs=Msampling*fswitch;
Nciclos=1000;         % N�mero de ciclos de control de la simulaci�n
L=Nciclos*Msampling;  % N�mero de puntos de la simulaci�n


% Condiciones el�ctricas
fred=50;                          % Frecuencia de red
Vffrmasred=690;                   % Tensi�n RMS fase fase
Vfnrmsred=Vffrmasred/sqrt(3);     % Tensi�n RMS de red fase neutro
Snom=3.3e6;                       % Potencia nominal del equipo
Pu=1;                             % Referencia de potencia activa demandada al equipo por unidad
Lac=150e-6;                       % Inductancia del filtro LC

% Valor m�ximo de generaci�n del inversor
Iacmax=Snom/(3*Vfnrmsred);
Vacmax=Vfnrmsred+2*pi*fred*Lac*Iacmax;

Pac=Snom*Pu;                      % Potencia AC
Iac=Pac/(3*Vfnrmsred);            % Corriente f�sica
Vac=Vfnrmsred+2*pi*fred*Lac*Iac;  % Tensi�n AC rms f�sica que hay que generar


Iprotect=Iacmax*1.2;              % Protecci�n de corriente AC del equipo
flag_protct=0;


% Modelo de arco el�ctrico
%Rc_arco=2221;         % Ohms
%alfa_arco=49.0874;    % V
%beta_arco=1.4614;     % 1/A
Rl_arco=10;            % ohms
Vd=900;
Id=0.1;
V0=25;
alfa_arco=V0*pi/2;
Rc_arco=Vd/Id;
beta_arco=tan(alfa_arco/Vd)/Id;



% Modelo din�mico del arco el�ctrico
tau_aval=100e-6;
nest=tau_aval*Fs;
tau=1/(Fs*(e^(2.3/nest)-1));

a0=1+tau*Fs;
a1=-tau*Fs;
Nom=1/a0;
Den=a1/a0;
DenVz1=0;
DenIz1=0;


% C�lculo de puntos de trabajo
dI=0.01;
It=(-32768:32767).*dI;
Vt=(alfa_arco*Rc_arco.*It)./(atan(beta_arco.*It).*It.*Rc_arco+alfa_arco);

Vaval=max(Vt);  % Tensi�n aproximada de avalancha

% Simulaci�n din�mica arco-panel
Iarc=0;
indarco=round(rand(1)*L);   % �ndice cuando se produce el arco
start_arc=1;
idc_aux=0;


Vac_vector=[];
Iac_vector=[];
Iarc_vector=[];
n=1;



while (n<=L)

  if (flag_protct==0)
    % Tensi�n y corriente AC fase R sin sobrecarga
    I=Iac*sin(2*pi*fred*(n-1)/Fs);
    v=Vac*sin(2*pi*fred*(n-1)/Fs);
  else
    I=0;
    v=0;
  endif


  if n>=indarco
    % C�lculo de puntos de trabajo
    Vt2=v-It.*Rl_arco;
    % C�lculo r�pido puntos corte
    if (abs(v)<=abs(Vaval))
      index_corte=Puntos_Corte(Vt,Vt2);
      It_corte=(index_corte-32769).*dI;
      Vt_corte=v-It_corte.*Rl_arco;
    else
      V0=2*alfa_arco/pi;
      It_corte=sign(v)*(abs(v)-V0)/Rl_arco;
      Vt_corte=sign(v)*V0;
    endif


    if start_arc==1
      % El primer punto, se escoge en zona de descarga luminiscente
      % si uno de los puntos de corte est� en esta zona. Si no, se
      % escoge el de mayor corriente en zona de avalancha
      start_arc=0;
      [Itn,indtn]=min(It_corte);

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

    % Filtrado din�mico del arco
    Varc=Vtn*Nom-DenVz1*Den;
    DenVz1=Varc;

    Iarc=Itn*Nom-DenIz1*Den;

    DenIz1=Iarc;

  endif


  idc_aux=I-Iarc;

  % Protecci�n de corriente DC
  if (idc_aux>=Iprotect)
    flag_protct=1;
  endif


  Vac_vector(n)=v;
  Iac_vector(n)=idc_aux;
  Iarc_vector(n)=Iarc;
  n=n+1;


endwhile








