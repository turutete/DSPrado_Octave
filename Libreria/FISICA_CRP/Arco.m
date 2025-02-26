## -*- texinfo -*-
##
##  Arco.m
##
## Esta función devuelve el vector arco=[varaco,iarco], que son la tensión
## y la corriente del arco eléctrico entre dos conductores a una diferencia
## de potencial v(n) [v], siendo la impedancia de descarga del arco Rl [ohm].
##
## La función utiliza también los parámetros de modelización del arco, alfa, beta
## beta y Rc.
##
## Author: Dr. Carlos Romero Pérez
## Created: 2025-02-16
##
##
## Copyright (C) 2025 Zigor R&D AIE
##
## @deftypefn {} {@var{arco} =} Arco (@var{v}, @var{Rc}, @var{alfa}, @var{beta}, @var{Rl})
##
## @end deftypefn

addpath("..\Scripts");

function arco= Arco (v, Rc, alfa, beta, Rl)

  if(isvector(v)==false)
    error("El parámetro v debe ser un vector numérico");
  endif
  if(isnumeric(v)==false || isnumeric(Rc)==false || isnumeric(alfa)==false || isnumeric(beta)==false || isnumeric(Rl)==false)
    error("Los parámetros de entrada deben ser numéricos");
  endif

  if(Rc<=0||alfa<=0||beta<=0||Rl<=0)
    error("Los parámetros del modelo de arco deben ser positivos");
  endif

  % Cálculo de puntos de trabajo

  dI=0.01;
  It=(-2048:2047).*dI;
  Vt=(alfa*Rc.*It)./(atan(beta.*It).*It.*Rc+alfa);

  Vaval=max(Vt);  % Tensión aproximada de avalancha

  Vt_vector=[];
  It_vector=[];

  for index=1:length(v)

    % Cálculo de puntos de trabajo
    Vt2=v(index)-It.*Rl;

    % Cálculo rápido puntos corte
    index_corte=Puntos_Corte(Vt,Vt2);
    if length(index_corte)==0
      error("El modelo V-I estático tiene pocos puntos");
    endif

    It_corte=(index_corte-2049).*dI;
    Vt_corte=Vg_vector(index)-It_corte.*Rl;

    if index==1
      % El primer punto, se escoge en zona de descarga luminiscente
      % si uno de los puntos de corte está en esta zona. Si no, se
      % escoge el de mayor corriente en zona de avalancha
      if (length(Vt_corte)==3)
        [Itn,indtn]=min(It_corte);
      else
      [Itn,indtn]=max(It_corte);
      endif

      Vtn=Vt_corte(indtn);
      Vtprev=Vtn;
      Itprev=Itn;
      Ptprev=Vtn*Itn;
    else
      Pn_vect=It_corte.*Vt_corte;
      Pnprev_vect=Ptprev*ones(size(index_corte));
      Pdif=abs(Pnprev_vect-Pn_vect);
      [Pdifmin,indmin]=min(Pdif);
      Vtn=Vt_corte(indmin);
      Itn=It_corte(indmin);
      Vtprev=Vtn;
      Itprev=Itn;
      Ptprev=Vtn*Itn;
    endif

    Vt_vector(index)=Vtn;
    It_vector(index)=Itn;

  endfor

  % Modelo dinámico del arco eléctrico
  tau_aval=100e-6;
  nest=tau_aval*Fs;
  tau=1/(Fs*(e^(2.3/nest)-1));

  Nom=1;
  Den=[1+tau*Fs -tau*Fs];

  Iarc=filter(Nom,Den,It_vector);
  Varc=filter(Nom,Den,Vt_vector);


endfunction
