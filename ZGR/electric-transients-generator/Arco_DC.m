#
# Arco_DC.m
#
# Ejemplo de arco DC en el equipo.
#
# Este ejemplo usa los datos de un panel comercial.
#
# Simula, para unas condiciones ambientales de irradiancia Su, y temperatura T
# y una referencia de potencia activa Pref por unidad, la forma de onda de
# corriente Idc que mide el sensor de medida de corriente DC del equipo, antes
# y despu�s de producirse un evento de arco DC
#
# Autor: Dr. Carlos Romero P�rez
# Fecha: 15/02/2025
#



% Condiciones ambientales
Su=0.5+0.5*rand(1);    % Irradiancia por unidad S/Sref [0.5 - 1]
T=25+15*(1-rand(1));           % Temperatura en �C [25 - 40]


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
M=1.3;                            % �ndice de modulaci�n

% Valor m�ximo de generaci�n del inversor
Iacmax=Snom/(3*Vfnrmsred);
Vacmax=Vfnrmsred+2*pi*fred*Lac*Iacmax;

Pac=Snom*Pu;                      % Potencia AC
Iac=Pac/(3*Vfnrmsred);            % Corriente f�sica
Vac=Vfnrmsred+2*pi*fred*Lac*Iac;  % Tensi�n AC rms f�sica que hay que generar


Vequipomx=Vacmax*2*sqrt(2)/M;     % Tensi�n m�xima del Bus del equipo
Iequipomx=Snom/Vequipomx;         % Corriente m�xima  del bus del equipo
Iprotect=Iequipomx*1.2;           % Protecci�n de corriente DC del equipo
flag_protct=0;

Vequipo=Vac*2*sqrt(2)/M;          % Tensi�n de bus real
Iequipo=Pac/Vequipo;              % Corriente de bus demandada por la carga


% Modelo de arco el�ctrico
%Rc_arco=2221;         % Ohms
%alfa_arco=49.0874;    % V
%beta_arco=1.4614;     % 1/A
Rl_arco=0.1;            % ohms
Vd=1300;
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

% Selector Panel
ejemplo=2;

switch (ejemplo)
  case 1
    % Art�culo
    Np=1;
    Ns=60;
    Iscpanel=8.85;
    Vocpanel=37.85;
    alfa_isc=0.062;
    beta_vosc=-0.33;
    Vmpptpanel=30.12;
    Impptpanel=8.3;
    Npanels=round(Vequipomx/Vmpptpanel);
    Npanelp=round(Iequipomx/Impptpanel);
  case 2
    % Ejemplo de panel solar real: TSM-DE14A
    Np=3;
    Ns=24;
    Iscpanel=9.69;    %A
    Vocpanel=47;      %V
    alfa_isc=0.05;    %/�C
    beta_vosc=-0.29;  % %/�C
    Vmpptpanel=38.7;
    Impptpanel=9.17;
    Npanels=round(Vequipomx/Vmpptpanel);
    Npanelp=round(Iequipomx/Impptpanel);
  case 3
    % Ejemplo de panel solar DS new energy 600W monocristalino
    Np=6;
    Ns=20;
    Iscpanel=18.57;     %A
    Vocpanel=41.7;      %V
    alfa_isc=0.046;    %/�C
    beta_vosc=-0.277;  % %/�C
    Vmpptpanel=34.6;
    Impptpanel=17.49;
    Npanels=round(Vequipomx/Vmpptpanel);
    Npanelp=round(Iequipomx/Impptpanel);
endswitch


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

% Condici�n inicial del control de bus DC
D=0.5;
Vdcpanel=Vequipo/Npanels;

Vdc_vector=[];
Idc_vector=[];
Iarc_vector=[];
n=1;
r=1;
flag_sobrecarga=0;    % 0: I <=Imppt 1: I>Imppt

% C�lculo del condensador del bus de continua
dVdc=Vequipomx/10;   % 10% de la tensi�n de bus
Cdc=Iequipomx/(4*Fs*dVdc);
Kdc=Iequipomx/(Cdc*Fs);

Vdcrect=3*sqrt(2)/pi*Vffrmasred;       % Tensi�n de red rectificada del ejemplo

while (n<=L)

  if (flag_protct==0)
    if (flag_sobrecarga== 0)
      % C�lculo de la corriente de campo fotovoltaico seg�n condiciones ambientales
      Ipanel=Idc_Panel(Vdcpanel,Su,T,Iscpanel,Vocpanel,Vmpptpanel,Impptpanel,Ns,Np,alfa_isc,beta_vosc);
      I=Npanelp*Ipanel;
      v=Vdcpanel*Npanels;
    else
      %Calculamos la caida de tensi�n en los paneles debido a la sobrecorriente
      deltaV=(idc_aux-(Ipanel*Npanelp))/(Cdc*Fs*Npanels);
      Vdcpanel=Vdcpanel-deltaV;
      if (Vdcpanel<(Vdcrect/Npanels))
        Vdcpanel=Vdcrect/Npanels;
      endif
      Ipanel=Idc_Panel(Vdcpanel,Su,T,Iscpanel,Vocpanel,Vmpptpanel,Impptpanel,Ns,Np,alfa_isc,beta_vosc);
      I=Npanelp*Ipanel;
      v=Vdcpanel*Npanels;
    endif
  else
    deltaV=idc_aux/(Cdc*Fs*Npanels);
    Vdcpanel=Vdcpanel-deltaV;
    if (Vdcpanel<(Vdcrect/Npanels))
      Vdcpanel=Vdcrect/Npanels;
    endif
    Ipanel=0;
    I=0;
    v=Vdcpanel*Npanels;
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
  % Valor de tensi�n DC
  % Generaci�n de la corriente de carga en nuevo ciclo de control
  if (r==1)
    c=1:3;
    idcp(c)=I*(c-1)/(Msampling*D);
    c=4:Msampling;
    idcp(c)=I*(1-(c-1)/Msampling)/(1-D);
  endif

  if (flag_protct==1)
    idcp(r)=0;
  endif

  idc_aux=idcp(r)+Iarc;

  % Protecci�n de corriente DC
  if (idc_aux>=Iprotect)
    flag_protct=1;
  endif
  % Si la corriente total es menor o igual a Isc el panel es capaz de suministrarlo
  % pero si es mayor, el condensador del bus de DC debe suministrarlas,
  % lo que provoca que caiga la tensi�n del bus
  if (idc_aux>(Iscpanel*Npanelp))
    flag_sobrecarga=1;
  else
    flag_sobrecarga=0;
  endif

  Vdc_vector(n)=v;
  Idc_vector(n)=idc_aux;
  Iarc_vector(n)=Iarc;
  r=r+1;
  n=n+1;

  if (r==(Msampling+1))
    r=1;
  endif

endwhile








