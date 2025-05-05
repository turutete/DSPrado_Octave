##
##  LMS_Ejemplo
##
## Ejemplo de filtro adaptativo LMS
##
## Autor: Dr. Carlos Romero P�rez
## fecha: 28/04/2025
##

% Par�metros
N = 2048;            % N�mero de muestras
M = 10;              % N�mero de coeficientes del filtro adaptativo
frec = 50/12500;     % Frecuencia de la se�al limpia
%mu_values = [0.001, 0.01, 0.1];  % Distintos valores de mu a probar
mu_values=0.1;

% Se�al limpia (senoide)
n = 0:N-1;
signal_clean = sin(2*pi*frec*n);

% Ruido blanco
noise = 0.1*randn(1, N);
%noise = 0.1 * (sin(2*pi*frec*5*n)+sin(2*pi*frec*10*n));

% Se�al contaminada
d = signal_clean + noise;

% Referencia de ruido (en este ejemplo simple, el propio ruido)
x = noise;

% Graficar resultados
figure;
for k = 1:length(mu_values)
    mu = mu_values(k);

    % Inicializaci�n del filtro
    w = zeros(M,1);
    e = zeros(1,N);

    % Adaptaci�n LMS
    for i = M:N
        x_vec = x(i:-1:i-M+1)';  % Vector de entrada
        y = w' * x_vec;          % Salida del filtro
        e(i) = d(i) - y;          % Error
        w = w + mu * e(i) * x_vec; % Actualizaci�n LMS
    end

    % Representar error
    subplot(length(mu_values),1,k);
    plot(n, e);
    title(["Error e(n) con mu = ", num2str(mu)]);
    xlabel('n');
    ylabel('e(n)');
end

figure;
plot(n,d);


