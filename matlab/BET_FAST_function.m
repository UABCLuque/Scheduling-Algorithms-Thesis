
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Algoritmo de despacho Blind Equal Throughput en
% donde se asigna recursos priorizando el fairness
% sin importar la eficiencia
%
% Este es una combinacion de BET_1 y BET_2 en el que
% se utiliza el valor de rizo
%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [atp, FT, Ef, delay, outt] = BET_FAST(Qty_UE, r, freq, Pout, BW, TTI, buffer, Pkg, fi, frames, rdg, plm)

% Modelo de perdidas por trayectoria (ver Modelo_de_canal.m)
if nargin < 12
    plm = 'FSPL';
end
%tic

%Modificar solamente cantidad de UE
%Qty_UE = 20;
%r = 1;

%Calculo de las distancias entre UEs y gNB

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
%d = normrnd(0.5,0.1,1,Qty_UE);
%d = r*(linspace(0,1,Qty_UE));

%d = [0.5 1 1.5 2 2.5]; %Debug

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
RXGn = 10; % Ganancia en dB del amplificador del UE en dB. No se usa

Tn = -174;   % Ruido termico 174dB/Hz
%BW = 3e6;  % 1.4, 3, 5, 10, 15 o 20MHz el BW del canal
%TTI = 10e-3; % Tiempo de un frame en LTE en s
SC = 72;     % Numero de subcarriers

%https://helpfiles.keysight.com/csg/89600B/Webhelp/Subsystems/lte/content/lte_overview.htm
%https://www.rfwireless-world.com/calculators/LTE-Resource-Block-Calculator.html
RBxFrame = (BW/1e6)*5*20;

%Variable para indicar si es buffer finito(1), infinito (0) o dinamico (2) 
%o dinamico random (3)
%frames = 50;
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
    Ps = normrnd(Pkg, Pkg*fp, 1, Qty_UE);
else
    var_lg = frames + 1;
    Ps = Inf(1,Qty_UE);
end

RBenBW = 0;
f = 0;
FirstRun = 1;
aux_var = 1;
vSNR = zeros(Qty_UE, RBxFrame);
%Ri = zeros(Qty_UE, RBxFrame);
%Ri = 0;
data = zeros(Qty_UE, RBxFrame);
contRB = 0;
sumData = zeros(1,Qty_UE);
BET_metric = zeros(1,Qty_UE);
sumCap = zeros(Qty_UE,1);
Ri = zeros(Qty_UE,1);
dataRate = zeros(Qty_UE,1);
RB_UE = zeros(Qty_UE,1);
UE_time = zeros(1,Qty_UE);
UE_tstart = zeros(1,Qty_UE);
UE_tend = Inf*ones(1, Qty_UE);
UE_tp = zeros(1, Qty_UE);
aux = 0;
Qty_outt = 0;

active_UE = 0;
Active_QtyUE = Qty_UE;
numTTI = 0;
tp = 0;
FN = Qty_UE * fi;
a = 0.99999; %Parece BET
%a = 0;  %Round Robin (o PF?)

while(f == 0)

    UE_done = find(vSNR(:,1) == 999);
    BET = zeros(1,RBxFrame);
    dataxTTI = zeros(1,Qty_UE);

for w = 1:RBxFrame
    I = abs(normrnd(0, FN, [1, Qty_UE]));
    %I = 0; %Debug
    SNR = pot-(Tn+10*log10(BW)) - I;
    vSNR(:,w) = SNR;
end

if(UE_done ~= 0)
    vSNR(UE_done,:) = 999;
end

%disp('SNR en dB con el cual se calcula el CQI de cada RB')
%disp(vSNR)

numTTI = numTTI + 1;

%**************************************************************************
%******************Loop para asignar recursos en un Frame******************
%**************************************************************************

