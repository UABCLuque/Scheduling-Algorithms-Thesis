
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Algoritmo de despacho Max CQI
% 
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [atp, FT, Ef, delay, outt, info] = BCQI(Qty_UE, r, freq, Pout, BW, TTI, buffer, Pkg, fi, frames, rdg, plm)

% Modelo de perdidas por trayectoria (ver Modelo_de_canal.m)
if nargin < 12
    plm = 'FSPL';
end
%tic

% Se definen los UE en coordenadas XYZ. El gNB se ubica en el centro y en
% el suelo
% gNB(0,0,0)

%UE = [2 1 1 ; 3 0 0; 3 0 1];

%Modificar solamente cantidad de UE
%Qty_UE = 20;
%r = 1;

% Qty_UE = size(UE,1);
% UE1 = UE(1,:);
% UE2 = UE(2,:);
% UE3 = UE(3,:);

%Calculo de las distancias entre UEs y gNB

% d1 = sqrt( (UE1(1)-0)^2 + (UE1(2)-0)^2 + (UE1(3)-0)^2 );
% disp('Distancia entre UE1 y gNB en m')
% disp(d1)
% 
% d2 = sqrt( (UE2(1)-0)^2 + (UE2(2)-0)^2 + (UE2(3)-0)^2 );
% disp('Distancia entre UE2 y gNB en m')
% disp(d2)
% 
% d3 = sqrt( (UE3(1)-0)^2 + (UE3(2)-0)^2 + (UE3(3)-0)^2 );
% disp('Distancia entre UE3 y gNB en m')
% disp(d3)

% Generacion de distancias de forma aleatoria
% En "The impact of scheduling algorithms for real-time traffic in the 5G
% femto-cells network" se usa una distribución uniforme
% En "Performance Evaluation of Proportional Fairness Scheduling in MmWave
% Network" se usa distribucion uniforme.

switch rdg
    case 0
        d = r*abs(randn(1,Qty_UE));   %Generacion de distancias con distribucion normal
    case 1
        d = r*rand(1,Qty_UE);     %Generacion de distancias con distribucion uniforme
    case 2
        d = r*(linspace(0,1,Qty_UE));   %Generacion de distancias con distribucion uniforme perfecta
end

%d = r*rand(1,Qty_UE);     %Generacion de distancias con distribucion uniforme
%d = randn(1,Qty_UE);   %Generacion de distancias con distribucion normal
%d = [1.1 1.15 1.2 1.25 1.3]; %Debug
%d = ones(1,Qty_UE);
%d = normrnd(0.5,0.1,1,Qty_UE);
%d = r*(linspace(0,1,Qty_UE));

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
%RXGn = 10; % Ganancia en dB del amplificador del UE en dB

Tn = -174;   % Ruido termico 174dB/Hz
%BW = 3e6;  % 1.4, 3, 5, 10, 15 o 20MHz el BW del canal
%TTI = 10e-3; % Tiempo de un frame en LTE en s
SC = 72;     % Numero de subcarriers

%https://helpfiles.keysight.com/csg/89600B/Webhelp/Subsystems/lte/content/lte_overview.htm
%https://www.rfwireless-world.com/calculators/LTE-Resource-Block-Calculator.html
RBxFrame = (BW/1e6)*5*20;

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

%Bandera que indica que ya terminaron de atenderse
f = 0;

vSNR = zeros(Qty_UE, RBxFrame);
data = zeros(Qty_UE, RBxFrame);
contRB = 0;
sumData = zeros(1,Qty_UE);
UE_start = zeros(1,Qty_UE);
FN = Qty_UE * fi;
UE_time = zeros(1,Qty_UE);
UE_tstart = zeros(1,Qty_UE);
UE_tend = Inf*ones(1, Qty_UE);
UE_tp = zeros(1, Qty_UE);
RB_UE = zeros(Qty_UE,1);
aux = 0;
Qty_outt = 0;

numTTI = 0;
Active_QtyUE = Qty_UE;

gtp = zeros(Qty_UE,var_lg);
%gF = zeros(Qty_UE,var_lg);
gF = zeros(1,Qty_UE);

% Para BEST CQI el loop mayor representará cada TTI

