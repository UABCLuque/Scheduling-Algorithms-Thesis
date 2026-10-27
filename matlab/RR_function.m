
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Algoritmo de despacho Round Robin
% 
%   LTE frame structure
%   - Un RB esta compuesto por 12 subcarriers de 15KHz c/u
%   - Y 7 simbolos OFDM (Lo cual es un slot y tiene una duracion de 0.5ms)
%   - 12 subcarriers * 7 simbolos OFDM = 84 resource elements en un RB
%   - Un simbolo son los 12 subcarriers en 0.5ms/7 de tiempo
%   - Un frame son 10ms en un ancho de banda determinado (1.4, 3, 5, 10, 15
%   o 20MHz)
%   - https://helpfiles.keysight.com/csg/89600B/Webhelp/Subsystems/lte/content/lte_overview.htm
%
%   5G NR frame structure
%   - Ancho de banda variable del RB gracias al subcarrier spacing
%   - Latencia dismuinuya en medida que aumenta el SCS
%   - https://www.3g4g.co.uk/5G/5Gtech_video0022_01.pdf
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [atp, FT, Ef, delay, outt, info] = RR(Qty_UE, r, freq, Pout, BW, TTI, buffer, Pkg, fi, frames, rdg, plm)

% Modelo de perdidas por trayectoria (ver Modelo_de_canal.m)
if nargin < 12
    plm = 'FSPL';
end
%tic

% Se definen los UE en coordenadas XYZ. El gNB se ubica en el centro y en
% el suelo
% gNB(0,0,0);

%UE = [2 1 1 ; 3 0 0; 3 0 1];

%Modificar solamente cantidad de UE
%Qty_UE = 20;
%r = 1;  %radio de la celda
%Qty_UE = round(2*pi*r^2);

%Generacion de distancias de forma aleatoria

switch rdg
    case 0
        d = r*abs(randn(1,Qty_UE));   %Generacion de distancias con distribucion normal
    case 1
        d = r*rand(1,Qty_UE);     %Generacion de distancias con distribucion uniforme
    case 2
        d = r*(linspace(0,1,Qty_UE));   %Generacion de distancias con distribucion uniforme perfecta
end

%d = normrnd(0.5,0.1,1,Qty_UE);
%d = [0.5 1 1.5 2 2.5]; %Debug
%d = [0.2858 0.7572 0.7537 0.3804 0.5678]; %Debug

% Frecuencia a la que se realiza la comunicacion para el modelo de canal
% https://es.wikipedia.org/wiki/Bandas_de_frecuencias_LTE
%freq = 2.6e9;

%Potencia de transmisión del UE al gNB en dBm
%Pout = 0;
%disp('Potencia con la que transmite el UE en dBm')
%disp(Pout)

% Se ingresan los datos del gNB a la funcion del modelo de canal.
pot = Modelo_de_canal(freq, d, Pout, plm);   %calcular distancia
%disp('Potencia recibida por la gNB en dBm')
%disp(pot)
%RXGn = 10; % Ganancia en dB del amplificador del UE en dB. No se usa

Tn = -174;      % Ruido termico 174dB/Hz
%BW = 3e6;      % 1.4, 3, 5, 10, 15 o 20MHz el BW del canal
%TTI = 10e-3;    % Tiempo de un frame en LTE
SC = 12;        % Numero de subcarriers
SCS = 15e3;     %Subcarrier spacing de 15KHz en LTE (fijo)
slot = 0.5e-3;  %Duracion de un slot

%https://helpfiles.keysight.com/csg/89600B/Webhelp/Subsystems/lte/content/lte_overview.htm
%https://www.rfwireless-world.com/calculators/LTE-Resource-Block-Calculator.html
RBxFrame = (BW/1e6)*5*20; %20 slots en un frame de 10ms

%Variable para indicar si es buffer finito(1), infinito (0) o dinamico (2)
%o dinamico random (3)
%frames = 100;
%Pkg = 10e6;
%buffer = 3;
fp = 0.2;