for k = 1:RBxFrame

    contRB = contRB+1;

    if(aux_var)
        Ri(:, contRB) = sumData;
    else
        %ri(:,contRB) = sumData;
        %ri(:,contRB) = UE_tp;
        %ri(:,contRB) = BET_metric;
        ri = BET_metric';
        %Ri(:,contRB) = a*Ri(:, contRB-1) + (1-a)*ri(:, contRB);
        %Ri(:,contRB) = a*Ri(:, contRB-1) + (1-a)*ri;
        Ri = a*Ri_old + (1-a)*ri;
    end

    %disp("Tasa de datos promedio Ri(t)")
    %disp(Ri(:,k))
    %disp(Ri)
    %pause;
    
    mBET = 1 ./ Ri;
    %disp(mBET)
    Ri_old = Ri;

    % Condicion para no asignar recursos a usuario que ya completo su
    % transmisión

    UE_done = find(vSNR(:,1) == 999);

    if(UE_done ~=0)
        %mBET(UE_done, contRB) = -999;   %Negativo porque la formula de Min_BET busca el max
        mBET(UE_done) = -999;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if(FirstRun)
        Min_BET = 1;
    else
        %Min_BET = find(mBET(:, contRB) == max(mBET(:, contRB)));
        Min_BET = find(mBET == max(mBET));
        %active_UE = find(UE_tp == min(UE_tp));
        %disp("UE con peor metrica de PF")
        %disp(Min_PFM)
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    aux_var = 0;
    active_UE = Min_BET;

    % Condicion por si 2 UE o más tienen la misma métrica mínima de PF. Se
    % hace RR (se atiende al primero)
    if(length(active_UE>1))
        active_UE = active_UE(randi(length(active_UE)));
    end

    %disp("Siguiente usuario a despachar:")
    %disp(active_UE)

    SNRenRB = vSNR(:,k);
    SNR_UE = SNRenRB(active_UE);

    %Funcion de CQI
    bRE = CQI(SNR_UE, BW); %Por algun motivo no funciona

    data(active_UE, k) = bRE*84; %El 84? 84 RE en un RB de LTE?
    %disp("Datos")
    %disp(data(active_UE, k))

    %disp("Capacidad")
    %disp(Cap(active_UE, k))

    sumData(active_UE) = sumData(active_UE) + data(active_UE,k);
    dataxTTI(active_UE) = dataxTTI(active_UE) + data(active_UE,k);
    BET_metric(active_UE) = BET_metric(active_UE) + data(active_UE,k);
    RB_UE(active_UE) = RB_UE(active_UE)+1;

    UE_tp(active_UE) = UE_tp(Active_QtyUE) + (data(active_UE,k)/TTI);

    %disp("Suma de datos por usuario")
    %disp(sumData);

    DONE = sumData>=Ps;
    f = prod(DONE);

    if(f == 1)
        break;
    end

    BET(k) = active_UE;

    if sumData(active_UE) >= Ps(active_UE)
        %disp("DONE")
        %pause;
        vSNR(active_UE,:) = 999;
        sumCap(active_UE) = Inf;
        UE_tend(active_UE) = numTTI*TTI;
        %PFM(active_UE,:) = 999;
        if(buffer == 2 || buffer == 3)
            Qty_UE = Qty_UE + 1;
            d2 = r*rand;
            for w = 1:RBxFrame
                I = abs(normrnd(0, FN));
                %I = 0;
                pot2 = Modelo_de_canal(freq, d2, Pout, plm);
                SNR2 = pot2-(Tn+10*log10(BW)) - I; %SNR siempre debe degradar la señal
                vSNR2(w) = SNR2;
            end
            pot(Qty_UE) = pot2;
            vSNR(Qty_UE, :) = vSNR2;
            data(Qty_UE, :) = zeros(1,RBxFrame);
            %BET_metric(Qty_UE) = mean(sumData);
            BET_metric = ones(1,Qty_UE)*mean(BET_metric);
            sumData(Qty_UE) = 0;
            hdata(Qty_UE,:) = zeros(1,numTTI);
            dataxTTI(Qty_UE) = 0;
            %gtp(Qty_UE, :) = zeros(1,var_lg);
            Cap(Qty_UE, :) = 0;
            %Ri(:, length(Ri)) = 0;
            %Ri(Qty_UE, :) = 0;
            %Ri_old(Qty_UE, :) = 0;
            Ri(Qty_UE, :) = mean(Ri);
            Ri_old(Qty_UE, :) = mean(Ri_old);
            Ri = ones(Qty_UE,1) * mean(Ri);
            Ri_old = ones(Qty_UE,1) * mean(Ri_old);
            ri(Qty_UE, :) = 0;
            dataRate(Qty_UE) = 0;
            htp(Qty_UE, :) = 0;
            gtp(Qty_UE, :) = 0;
            RB_UE(Qty_UE) = 0;
            UE_tstart(Qty_UE) = (numTTI-1)*TTI;
            UE_tend(Qty_UE) = Inf;
            UE_tp(Qty_UE) = 0;
            %Ri = zeros(Qty_UE,1);

            if(buffer == 3)
                %Ps(Qty_UE) = Pkg*rand;
                %Ps(Qty_UE) = Pkg;
                Ps(Qty_UE) = normrnd(Pkg, Pkg*fp);
            else
                Ps = Pkg * ones(1, Qty_UE);
            end
            Active_QtyUE = Qty_UE - length(find(vSNR(:,1) == 999));
        end
    end
    
    FirstRun = 0;
 end

