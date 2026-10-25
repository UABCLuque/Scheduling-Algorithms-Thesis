%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mediciones y Modelo de Propagacion
%
% Funcion
%
%   P = Modelo_de_canal(freq, dist, pout)          -> espacio libre (FSPL)
%   P = Modelo_de_canal(freq, dist, pout, modelo)  -> modelo seleccionado
%
%   freq    frecuencia portadora en Hz
%   dist    distancia 2D gNB-UE en metros (escalar o vector)
%   pout    potencia transmitida en dBm
%   modelo  modelo de perdidas por trayectoria:
%           'FSPL'           Espacio libre (por defecto)
%           '36942_Urban'    3GPP TR 36.942 macro celda urbana
%           '38901_UMa_LOS'  3GPP TR 38.901 Urban Macro, linea de vista
%           '38901_UMa_NLOS' 3GPP TR 38.901 Urban Macro, sin linea de vista
%           '38901_UMi_LOS'  3GPP TR 38.901 Urban Micro (Street Canyon), LOS
%           '38901_UMi_NLOS' 3GPP TR 38.901 Urban Micro (Street Canyon), NLOS
%
%   No se incluye shadow fading ni probabilidad de LOS: el modelo es
%   determinista en funcion de la distancia.
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function P = Modelo_de_canal(freq, dist, pout, modelo)

if nargin < 4
    modelo = 'FSPL';
end

switch modelo
    case 'FSPL'
        L = PL_FSPL(freq, dist);
    case '36942_Urban'
        L = PL_36942_Urban(freq, dist);
    case '38901_UMa_LOS'
        L = PL_38901_UMa(freq, dist, false);
    case '38901_UMa_NLOS'
        L = PL_38901_UMa(freq, dist, true);
    case '38901_UMi_LOS'
        L = PL_38901_UMi(freq, dist, false);
    case '38901_UMi_NLOS'
        L = PL_38901_UMi(freq, dist, true);
    otherwise
        error('Modelo_de_canal: modelo de perdidas "%s" no reconocido', modelo);
end

P = pout - L;
end


