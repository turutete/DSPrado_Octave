#
# utf8_coder.m
#
# Este script busca en el directorio desde donde se le ha invocado ficheros m.
#
# Identifica los ficheros que no son UTF-8 y les cambia la cosificación a UTF-8
#
# IMPORTANTE: La carpeta donde se encuentre este script debe estar en la
# tabla de rutas de búsqueda de Octave para que pueda ser invocado desde cualquier
# otra carpeta.
#
# Autor: Dr. Carlos Romero
# Copilot: Gemini 3 Fast
# Fecha: 13/04/2026


% 1. Obtener la ruta del directorio de trabajo actual
ruta_raiz = pwd();

lista_archivos = dir(fullfile(ruta_raiz, '**', '*.m'));

printf('Analizando directorio de trabajo: %s\n', ruta_raiz);
printf('--------------------------------------------------\n');

ficheros_cambiados = 0;

for i = 1:length(lista_archivos)
    fichero_actual = fullfile(lista_archivos(i).folder, lista_archivos(i).name);

    % Evitar procesar el propio script si esta en la misma carpeta
    if strcmp(fichero_actual, mfilename('fullpath'))
        continue;
    endif

    % 2. Leer los bytes crudos (sin interpretacion)
    fid = fopen(fichero_actual, 'r');
    if fid == -1, continue; end
    raw_bytes = uint8(fread(fid, '*uint8'));
    fclose(fid);

    if isempty(raw_bytes), continue; end

    % 3. DETECCION LOGICA: ¿Es UTF-8 valido?
    % Intentamos convertir de UTF-8 a Unicode. Si hay caracteres extendidos
    % que no siguen la regla de bits de UTF-8, native2unicode fallara o
    % producira caracteres de reemplazo.
    try
        test_str = native2unicode(raw_bytes, 'UTF-8');
        % Si el archivo tiene bytes > 127 (acentos, ñ) pero no es UTF-8,
        % el caracter 65533 aparecera casi seguro.
        necesita_conversion = any(test_str == 65533);
    catch
        necesita_conversion = true;
    end_try_catch

    if necesita_conversion
        printf('Detectado formato ANSI/Otro. Convirtiendo: %s\n', lista_archivos(i).name);

        % 4. Convertir asumiendo que el origen es Windows-1252 (ANSI)
        contenido_unicode = native2unicode(raw_bytes, 'Windows-1252');

        % 5. Guardar como UTF-8 puro
        fid = fopen(fichero_actual, 'w');
        fwrite(fid, unicode2native(contenido_unicode, 'UTF-8'));
        fclose(fid);

        ficheros_cambiados++;
    endif
end

printf('--------------------------------------------------\n');
printf('Finalizado. %d archivos convertidos a UTF-8.\n', ficheros_cambiados);
