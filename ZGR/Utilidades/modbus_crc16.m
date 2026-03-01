## Copyright (C) 2025 cromero
##
## This program is free software: you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program.  If not, see <https://www.gnu.org/licenses/>.
##
## -*- texinfo -*-
## @deftypefn {} {@var{crc} =} modbus_crc16 (@var{data})
##
## @end deftypefn
## Author: cromero <cromero@CROMERO-PC>
## Created: 2025-09-17

function crc = modbus_crc16(data)
  % data: vector de bytes [0-255] del telegrama
  % devuelve el CRC como entero sin signo (0\u201365535)

  crc = uint16(65535); % 0xFFFF
  poly = uint16(40961); % 0xA001

  for i = 1:length(data)
    crc = bitxor(crc, uint16(data(i)));
    for j = 1:8
      if bitand(crc, 1)
        crc = bitxor(bitshift(crc, -1), poly);
      else
        crc = bitshift(crc, -1);
      end
    end
  end

crc_low  = bitand(crc, 255);        % byte bajo
crc_high = bitshift(crc, -8);       % byte alto
printf("CRC 0x%02X 0x%02X\n", crc_low, crc_high);

endfunction
