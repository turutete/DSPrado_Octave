## -*- texinfo -*-
##
## Idc_Panel.m
##
## Esta funci�n retorna la corriente DC de un panel fotovoltaico para
## unas condiciones de tensi�n de DC Vdc (V), irradiancia por unidad Su y
## temperatura T (�C).
##
## Los par�metros caracter�sticos del pane solar que se deben introducir son:
##
## Iscpanel: Corriente de cortocircuito del panel a 25�C
## Vocpanel: Tensi�n de circuito abierto del panel a 25�C
## Vmpptpanel: Tensi�n de mppt a 25�C
## Impptpanel: Corriente de mppt a 25�C
## alfa_isc: Coeficiente de temperatura de la corriente de cortocircuito
## beta_voc: Coeficiente de temperatura de la tensi�n de circuito abierto
##
## Copyright (C) 2025 Zigor R&D AIE
## Author: Dr. Carlos Romero P�rez
## Created: 2025-02-23
##
## @deftypefn {}
##{@var{idc_panel} =} Idc_Panel (@var{Vdc}, @var{Su}, @var{T}, @var{Isc_panel},
## @var{Voc_panel},@var{Vmppt_panel},@var{Imppt_panel},@var{Ns},@var{Np},
## @var{alfa_isc},@var{beta_voc})
##
## @end deftypefn



function idc_panel = Idc_Panel (Vdc,Su,T,Isc_panel,Voc_panel,Vmppt_panel,Imppt_panel,Ns,Np,alfa_isc,beta_voc)

  if (isnumeric(Vdc)==false || isnumeric(Su)==false || isnumeric(T)==false ||
    isnumeric(Isc_panel)==false || isnumeric(Voc_panel)==false ||
    isnumeric(Vmppt_panel)==false||isnumeric(Imppt_panel)==false||
    isnumeric(Ns)==false || isnumeric(Np)==false ||
    isnumeric(alfa_isc)==false || isnumeric(beta_voc)==false)

    error("Los par�metros de entrada deben ser num�ricos");

  endif


  if (Vdc<0 || Su<0 || Isc_panel<0 || Voc_panel<0 || Vmppt_panel<0 ||
    Imppt_panel<0||Ns<0 || Np<0)
    error("Vdc, Su, Isc_panel, Voc_panel, Ns, Np deben ser positivos");
  endif

  if (Su>1)
    error("Su pertenece al intervalo [0 1]");
  endif

  if (Vmppt_panel>=Voc_panel)
    error("La tensi�n de mppt debe ser menor que Voc");
  endif

  if (Imppt_panel>=Isc_panel)
    error("La corriente de mppt debe ser menor que Isc");
  endif

  Np=round(Np);
  Ns=round(Ns);

  % Definiciones
  K=1.38e-23;     % Constante de Boltzman [J/K]
  q=1.6e-19;      % Carga del electr�n [C]
  A=1.3;          % Factor de idealidad del semiconductor (Si=1.3)
  Tref=25+273.15; % Tempertura de referencia [K]
  Rs=0.01;        % Resistencia serie de celda [ohms]
  Rsh=10000;      % Resistencia de p�rdida de celda [ohms]
  Eg=1.12;        % eV Energ�a de la banda gap

  % Valores deducidos de celda
  Tk=T+273.15;    % Tempertura ambiente en Kelvin
  a=K*Tk*A;
  Vter=a/q;
  % Extracci�n de par�metros de celda
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

  % C�lculo de la corriente de celda
  error_max=0.001;
  iteramax=1000;
  flagloop=0;
  itera=0;

  % Selecci�n de valor inicial
  if (V<=Vmppt)
    In=Isc;
  else
    In=Imppt;
  endif

  % C�lculo de la corriente de panel seg�n condiciones
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
