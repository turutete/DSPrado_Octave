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
  dalerta=1016;
  dfallo=4061;



  for veces=1:trials
      indnoise=floor((casos-1)/20)+1;
      An=Anoise(indnoise);
      noise=An*randn(1,L);      % Vector de ruido
      x=vin+noise;
      casos=casos+1;
      M=RT_Momentos(x,N);


      % Detección de sobretensión por umbral en Curtosis

      ind=2*N;    %Se inicia a partir de las N+2 primeras muestras
      flag=0;
      antiglitch=Nfallo; % Número de detecciones consecutivas para asegurar fallo
      nfallos=0;


      while (flag==0)
        if (M(2,ind)>=dalerta && M(1,ind)>0)
          nfallos=nfallos+1;
          if (nfallos>=antiglitch)
            flag=1;
          endif
        else
          nfallos=0;
        endif
        if (M(2,ind)>=dfallo && M(1,ind)>0)
          flag=1;
        endif
        ind=ind+1;

        if (ind==L)
          flag=2;
        endif
      endwhile

      if (flag==1)
        indfallo=ind-1;
        varval=M(2,indfallo);
      else
        indfallo=0;
        varval=0;
      endif

      R(veces,:)=[veces An^2 indfallo varval];

  endfor

  q=1:20;

  for fil=1:5
    v(q)=R((fil-1)*20+q,3);
    EST(fil,:)=[mean(v) max(v) min(v)];
  endfor


endfunction
