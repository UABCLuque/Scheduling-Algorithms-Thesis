% Caracterizacion de los despachadores (paper CITCA)
%
% Muestra el funcionamiento de cada despachador en un solo escenario, sin
% barridos (los barridos de Scheduling.m se reservan para otro trabajo).
%   Escenario A: buffer lleno. Throughput y equidad por UE segun la
%                distancia, datos acumulados por UE en el tiempo y
%                equidad de Jain en cada trama.
%   Escenario B: trafico por paquetes (buffer dinamico, como en la
%                metodologia). Retardo segun la distancia y ubicacion de
%                los UE que siguen en espera al final.
% Las figuras (PDF vectorial + PNG) y los datos se guardan en results/citca/.
clc;
close all;
clear;

% Parametros comunes
seed = 1;       % Semilla de rng (misma para cada despachador)
N = 40;         % UE activos (40 UE como en la Fig. 11 de Capozzi 2013)
r = 1000;       % Radio de la celda en m (ver nota en el resumen)
freq = 2.6e9;
Pout = 43;      % Potencia de transmision de la gNB en dBm (Capozzi 2013)
BW = 5e6;       % 5 MHz: menor ancho de banda de NR FR1
TTI = 10e-3;
fi = 0.1;
rdg = 2;        % Distancias equiespaciadas
plm = '38901_UMa_NLOS';

% Escenario A: buffer lleno
framesA = 100;  % 1 s
% Escenario B: paquetes con tamano ~N(Pkg, 0.2 Pkg), UE terminados se reemplazan
framesB = 100;  % 1 s
Pkg = 50e3;     % Valor ilustrativo, no corresponde a una clase de servicio

algNames = {'RR', 'BCQI', 'BET', 'PF'};
algoCalls = {@RR_function, @BCQI_function, @BET_FAST_function, @PF_FAST_function};
nAlg = numel(algoCalls);
markers = {'o', 's', '^', 'd'};
colores = lines(nAlg);

outDir = fullfile('..', 'results', 'citca');
if ~exist(outDir, 'dir')
    mkdir(outDir);
end

% -------------------------------------------------------------------------
% Simulaciones
% -------------------------------------------------------------------------
metA = zeros(nAlg, 5);  % [atp FT Ef delay outt]
metB = zeros(nAlg, 5);
infoA = cell(1, nAlg);
infoB = cell(1, nAlg);
for a = 1:nAlg
    rng(seed);
    [metA(a,1), metA(a,2), metA(a,3), metA(a,4), metA(a,5), infoA{a}] = ...
        algoCalls{a}(N, r, freq, Pout, BW, TTI, 0, Pkg, fi, framesA, rdg, plm);
    rng(seed);
    [metB(a,1), metB(a,2), metB(a,3), metB(a,4), metB(a,5), infoB{a}] = ...
        algoCalls{a}(N, r, freq, Pout, BW, TTI, 3, Pkg, fi, framesB, rdg, plm);
    fprintf('%s listo\n', algNames{a});
end

% -------------------------------------------------------------------------
% Fig. 1: throughput por UE contra la distancia (A)
% -------------------------------------------------------------------------
fig1 = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 8.4 5.5]);
for a = 1:nAlg
    s = infoA{a};
    plot(s.d, s.tp_UE/1e3, ['-' markers{a}], 'Color', colores(a,:), ...
        'MarkerSize', 3, 'LineWidth', 1); hold on;
end
set(gca, 'YScale', 'log');
xlabel('Distancia a la gNB (m)');
ylabel('Throughput por UE (kbps)');
legend(algNames, 'Location', 'northeast', 'NumColumns', 2);
grid on;
estiloPaper(fig1);
exportar(fig1, outDir, 'fig_tp_distancia');

% -------------------------------------------------------------------------
% Fig. 4: equidad, throughput por UE normalizado a la media (A)
% -------------------------------------------------------------------------
% Jain = 1/mean((x_i/mean(x))^2): la linea en 1 es el reparto perfectamente
% equitativo y el indice resume que tanto se alejan los UE de ella
jainA = zeros(1, nAlg);
fig4 = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 8.4 5.5]);
for a = 1:nAlg
    s = infoA{a};
    x = s.tp_UE/mean(s.tp_UE);
    jainA(a) = sum(s.tp_UE)^2/(numel(s.tp_UE)*sum(s.tp_UE.^2));
    plot(s.d, x, ['-' markers{a}], 'Color', colores(a,:), ...
        'MarkerSize', 3, 'LineWidth', 1); hold on;
end
yline(1, 'k--', 'LineWidth', 0.8);
set(gca, 'YScale', 'log');
xlabel('Distancia a la gNB (m)');
ylabel('Throughput / throughput medio');
etiquetas = arrayfun(@(a) sprintf('%s (J = %.2f)', algNames{a}, jainA(a)), 1:nAlg, ...
    'UniformOutput', false);
legend(etiquetas, 'Location', 'north', 'NumColumns', 2, 'AutoUpdate', 'off');
ylim([0.2 2000]);   % Espacio arriba para la leyenda
grid on;
estiloPaper(fig4);
exportar(fig4, outDir, 'fig_equidad_distancia');

% -------------------------------------------------------------------------
% Fig. 5: equidad de Jain en cada trama (A)
% -------------------------------------------------------------------------
% x_i = bits que recibe el UE i en la trama (no acumulados), sobre los N UE
jainTrama = zeros(nAlg, framesA);
fig5 = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 8.4 5.5]);
for a = 1:nAlg
    s = infoA{a};
    nUE = numel(s.d);
    for f = 1:framesA
        sel = s.alloc(f,:) > 0;
        x = accumarray(s.alloc(f,sel)', s.bits(f,sel)', [nUE 1]);
        jainTrama(a,f) = sum(x)^2/(nUE*sum(x.^2));
    end
    plot((1:framesA)*TTI*1e3, jainTrama(a,:), ['-' markers{a}], 'Color', colores(a,:), ...
        'MarkerSize', 3, 'MarkerIndices', 1:10:framesA, 'LineWidth', 1); hold on;
