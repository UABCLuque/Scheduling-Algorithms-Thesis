%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parametros de la estructura de trama de 5G NR (enlace descendente)
%
% Funcion
%
%   [RBxFrame, REperRB, NRB, Nslot] = NR_parametros(BW, TTI)
%   [RBxFrame, REperRB, NRB, Nslot] = NR_parametros(BW, TTI, SCS)
%
%   BW      ancho de banda del canal en Hz (5 a 100 MHz, FR1)
%   TTI     duracion de la trama en s (10 ms en NR)
%   SCS     separacion entre subportadoras en Hz (15e3, 30e3 o 60e3).
%           Por defecto 30 kHz (numerologia mu = 1), la mas comun en la
%           banda n78 (3.5 GHz)
%
%   RBxFrame  RB disponibles en una trama (NRB por slot * slots por trama)
%   REperRB   elementos de recurso de un RB en un slot (12 * 14 = 168)
%   NRB       RB por slot segun el ancho de banda (TS 38.101-1)
%   Nslot     slots por trama
%
%   Estructura de trama de NR (3GPP TS 38.211, sec. 4.2 y 4.3):
%   - Un RB son 12 subportadoras con separacion SCS = 15*2^mu kHz
%   - Un slot tiene 14 simbolos OFDM (prefijo ciclico normal) y dura
%     1 ms / 2^mu (0.5 ms con 30 kHz)
%   - Una trama dura 10 ms y tiene 10*2^mu slots (20 con 30 kHz)
%   - Un RB en un slot tiene 12*14 = 168 RE. No se descuentan los RE de
%     senales de referencia ni de control (DMRS, PDCCH)
%
%   El numero de RB por ancho de banda es la configuracion maxima de la
%   tabla 5.3.2-1 de 3GPP TS 38.101-1 (FR1)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [RBxFrame, REperRB, NRB, Nslot] = NR_parametros(BW, TTI, SCS)

if nargin < 3
    SCS = 30e3;
end

SC = 12;        % Subportadoras por RB
Nsimb = 14;     % Simbolos OFDM por slot (prefijo ciclico normal)
REperRB = SC*Nsimb;

mu = log2(SCS/15e3);
slot = 1e-3/2^mu;               % Duracion de un slot en s
Nslot = round(TTI/slot);        % Slots por trama

% TS 38.101-1, tabla 5.3.2-1: N_RB maximo por ancho de banda (MHz)
BWtab = [5 10 15 20 25 30 40 50 60 70 80 90 100];
switch SCS
    case 15e3
        NRBtab = [25 52 79 106 133 160 216 270 NaN NaN NaN NaN NaN];
    case 30e3
        NRBtab = [11 24 38 51 65 78 106 133 162 189 217 245 273];
    case 60e3
        NRBtab = [NaN 11 18 24 31 38 51 65 79 93 107 121 135];
    otherwise
        error('NR_parametros: SCS de %g kHz no soportado', SCS/1e3);
end

i = find(BWtab == BW/1e6, 1);
if isempty(i) || isnan(NRBtab(i))
    error('NR_parametros: ancho de banda de %g MHz no valido con SCS de %g kHz', ...
        BW/1e6, SCS/1e3);
end
NRB = NRBtab(i);
RBxFrame = NRB*Nslot;
end