% Se calculará el SNR para todos los usuarios en cada RB del TTI y se le
% asignarán recursos al que tenga mejor CQI

while(f == 0)

    UE_done = find(vSNR == -999);
    MCQI = zeros(1,RBxFrame);
    dataxTTI = zeros(1,Qty_UE);

for w = 1:RBxFrame
    % normrnd requiere Statistics Toolbox (no disponible); mu + sigma*randn es equivalente
    %I = abs(normrnd(0, FN, [1, Qty_UE]));
    I = abs(FN*randn(1, Qty_UE));
    %I = 0;
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

    mSNR = sprintf('SNR en RB %d',k);
    %disp(mSNR)
    %disp(vSNR(:,k))

    SNRenRB = vSNR(:,k);
    SNRmax = max(SNRenRB);
    active_UE = find(SNRenRB == SNRmax);

    %disp("Usuario con mejor CQI:")
    %disp(active_UE)
    
    %Funcion de CQI
    bRE = CQI(SNRmax, BW);
    contRB = contRB+1;

    data(active_UE, k) = bRE*84; %El 84? 84 RE en un RB de LTE
    FBits(numTTI, k) = data(active_UE(1), k); % Bits del RB asignado
    %disp(data)

    % if(length(sumData) ~= length(data(k)))
    %     disp('Check')
    % end

    sumData(active_UE) = sumData(active_UE) + data(active_UE,k);
    dataxTTI(active_UE) = dataxTTI(active_UE) + data(active_UE,k);
    RB_UE(active_UE) = RB_UE(active_UE)+1;

    %disp("Suma de datos por usuario")
    %disp(sumData);

    if sumData(active_UE) >= Ps(active_UE)
        %disp("DONE")
        %vSNR(active_UE,:) = -999;
        UE_tend(active_UE) = numTTI*TTI;
        if(buffer == 2 || buffer == 3)
            Qty_UE = Qty_UE + 1;
            d2 = r*rand;
            d(Qty_UE) = d2; % Distancia del UE que llega
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
        vSNR(active_UE,:) = -999;
    end

    DONE = sumData>=Ps;
    f = prod(DONE);

    if(f == 1)
        break;
    end

    MCQI(k) = active_UE;

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

%disp(MCQI)

%FRR es la variable que tiene la matriz de todos los recursos asignados
FRR(numTTI,:) = MCQI; 

%Throughput
tp = dataxTTI / TTI;                %Este es el throughput de cada usuario en un TTI
atp = sum(sumData) / (TTI * numTTI); %Este es el throughput de la red
gtp(:,numTTI+1) = tp;

%disp("Throughput en b/s")
%disp(tp);

hdata(:,numTTI+1) = sumData;

%Fairness segun Jains index
F = (sum(dataxTTI))^2 / ((Active_QtyUE) * sum(dataxTTI.^2));  %Fairness en cada TTI
%gF(:,numTTI+1) = F;
gF(numTTI+1) = F;

%disp("Fairness")
%disp(F)

%Condicion para buffer infinito
if(buffer ~=1 && numTTI>=frames)
    f = 1;
end

end

% Fairness de Jain sobre el throughput de cada UE (bits / tiempo en la celda)
%FT = (sum(sumData))^2 / ((Qty_UE) * sum(sumData.^2));  %Fairness de la red
t_UE = min(UE_tend, numTTI*TTI) - UE_tstart;
tp_UE = sumData ./ t_UE;
FT = (sum(tp_UE))^2 / ((Qty_UE) * sum(tp_UE.^2));

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

%outt = (Qty_outt/Qty_UE)*100;
outt = mean(outt_TTI);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% disp("Tiempo transcurrido en s")
% disp(numTTI*TTI);
% 
% %disp("Throughput en todos los TTI por usuario")
% %disp(gtp)
% 
% %disp("Fairness en todos los TTI")
% %disp(gF)
% 
% disp("Throughput de la red (b/s)")
% disp(atp)
% 
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%toc
end

%y = 0:TTI:(length(gF)-1)*TTI;%was gtp

% %Grafica de throughput
% 
% figure(1)
% set(gcf,'Color','w')
% plot(y,gtp)
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
% 
% figure(3)
% set(gcf,'Color','w')
% plot(y,hdata, 'Marker','.')
% title('Max C/I')
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