end
xlabel('Tiempo (ms)');
ylabel('Índice de Jain por trama');
legend(algNames, 'Location', 'east', 'NumColumns', 1);
xlim([0 framesA*TTI*1e3]);
ylim([0 1.05]);
grid on;
estiloPaper(fig5);
exportar(fig5, outDir, 'fig_equidad_tiempo');

% -------------------------------------------------------------------------
% Fig. 2: datos acumulados por UE en el tiempo (A), como Capozzi 2013
% -------------------------------------------------------------------------
fig2 = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 8.4 8]);
tl = tiledlayout(fig2, 2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');
cmap = parula(256);
for a = 1:nAlg
    s = infoA{a};
    K = size(s.alloc, 2);
    al = reshape(s.alloc', [], 1);    % RB en orden temporal
    bt = reshape(s.bits', [], 1);
    t = (1:numel(al))' * TTI / K;
    idx = K:K:numel(al);              % Un punto por trama
    nexttile(tl);
    for u = 1:numel(s.d)
        c = cumsum(bt .* (al == u));
        ci = cmap(1 + round(255*s.d(u)/r), :);
        plot([0; t(idx)], [0; c(idx)]/1e6, 'Color', ci, 'LineWidth', 0.6); hold on;
    end
    title(algNames{a}, 'FontWeight', 'normal');
    grid on;
end
xlabel(tl, 'Tiempo (s)', 'FontSize', 8, 'FontName', 'Times New Roman');
ylabel(tl, 'Datos recibidos por UE (Mbit)', 'FontSize', 8, 'FontName', 'Times New Roman');
colormap(fig2, cmap);
cb = colorbar;
cb.Layout.Tile = 'east';
clim([0 r]);
cb.Label.String = 'Distancia a la gNB (m)';
estiloPaper(fig2);
exportar(fig2, outDir, 'fig_datos_tiempo');

% -------------------------------------------------------------------------
% Fig. 3: retardo y UE en espera contra la distancia (B)
% -------------------------------------------------------------------------
edges = 0:200:r;
nb = numel(edges) - 1;
centros = edges(1:end-1) + diff(edges)/2;
delayBin = NaN(nAlg, nb);
esperaBin = zeros(nAlg, nb);
for a = 1:nAlg
    s = infoB{a};
    bin = discretize(s.d, edges);
    fin = isfinite(s.tend);
    D = s.tend - s.tstart;
    for b = 1:nb
        sel = fin & bin == b;
        if any(sel)
            delayBin(a,b) = mean(D(sel));
        end
        esperaBin(a,b) = sum(~fin & bin == b);
    end
end

fig3 = figure('Color', 'w', 'Units', 'centimeters', 'Position', [2 2 8.4 9]);
tl = tiledlayout(fig3, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile(tl);
for a = 1:nAlg
    plot(centros, 1e3*delayBin(a,:), ['-' markers{a}], 'Color', colores(a,:), ...
        'MarkerSize', 3, 'LineWidth', 1); hold on;
end
ylabel('Retardo promedio (ms)');
title('(a)', 'FontWeight', 'normal');
legend(algNames, 'Location', 'northwest', 'NumColumns', 2);
xlim([0 r]);
grid on;

nexttile(tl);
hb = bar(centros, esperaBin', 'grouped', 'EdgeColor', 'none');
for a = 1:nAlg
    hb(a).FaceColor = colores(a,:);
end
xlabel('Distancia a la gNB (m)');
ylabel('UE en espera al final');
title('(b)', 'FontWeight', 'normal');
xlim([0 r]);
grid on;
estiloPaper(fig3);
exportar(fig3, outDir, 'fig_retardo_distancia');

% -------------------------------------------------------------------------
% Metricas de cada escenario y datos para reproducir las figuras
% -------------------------------------------------------------------------
T = table(algNames', metA(:,1)/1e6, metA(:,3), metA(:,2), ...
    metB(:,1)/1e6, metB(:,2), 1e3*metB(:,4), metB(:,5), ...
    'VariableNames', {'Despachador', 'A_Throughput_Mbps', 'A_Ef_bpsHz', 'A_Jain', ...
    'B_Throughput_Mbps', 'B_Jain', 'B_Retardo_ms', 'B_Outage_pct'});
disp(T);
writetable(T, fullfile(outDir, 'metricas.csv'));

param = struct('seed', seed, 'N', N, 'r', r, 'freq', freq, 'Pout', Pout, ...
    'BW', BW, 'TTI', TTI, 'fi', fi, 'rdg', rdg, 'plm', plm, ...
    'framesA', framesA, 'framesB', framesB, 'Pkg', Pkg);
save(fullfile(outDir, 'caracterizacion.mat'), 'param', 'algNames', ...
    'metA', 'metB', 'infoA', 'infoB', 'delayBin', 'esperaBin', 'edges', 'jainTrama');

% -------------------------------------------------------------------------
function estiloPaper(fig)
% Fuente Times de 8 pt, como el texto del formato IFAC
set(findall(fig, '-property', 'FontName'), 'FontName', 'Times New Roman');
set(findall(fig, '-property', 'FontSize'), 'FontSize', 8);
end

function exportar(fig, outDir, nombre)
exportgraphics(fig, fullfile(outDir, [nombre '.pdf']), 'ContentType', 'vector');
exportgraphics(fig, fullfile(outDir, [nombre '.png']), 'Resolution', 300);
end
