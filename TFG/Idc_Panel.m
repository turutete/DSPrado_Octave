
## Idc_Panel.m
##
##
## idc_panel = Idc_Panel (Vdc,Su,T,Isc_panel,Voc_panel,Vmppt_panel,Imppt_panel,Ns,Np,alfa_isc,beta_voc)
##
## Esta función retorna la corriente DC de un panel fotovoltaico para
## unas condiciones de tensión de DC Vdc (V), irradiancia por unidad Su y
## temperatura T (ºC).
##
## Los parámetros característicos del panel solar que se deben introducir son:
##
## Iscpanel: Corriente de cortocircuito del panel a 25ºC
##
## Vocpanel: Tensión de circuito abierto del panel a 25ºC
##
## Vmpptpanel: Tensión de mppt a 25ºC
##
## Impptpanel: Corriente de mppt a 25ºC
##
## alfa_isc: Coeficiente de temperatura de la corriente de cortocircuito
##
## beta_voc: Coeficiente de temperatura de la tensión de circuito abierto
##
## Ns: Número de celdas en serie
##
## Np: Número de celdas en paralelo
##
##




function idc_panel = Idc_Panel (Vdc,Su,T,Isc_panel,Voc_panel,Vmppt_panel,Imppt_panel,Ns,Np,alfa_isc,beta_voc)

  if (isnumeric(Vdc)==false || isnumeric(Su)==false || isnumeric(T)==false ||
    isnumeric(Isc_panel)==false || isnumeric(Voc_panel)==false ||
    isnumeric(Vmppt_panel)==false||isnumeric(Imppt_panel)==false||
    isnumeric(Ns)==false || isnumeric(Np)==false ||
    isnumeric(alfa_isc)==false || isnumeric(beta_voc)==false)

    error("Los parámetros de entrada deben ser numéricos");

  endif


  if (Vdc<0 || Su<0 || Isc_panel<0 || Voc_panel<0 || Vmppt_panel<0 ||
    Imppt_panel<0||Ns<0 || Np<0)
    error("Vdc, Su, Isc_panel, Voc_panel, Ns, Np deben ser positivos");
  endif

  if (Su>1)
    error("Su pertenece al intervalo [0 1]");
  endif

  if (Vmppt_panel>=Voc_panel)
    error("La tensión de mppt debe ser menor que Voc");
  endif

  if (Imppt_panel>=Isc_panel)
    error("La corriente de mppt debe ser menor que Isc");
  endif

  Np=round(Np);
  Ns=round(Ns);

  % Definiciones
  K=1.38e-23;     % Constante de Boltzman [J/K]
  q=1.6e-19;      % Carga del electrón [C]
  A=1.3;          % Factor de idealidad del semiconductor (Si=1.3)
  Tref=25+273.15; % Tempertura de referencia [K]
  Rs=0.01;        % Resistencia serie de celda [ohms]
  Rsh=10000;      % Resistencia de pérdida de celda [ohms]
  Eg=1.12;        % eV Energía de la banda gap

  % Valores deducidos de celda
  Tk=T+273.15;    % Tempertura ambiente en Kelvin
  a=K*Tk*A;
  Vter=a/q;
  % Extracción de parámetros de celda
  Vcelda=Vdc/Ns;
  Isc=Isc_panel/Np;
  Voc=Voc_panel/Ns;
  Vmppt=Vmppt_panel/Ns;
  Imppt=Imppt_panel/Np;
  delta_isc=alfa_isc*(Tk-Tref)*Isc/100;
  V=Vdc/Ns;

  Il=Su*(Isc+delta_isc);
  I0ref=Isc/(e^(Voc/Vter)-1);
  I0=I0ref*(Tk/Tref)^3*e^(q*Eg*(1/Tref-1/Tk)/(K*A));

  % Cálculo de la corriente de celda
  error_max=0.000001;
  iteramax=1000;
  flagloop=0;
  itera=0;

  % Selección de valor inicial
  if (V<=(Vmppt*0.9))
    In=Isc;
  else
      In=Imppt;
  endif

  % Cálculo de la corriente de panel según condiciones
  while (flagloop==0)
    f=In-Il+I0*(e^((V+In*Rs)/Vter)-1)+(V+In*Rs)/Rsh;
    df=1+I0*Rs/Vter*e^((V+In*Rs)/Vter)+Rs/Rsh;

    Inext=In-f/df;

    err=abs(In-Inext);

    In=Inext;

    if (err<error_max)
      flagloop=1;
    endif

    itera=itera+1;

    if (itera>=iteramax)
      error("No converge");
    endif
  endwhile
  idc_panel=In*Np;


endfunction
