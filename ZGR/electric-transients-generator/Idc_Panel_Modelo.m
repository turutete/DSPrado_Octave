##
## Idc_Panel_Modelo,m
##
## Esta función calcula la corriente de un panel fotovoltaico utilizando
## un modelo lineal de 2 secciones.
##
## Idc= Idc_Panel_Modelo(Vdc,Iscpanel,Vocpanel, Vmpptpanel, Impptpanel);
##
## Vdc= Tensión del bus DC
## Iscpanel= Corriente de corto circuito del panel
## Vocpanel= Tensión de circuito abierto
## Vmpptpanel= Tensión de mppt
## Impptpanel= Corriente de mppt
##
## Copyright (C) 2026 carom
##
## Author: Dr. Carlos Romero Pérez
## Created: 2026-04-25

function Idc = Idc_Panel_Modelo(Vdc,Iscpanel,Vocpanel, Vmpptpanel, Impptpanel)
  if (Vdc<=Vmpptpanel)
    Idc=Vdc*(Impptpanel-Iscpanel)/Vmpptpanel+Iscpanel;
  else
    Idc=(Vdc-Vmpptpanel)*Impptpanel/(Vmpptpanel-Vocpanel)+Impptpanel;
  endif

endfunction
