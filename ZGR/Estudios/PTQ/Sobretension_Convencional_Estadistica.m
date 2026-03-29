##
##  Sobretension_Convencional_Estadistica
##
## EST = Sobretension_Convencional_Estadistica (vin, alerta, fallo ,Nfallo, tipo)
##
## Esta función efectúa un análisis estadístico de la detección de sobretensión
## de DC mediante el algoritmo convencional de detección por umbral
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
## vin: señal de entrada sin ryuido
## alerta: Nivel de alerta
## fallo: Nivel de fallo
## Nfallo: Duración en muestras para fallo por superación del nivel de alerta
## tipo: Ancho de banda del filtro LP 0: sin filtrar 1: 0.01 2: 0.1 3: 0.25
##
## Copyrigh##t (C) 2026 Zigor R&D
##
## Author: Dr. Carlos Romero
## Created: 2026-03-20
##
function EST = Sobretension_Convencional_Estadistica (vin, alerta, fallo ,Nfallo, tipo)

  pkg load signal;

  if (isvector(vin)==false)
    error("vin debe ser un vector");
  endif

  if (isnumeric(vin)==false)
    error("vin debe ser numérico");
  endif

  if (isscalar(alerta)==false || isscalar(Nfallo)==false || isscalar(fallo)==false || isscalar(tipo)==false )
    error("alerta, fallo, Nfallo y tipo deben ser escalares");
  endif

 if (isnumeric(alerta)==false || isnumeric(tipo)==false || isnumeric(Nfallo)==false || isnumeric(fallo)==false )
    error("alerta, fallo, Nfallo y tipo deben ser numéricos");
  endif

  if (alerta<=0 || fallo<=0 || tipo<0 || Nfallo<=0)
    error("alerta, fallo, Nfallo y tipo deben ser enteros positivos");
  endif

  tipo=floor(tipo);
  Nfallo=floor(Nfallo);

  if (tipo==1)
    [B,A]=ellip(2,0.1,20,0.01);
  endif

  if (tipo==2)
    [B,A]=ellip(2,0.1,20,0.1);
   endif

   if(tipo==3)
      [B,A]=ellip(2,0.1,20,0.25);
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
      xraw=vin+noise;
      if (tipo==0)
        x=xraw;
      else
        x=filter(B,A,xraw);
      endif

      casos=casos+1;

      flag=0;
      antiglitch=Nfallo; % Número de detecciones consecutivas para asegurar fallo
      nfallos=0;
      flag_alerta=0;
      flag_fallo=0;
      ind=150;          % El pero caso Wp=0.01 tiene un retaso de 150 muestras

      while (flag==0)

     %Seguimiento de alerta
        if (x(ind)>=alerta && flag_alerta==1)
          nfallos=nfallos+1;
        else
          if (flag_alerta==1)
            flag_alerta=0;
            nfallos=0;
          endif
        endif

        %Confirmación de fallo
        if (x(ind)>fallo && flag_fallo==1)
          flag=1;
        else
          if (flag_fallo==1)
            flag_fallo=0;
          endif
        endif

      %Detector de disparo de alerta
        if (x(ind)>=alerta && flag_alerta==0)
          flag_alerta=1;
          nfallos=nfallos+1;
        endif

        %Detector de disparo de fallo
        if (x(ind)>fallo && flag_fallo==0)
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

  printf("Media \t Max\t \Min\t \Varianza\n");
  for fil=1:5
    printf("%0.2f\t %i\t %i\t %0.2f\n",EST(fil,1),EST(fil,2), EST(fil,3), EST(fil,4));
  endfor

endfunction
