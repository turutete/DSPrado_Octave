##
##  Sobretension_Momentos_Estadisticas
##
## Esta función efectúa un análisis estadístico de la detección de sobretensión
## de DC.
##
## La función tiene como parámetros de entrada una señal de entrada x(n), el
## umbral de alerta, el umbral de fallo, el número de muestras de duración en
## alerta para considerarlo fallo y el número de muestras de la ventana de
## análisis
##
## La función realiza 100 casos de estudio, añadiendo ruido blanco aditivo
## Gaussiano a la señal de entrada con varianzas 0.01,0.05, 0.1, 0.5, 1.
##
## Para cada iteración la función indica:
##
## Iteración
## índice de detección del fallo
## valor de la curtosis en el momento de la detección
## Varianza del ruido
##
## Copyright (C) 2026 Zigor R&D
##
## -*- texinfo -*-
## @deftypefn {} {@var{EST} =} Sobretension_Momentos_Estadisticas (@var{xin}, @var{alerta},@var{fallo}, @var {Nfallo}, @var{N})
##
## @end deftypefn
## Author: Dr. Carlos Romero
## Created: 2026-01-17

function EST = Sobretension_Momentos_Estadisticas (vin, alerta, fallo ,Nfallo, N)

  if (isvector(vin)==false)
    error("vin debe ser un vector");
  endif

  if (isnumeric(vin)==false)
    error("vin debe ser numérico");
  endif

  if (isscalar(alerta)==false || isscalar(N)==false || isscalar(Nfallo)==false || isscalar(fallo)==false )
    error("alerta, fallo, Nfallo y N deben ser escalares");
  endif

 if (isnumeric(alerta)==false || isnumeric(N)==false || isnumeric(Nfallo)==false || isnumeric(fallo)==false )
    error("alerta, fallo, Nfallo y N deben ser numéricos");
  endif

  if (alerta<=0 || fallo<=0 || N<=0 || Nfallo<=0)
    error("alerta, fallo, Nfallo y N deben ser enteros positivos");
  endif

  N=floor(N);
  Nfallo=floor(Nfallo);

  if (N==0)
    N=1;
  endif

  if (Nfallo==0)
    Nfallo=1;
  endif

  L=length(vin);
  trials=100;
  R=zeros(trials,4);
  Anoise=sqrt([0.01 0.05 0.1 0.5 1]);
  casos=1;




  for veces=1:trials
      indnoise=floor((casos-1)/20)+1;
      An=Anoise(indnoise);
      noise=An*randn(1,L);      % Vector de ruido
      x=vin+noise;
      xprealer(1,:)=x(1,:)-alerta;
      xprefall(1,:)=x(1,:)-fallo;
      casos=casos+1;
      Male=RT_Momentos(xprealer,N);
      Mfall=RT_Momentos(xprefall,N);


      % Detección de sobretensión por M0

      ind=2*N;    %Se inicia a partir de las N+2 primeras muestras
      flag=0;
      antiglitch=Nfallo; % Número de detecciones consecutivas para asegurar fallo
      nfallos=0;
      detector_asim=4;
      flag_alerta=0;
      flag_fallo=0;


      while (flag==0)

     %Seguimiento de alerta
        if (Male(1,ind)>0&& flag_alerta==1)
          nfallos=nfallos+1;
        else
          if (flag_alerta==1)
            flag_alerta=0;
            nfallos=0;
          endif
        endif

        %Confirmación de fallo
        if ((Mfall(3,ind)>detector_asim && Mfall(1,ind)>0)&& flag_fallo==1)
          flag=1;
        else
          if (flag_fallo==1)
            flag_fallo=0;
          endif
        endif

      %Detector de disparo de alerta
        if ((Male(3,ind)>detector_asim && Male(1,ind)>0)&& flag_alerta==0)
          flag_alerta=1;
          nfallos=nfallos+1;
        endif

        %Detector de disparo de fallo
        if ((Mfall(3,ind)>detector_asim && Mfall(1,ind)>0)&& flag_fallo==0)
          flag_fallo=1;
        endif

        if (nfallos>=antiglitch)
            flag=1;
        endif

        ind=ind+1;

        if (ind==L)
          flag=2;
        endif
      endwhile

      if (flag==1)
        indfallo=ind-1;
        merval=x(indfallo);
      else
        indfallo=0;
        merval=0;
      endif

      R(veces,:)=[veces An^2 indfallo merval];

  endfor

  q=1:20;

  for fil=1:5
    v(q)=R((fil-1)*20+q,3);
    EST(fil,:)=[mean(v) max(v) min(v) var(v)];
  endfor


endfunction