%**************************************************************************
%**************************************************************************

%disp(BET)
%numTTI = numTTI + 1;
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

%FPF es la variable que tiene la matriz de todos los recursos asignados
FPF(numTTI,:) = BET; 

%Throughput
tp = dataxTTI / TTI;
dataRate = sumData / (TTI*numTTI);
atp = sum(sumData) / (TTI * numTTI); 
hdata(:,numTTI+1) = sumData;
htp(:,numTTI+1) = UE_tp;
gtp(:,numTTI+1) = tp;

%disp("Throughput en b/s en el TTI")
%disp(tp);

%Fairness segun Jains index en cada frame con base en los datos
F = (sum(dataxTTI))^2 / ((Active_QtyUE) * sum(dataxTTI.^2));
gF(:,numTTI+1) = F;

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

% disp("Tiempo transcurrido en s")
% disp(numTTI*TTI);

%disp("Throughput en todos los TTI por usuario")
%disp(htp)

%disp("Fairness en todos los TTI")
%disp(gF)

% disp("Throughput de la red (b/s)")
% disp(atp)
% 
% disp('Jains Index Fairness')
% disp(FT)

%Throughput total
%Resultado de throughput total es incorrecto, solo funcionaría si fuera
%buffer infinito. De lo contrario se necesita calcular el throughput hasta
%que cada usuario deje de ser atendido, de manera que el tiempo de
%transmisión considerado para calcular el thoughput de cada usuario sería
%diferente
%tpt = sum(sumData) / (TTI*numTTI);
% tpt = sum(htp,"all");
% disp('Throughput total (bps)')
% disp(tpt)

%Eficiencia espectral (throughput total entre el ancho de banda del canal)
%Resultado de eficiencia espectral es incorrecto, solo funcionaría si fuera
%de buffer infinito, de lo contrario se necesita realizar un cálculo de
%t
% Ef = tpt/BW;
% disp('Eficiencia espectral (bps/Hz)')
% disp(Ef)
Ef = ((sum(sumData))/(numTTI*TTI)) / BW;
% disp('Eficiencia espectral (bps/Hz)')
% disp(Ef)
% 
 delay = mean(delay);
% disp('Delay promedio (s)')
% disp(delay)
% 
% disp('Probabilidad de Interrupción')
% disp(outt)

%toc
end

%y = 0:TTI:(length(gF)-1)*TTI;%was htp

% %Grafica de throughput
% % figure(1)
% % set(gcf,'Color','w')
% % plot(y,htp)
% % title('Throughput por usuario')
% % xlabel('Tiempo (s)')
% % ylabel('Throughput (b/s)')
% % legend(str);
% % grid on;
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
% plot(y,hdata, 'Marker', '.')
% title('Blind Equal Throughput')
% xlabel('Tiempo (s)')
% ylabel('Datos (bits)')
% %ylim([0 12e7])
% legend(str);
% grid on;
% 
% % Nueva gráfica de Throughput vs Fairness
% figure(4)
% set(gcf,'Color','w')
% plot(gF, htp, 'o');
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
