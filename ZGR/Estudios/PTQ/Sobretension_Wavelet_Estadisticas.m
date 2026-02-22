##
##  Sobretension_Wavelet_Estadisticas
##
## Esta función efectúa un análisis estadístico de la detección de sobretensión
## de DC mediante Wavelets.
##
## La función tiene como parámetros de entrada una señal de entrada x(n), el
## umbral de alerta, el umbral de fallo, el número de muestras de duración en
## alerta para considerarlo fallo y el tipo de wavelet.
##
## El tipo de wavelet es un enumerado:
##
## 0: Db4
## 1: Db8
##
## No importa cuál es el número de niveles de Wavelet, porque siempre usamos
## la wavelet de mayor banda de frecuencia.
##
## La función realiza 100 casos de estudio, añadiendo ruido blanco aditivo
## Gaussiano a la señal de entrada con varianzas 0.01,0.05, 0.1, 0.5, 1.
##
## La función retorna una matriz EST [5 X 4] donde cada fila muestra
## el valore medio del índice de detección del fallo de sobretensión, el valore
## del índice máximo, el valor del índice mínimo, y el valor de la varianzas
## en la detección del índice para el nivel de varianza de ruido:
##
## fila 1: 0.01
## fila 2: 0.05
## fila 3: 0.1
## fila 4: 0.5
## fila 5: 1
##
## Copyright (C) 2026 Zigor R&D
##
## -*- texinfo -*-
## @deftypefn {} {@var{EST} =} Sobretension_Wavelet_Estadisticas (@var{xin}, @var{alerta},@var{fallo}, @var {Nfallo}, @var{tipo})
##
## @end deftypefn
## Author: Dr. Carlos Romero
## Created: 2026-02-15

function EST = Sobretension_Wavelet_Estadisticas (vin, alerta, fallo ,Nfallo, tipo)

  if (isvector(vin)==false)
    error("vin debe ser un vector");
  endif

  if (isnumeric(vin)==false)
    error("vin debe ser numérico");
  endif

  if (isscalar(alerta)==false || isscalar(Nfallo)==false || isscalar(fallo)==false || isscalar(tipo)==false)
    error("alerta, fallo, Nfallo  y tipo deben ser escalares");
  endif

 if (isnumeric(alerta)==false || isnumeric(Nfallo)==false || isnumeric(fallo)==false || isnumeric(tipo)==false )
    error("alerta, fallo, Nfallo y tipo deben ser numéricos");
  endif

  if (alerta<=0 || fallo<=0 || Nfallo<=0 || tipo<0)
    error("alerta, fallo, Nfallo y tipo deben ser enteros positivos");
  endif


  Nfallo=floor(Nfallo/2);
  tipo=floor(tipo);
  if (tipo>1)
    tipo=0;
  endif

   if (Nfallo==0)
    Nfallo=1;
  endif

  L=length(vin);
  trials=100;
  R=zeros(trials,3);
  Anoise=sqrt([0.01 0.05 0.1 0.5 1]);
  casos=1;
  l=1:L;
  modulador(l)=(-1).^l;

  alerta=alerta*sqrt(2);    % Adecuanión de nivel al wavelet
  fallo=fallo*sqrt(2);

  for veces=1:trials
      indnoise=floor((casos-1)/20)+1;
      An=Anoise(indnoise);
      noise=An*randn(1,L);      % Vector de ruido
      x=vin+noise;
      xmod=x.*modulador;        % Modulamos a alta frecuencia
      casos=casos+1;


      if (tipo==0)
        W=Wavelet_Db4(xmod,3);
      endif

      if (tipo==1)
        W=Wavelet_Db8(xmod,3);
      endif

      % Detección de sobretensión por Wavelet

      ind=8;    %El peor caso es Db8, con 8 muestras de retraso
      flag=0;
      antiglitch=Nfallo; % Número de detecciones consecutivas para asegurar fallo
      nfallos=0;

      while (flag==0)

        if (W(ind)>alerta)
          nfallos=nfallos+1;
        else
          nfallos=0;
        endif

        if (W(ind)>fallo)
          flag=1;
        endif

        if (nfallos>=antiglitch)
            flag=1;
        endif

        ind=ind+1;

        if (ind>=(L/2))
          flag=2;
        endif
      endwhile

      if (flag==1)
        indfallo=ind-1;
      else
        indfallo=0;
      endif

      R(veces,:)=[veces An^2 indfallo*2];

  endfor

  q=1:20;

  for fil=1:5
    v(q)=R((fil-1)*20+q,3);
    EST(fil,:)=[mean(v) max(v) min(v) var(v)];
  endfor


endfunction