function L = PL_FSPL(freq, dist)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Modelo de propagación de espacio libre
%   PL[dB] = 10*log[(lambda^2 / (4*pi)^2 * d^2)]
%
%   donde:
%   lambda = longitud de onda (c/f)
%   d = distancia
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lambda = physconst('LightSpeed')/freq;
%L = 10 * log10(lambda.^2./(((4*pi).^2)*(dist.^2)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   Modelo de propagación de espacio libre
%   elaborado
%
%   P[dBm] = (Pt*Gt*Gr*lambda^2) / ( (4*pi^2)*(d^2)*ls )
%
%   donde:
%   Pt      es la potencia transmitida.
%   P[dBm]  la potencia recibida en función de la separación TR.
%   Gt      es la ganancia de la antena del transmisor.
%   Gr      la ganancia de la antena del receptor.
%   d       es la distancia de separación TR en metros.
%   ls      es el factor de pérdida del sistema no relacionado con la propagación
%   lambda  es la longitud de onda en metros.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%P = (Pt*Gt*Gr*lambda^2) / ( (4*pi^2)*(d^2)*ls )

% Usando la función modelo de espacio libre de MATLAB
L = fspl(dist, lambda);
end


function L = PL_36942_Urban(freq, dist)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   3GPP TR 36.942, sec. 4.5.2: macro celda en area urbana
%   L = 40(1 - 4e-3*Dhb)*log10(R) - 18*log10(Dhb) + 21*log10(f) + 80
%
%   donde:
%   R   = distancia gNB-UE en km
%   f   = frecuencia portadora en MHz
%   Dhb = altura de la antena del gNB sobre el nivel de los techos, 15 m
%   Con Dhb = 15 m y f = 2 GHz: L = 128.1 + 37.6*log10(R)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Dhb = 15;
dmin = 35;  % Distancia minima gNB-UE en m (TR 36.942, tabla 4.1, macro)

R = max(dist, dmin)/1e3;
f = freq/1e6;
L = 40*(1 - 4e-3*Dhb)*log10(R) - 18*log10(Dhb) + 21*log10(f) + 80;
end


function L = PL_38901_UMa(freq, dist, nlos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   3GPP TR 38.901, tabla 7.4.1-1: Urban Macro (UMa)
%   fc en GHz, distancias en m, valido para 10 m <= d2D <= 5 km
%
%   LOS:
%   PL1 = 28.0 + 22*log10(d3D) + 20*log10(fc)              10 m <= d2D <= d'BP
%   PL2 = 28.0 + 40*log10(d3D) + 20*log10(fc)
%         - 9*log10(d'BP^2 + (hBS - hUT)^2)                 d'BP <= d2D <= 5 km
%   NLOS:
%   PL' = 13.54 + 39.08*log10(d3D) + 20*log10(fc) - 0.6*(hUT - 1.5)
%   PL  = max(PL_LOS, PL')
%
%   d'BP = 4*h'BS*h'UT*fc/c, con h'BS = hBS - hE, h'UT = hUT - hE
%   hBS = 25 m, hUT = 1.5 m, hE = 1 m (sec. 7.4.1, nota 1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hBS = 25;
hUT = 1.5;
hE = 1;
dmin = 10;  % Limite inferior de validez del modelo

c = physconst('LightSpeed');
fc = freq/1e9;
d2D = max(dist, dmin);
d3D = sqrt(d2D.^2 + (hBS - hUT)^2);
dBP = 4*(hBS - hE)*(hUT - hE)*freq/c;

PL1 = 28.0 + 22*log10(d3D) + 20*log10(fc);
PL2 = 28.0 + 40*log10(d3D) + 20*log10(fc) - 9*log10(dBP^2 + (hBS - hUT)^2);
L = PL1;
L(d2D > dBP) = PL2(d2D > dBP);

if nlos
    PLn = 13.54 + 39.08*log10(d3D) + 20*log10(fc) - 0.6*(hUT - 1.5);
    L = max(L, PLn);
end
end


function L = PL_38901_UMi(freq, dist, nlos)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   3GPP TR 38.901, tabla 7.4.1-1: Urban Micro - Street Canyon (UMi)
%   fc en GHz, distancias en m, valido para 10 m <= d2D <= 5 km
%
%   LOS:
%   PL1 = 32.4 + 21*log10(d3D) + 20*log10(fc)              10 m <= d2D <= d'BP
%   PL2 = 32.4 + 40*log10(d3D) + 20*log10(fc)
%         - 9.5*log10(d'BP^2 + (hBS - hUT)^2)               d'BP <= d2D <= 5 km
%   NLOS:
%   PL' = 35.3*log10(d3D) + 22.4 + 21.3*log10(fc) - 0.3*(hUT - 1.5)
%   PL  = max(PL_LOS, PL')
%
%   d'BP = 4*h'BS*h'UT*fc/c, con h'BS = hBS - hE, h'UT = hUT - hE
%   hBS = 10 m, hUT = 1.5 m, hE = 1 m
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hBS = 10;
hUT = 1.5;
hE = 1;
dmin = 10;  % Limite inferior de validez del modelo

c = physconst('LightSpeed');
fc = freq/1e9;
d2D = max(dist, dmin);
d3D = sqrt(d2D.^2 + (hBS - hUT)^2);
dBP = 4*(hBS - hE)*(hUT - hE)*freq/c;

PL1 = 32.4 + 21*log10(d3D) + 20*log10(fc);
PL2 = 32.4 + 40*log10(d3D) + 20*log10(fc) - 9.5*log10(dBP^2 + (hBS - hUT)^2);
L = PL1;
L(d2D > dBP) = PL2(d2D > dBP);

if nlos
    PLn = 35.3*log10(d3D) + 22.4 + 21.3*log10(fc) - 0.3*(hUT - 1.5);
    L = max(L, PLn);
end
end