if(buffer == 1)
    Ps = Pkg * ones(1, Qty_UE);
    var_lg = 15;
elseif(buffer == 2)
    var_lg = frames + 1;
    Ps = Pkg * ones(1, Qty_UE);
elseif(buffer == 3)
    var_lg = frames + 1;
    %Ps = Pkg*rand(1,Qty_UE);
    %Ps = Pkg * ones(1, Qty_UE);
    % normrnd requiere Statistics Toolbox (no disponible); mu + sigma*randn es equivalente
    %Ps = normrnd(Pkg, Pkg*fp, 1, Qty_UE);
    Ps = Pkg + Pkg*fp*randn(1, Qty_UE);
else
    var_lg = frames + 1;
    Ps = Inf(1,Qty_UE);
end

%Bandera que indica que ya terminaron de atenderse todos los usuarios
f = 0;

vSNR = zeros(Qty_UE, RBxFrame);
data = zeros(Qty_UE, RBxFrame);
contRB = 0;
sumData = zeros(1,Qty_UE);
UE_time = zeros(1,Qty_UE);
UE_start = zeros(1,Qty_UE);
FN = Qty_UE * fi;
%FRR = zeros(1,RBxFrame);
UE_time = zeros(1,Qty_UE);
UE_tstart = zeros(1,Qty_UE);
UE_tend = Inf*ones(1, Qty_UE);
UE_tp = zeros(1, Qty_UE);
RB_UE = zeros(Qty_UE,1);
aux = 0;
Qty_outt = 0;
outt_TTI = 0;

active_UE = 0;
numTTI = 0;
Active_QtyUE = Qty_UE;
auxd = 1;

gtp = zeros(Qty_UE,var_lg);
%gF = zeros(Qty_UE,var_lg);
gF = zeros(1,Qty_UE);


%%%%%DEBUG%%%%%%%%%
tic
countFrames = 0;

while(f == 0)
    %DEBUG
    %countFrames = countFrames + 1;

    UE_done = find(vSNR == -999);
    RR = zeros(1,RBxFrame);
    dataxTTI = zeros(1,Qty_UE);

for w = 1:RBxFrame
    % normrnd requiere Statistics Toolbox (no disponible); mu + sigma*randn es equivalente
    %I = abs(normrnd(0, FN, [1, Qty_UE]));
    I = abs(FN*randn(1, Qty_UE));
    %I = 0; %Debug
    SNR = pot-(Tn+10*log10(BW)) - I; %SNR siempre debe degradar la señal
    vSNR(:,w) = SNR;
end

vSNR(UE_done) = -999;
%disp('SNR en dB con el cual se calcula el CQI de cada RB')
%disp(vSNR)

numTTI = numTTI + 1;

%**************************************************************************
%******************Loop para asignar recursos en un Frame******************
%**************************************************************************

for k = 1:RBxFrame

    %mSNR = sprintf('SNR en RB %d',k);
    %disp(mSNR)
    %disp(vSNR(:,k))

    while(1)
        if(active_UE+1 > Qty_UE)
            active_UE = 0; %Error de SNR donde se quiere alojar un UE con numero 0
        end
        if(vSNR(active_UE+1,:) ~= -999)
            active_UE = active_UE + 1;
            break;
        else
            active_UE = active_UE + 1;
        end
    end

    %disp("Siguiente usuario a despachar:")
    %disp(active_UE)

    SNRenRB = vSNR(:,k);
    SNR_UE = SNRenRB(active_UE);

    %Funcion de CQI
    bRE = CQI(SNR_UE, BW);
    contRB = contRB+1;

    data(active_UE, k) = bRE*84; %El 84? 84 RE en un RB de LTE
    FBits(numTTI, k) = data(active_UE(1), k); % Bits del RB asignado
    %disp(data)

    sumData(active_UE) = sumData(active_UE) + data(active_UE,k);
    dataxTTI(active_UE) = dataxTTI(active_UE) + data(active_UE,k);
    UE_tp(active_UE) = UE_tp(Active_QtyUE) + (data(active_UE,k)/TTI);
    RB_UE(active_UE) = RB_UE(active_UE)+1;

    %disp("Suma de datos por usuario")
    %disp(sumData);

    if sumData(active_UE) >= Ps(active_UE)
        countFrames = countFrames + 1;
        %disp("DONE")
        vSNR(active_UE,:) = -999;
        UE_tend(active_UE) = numTTI*TTI;
        if(buffer == 2 || buffer == 3)
            Qty_UE = Qty_UE + 1;
            d2 = r*rand;
            d(Qty_UE) = d2; % Distancia del UE que llega
            %d2 = d(auxd);
            %auxd = auxd+1;
            %d(Qty_UE) = d2;
            for w = 1:RBxFrame
                % normrnd requiere Statistics Toolbox (no disponible); mu + sigma*randn es equivalente
                %I = abs(normrnd(0, FN));
                I = abs(FN*randn);
                %I = 0;
                pot2 = Modelo_de_canal(freq, d2, Pout, plm);
                SNR2 = pot2-(Tn+10*log10(BW)) - I; %SNR siempre debe degradar la señal
                vSNR2(w) = SNR2;
            end
            pot(Qty_UE) = pot2;
            vSNR(Qty_UE, :) = vSNR2;
            data(Qty_UE, :) = zeros(1,RBxFrame);
            sumData(Qty_UE) = 0;
            hdata(Qty_UE,:) = zeros(1,numTTI);
            dataxTTI(Qty_UE) = 0;
            gtp(Qty_UE, :) = zeros(1,var_lg);
            UE_tstart(Qty_UE) = (numTTI-1)*TTI;
            UE_tend(Qty_UE) = Inf;
            UE_tp(Qty_UE) = 0;
            RB_UE(Qty_UE) = 0;
            
            if(buffer == 3)
                %Ps(Qty_UE) = Pkg*rand;
                %Ps(Qty_UE) = Pkg;
                % normrnd requiere Statistics Toolbox (no disponible); mu + sigma*randn es equivalente
                %Ps(Qty_UE) = normrnd(Pkg, Pkg*fp);
                Ps(Qty_UE) = Pkg + Pkg*fp*randn;
            else
                Ps = Pkg * ones(1, Qty_UE);
            end
            Active_QtyUE = Qty_UE - length(find(vSNR(:,1) == -999));
        end
    end

    DONE = sumData>=Ps;
    f = prod(DONE);

    if(f == 1)
        break;
    end

    RR(k) = active_UE;

end

UE_time = abs(UE_tend-UE_tstart);
aux_data = dataxTTI;

for st = 1:Qty_UE
    C(st) = {sprintf('UE %d',st)};

    if(find(UE_done == st))
        UE_tp(st) = sumData(st)/(UE_time(st));
        aux_data(st) = 1;
    else
        UE_tp(st) = sumData(st)/abs(UE_tstart(st)-(numTTI*TTI));
    end
end

str = string(C);
outt_TTI(numTTI) = (length(find(aux_data == 0))/Qty_UE)*100;

%**************************************************************************
%**************************************************************************

%disp(RR);

%FRR es la variable que tiene la matriz de todos los recursos asignados
FRR(numTTI,:) = RR; 

%Throughput
tp = dataxTTI / TTI;
atp = sum(sumData) / (TTI * numTTI); 
gtp(:,numTTI+1) = tp;

%disp("Throughput en b/s")
%disp(tp);

hdata(:,numTTI+1) = sumData;

%Fairness segun Jains index
%REVISAR
F = (sum(dataxTTI))^2 / ((Active_QtyUE) * sum(dataxTTI.^2));
%gF(:,numTTI+1) = F;
gF(numTTI+1) = F;

%disp("Fairness")
%disp(F)

%Condicion para buffer infinito
if(buffer ~=1 && numTTI>=frames)
    f = 1;
end

end
%%DEBUGGGGG%%
toc
disp(['Frames simulados: ', num2str(countFrames)]);


for g = 1:Qty_UE
    if(find(UE_time(g) ~= Inf))
        aux = aux+1;
        delay(aux) = UE_time(g);
    else
        Qty_outt = Qty_outt + 1;
    end
end

if ~exist('delay', 'var')
    delay = inf;
end

%if(1)   %El que no transmite nada
%    Qty_outt = mean(outt_TTI);

%outt = (Qty_outt/Qty_UE)*100; 
outt = mean(outt_TTI);

%disp("Tiempo transcurrido en s")
%disp(numTTI*TTI);

%disp("Throughput en todos los TTI")
%disp(gtp)

%disp("Fairness en todos los TTI")
%disp(gF)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% disp("Throughput de la red (b/s)")
% disp(atp)
% 
% %Fairness según la métrica de Jain
 % Fairness de Jain sobre el throughput de cada UE (bits / tiempo en la celda)
 %FT = (sum(sumData))^2 / ((Qty_UE) * sum(sumData.^2));
 t_UE = min(UE_tend, numTTI*TTI) - UE_tstart;
 tp_UE = sumData ./ t_UE;
 FT = (sum(tp_UE))^2 / ((Qty_UE) * sum(tp_UE.^2));
% disp('Jains Index Fairness')
% disp(FT)
% 
 Ef = ((sum(sumData))/(numTTI*TTI)) / BW;
% disp('Eficiencia espectral (bps/Hz)')
% disp(Ef)
% 
 delay = mean(delay);

% Datos por UE para caracterizar el despachador (salida opcional)
info.d = d;                 % Distancia de cada UE a la gNB (m)
info.sumData = sumData;     % Bits recibidos por UE
info.RB_UE = RB_UE';        % RB asignados por UE
info.tstart = UE_tstart;    % Llegada de cada UE (s)
info.tend = UE_tend;        % Fin del paquete (Inf si no termino)
info.tp_UE = tp_UE;         % Throughput por UE (bps)
info.alloc = FRR;          % UE asignado a cada RB (trama x RB)
info.bits = FBits;          % Bits del RB asignado (trama x RB)
% disp('Delay promedio (s)')
% disp(delay)
% 
% disp('Probabilidad de Interrupción')
% disp(outt)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%toc
end

%y = 0:TTI:(length(gF)-1)*TTI;

% %Grafica de Throughput
% 
% figure(1)
% set(gcf,'Color','w')
% plot(y,gtp);
% %plot(y, gtp(1:Qty_UE, 1:numTTI+1)); % Asegurarse de graficar todos los usuarios
% title('Throughput por usuario')
% xlabel('Tiempo (s)')
% ylabel('Throughput (b/s)')
% legend(str);
% grid on;
% 
% %Grafica de Fairness
% 
% figure(2)
% set(gcf,'Color','w')
% p = plot(y,gF);
% title('Jains Index Fairness')
% xlabel('TTI')
% ylabel('Fairness')
% grid on;
% 
% %Grafica de datos historico
% figure(3)
% set(gcf,'Color','w')
% plot(y,hdata, 'Marker','.');
% title('Round Robin')
% xlabel('Tiempo (s)')
% ylabel('Datos (bits)')
% %ylim([0 12e7])
% legend(str);
% grid on;
% 
% % Nueva gráfica de Throughput vs Fairness
% figure(4)
% set(gcf,'Color','w')
% plot(gF, gtp, 'o');
% title('Throughput vs Fairness')
% ylabel('Throughput (b/s)')
% xlabel('Fairness (Jains Index)')
% grid on;
% 
% figure(5)
% set(gcf,'Color','w')
% histogram(UE_time,0:0.1:numTTI*TTI)
% title('Histograma de tiempo por UE')
% ylabel('Cantidad de UEs')
% xlabel('Tiempo (s)')
% grid on;