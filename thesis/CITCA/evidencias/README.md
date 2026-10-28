# Evidencias de los resultados (paper CITCA)

Esta carpeta reúne los datos que respaldan cada número de la sección 1.4 Resultados de `metodologia.tex`. Todo sale de una sola corrida de `matlab/Caracterizacion.m` en el escenario de buffer infinito (`buffer = 0`), con `rng(1)` antes de cada despachador. El archivo original de resultados es `results/citca/caracterizacion.mat`.

## Archivos

| Archivo | Contenido | Se usa en |
|---|---|---|
| `fig_tp_distancia.pdf` / `.png` | Throughput por UE contra distancia, los cuatro despachadores | Fig. 2 del paper |
| `metricas_globales.csv` | Throughput de la celda, eficiencia espectral e índice de Jain por despachador | Tabla 2 y su párrafo |
| `datos_por_UE.csv` | Por despachador y UE: distancia, RB asignados, % de RB, throughput, CQI mínimo, máximo y promedio de sus RB | Párrafos de la subsección 1.4.1 |
| `justificacion_parametros.md` | Por qué se eligieron los valores de la Tabla 1 | Tabla 1 |

## De dónde salen los porcentajes de RB

En 1 s hay 100 tramas × 500 RB = **50 000 RB**. El simulador guarda qué UE recibió cada RB (`info.alloc`, matriz trama × RB) y cuántos RB recibió cada UE (`info.RB_UE`). El porcentaje es `RB_UE / 50 000 × 100` (columnas `RB_asignados` y `RB_pct` de `datos_por_UE.csv`). Se comprobó que el conteo sobre `alloc` coincide con `RB_UE` para los 160 UE.

El CQI de cada RB se obtiene de los bits que transportó (`info.bits`): bits/RB = 84 × eficiencia de la tabla de CQI de 4 bits (TS 36.213), y se busca la fila correspondiente.

### Por qué varía el CQI de un mismo UE

Las columnas `CQI_min`, `CQI_max` y `CQI_promedio` resumen el CQI de los ~1250 RB que recibió cada UE. El CQI cambia de un RB a otro por el término de interferencia de la ec. (2): I = |N(0, 4 dB)| se sortea de nuevo para cada UE, cada RB y cada trama, y es la única variación del canal entre RB (no hay desvanecimiento rápido).

- `CQI_max` es el CQI casi sin interferencia y depende solo de la distancia (pérdidas por propagación): baja de 15 cerca de la gNB a 9 en el borde.
- Los UE cercanos tienen tanto margen sobre el umbral de CQI 15 que ninguna interferencia los baja de ahí (con RR, mínimo = máximo = 15 hasta 205 m).
- Los UE lejanos tienen menos margen, y algunos de sus RB caen a CQI menores. Por ejemplo, con RR a 487 m el CQI va de 8 a 15, con promedio 13.07.
- RR toma los RB que le tocan con la interferencia que traigan, por eso su rango es amplio. PF prefiere los RB con menor interferencia de cada UE y casi siempre obtiene el CQI sin interferencia (promedio 14.99 a 487 m contra 13.07 de RR). De ahí sale la ventaja de throughput de PF sobre RR.
- BCQI solo atiende a los dos UE junto a la gNB, y todos sus RB están en CQI 15.

## Cada afirmación del texto y su fuente

| Afirmación en el paper | Valor en los datos | Dónde verlo |
|---|---|---|
| RR: cada UE recibe 2.5 % de los RB | 1250 RB (2.50 %) para los 40 UE | `datos_por_UE.csv`, RR |
| RR: 583 kbps hasta ~300 m | 583.2 kbps de 0 a 256 m; 582.1 y 581.1 kbps a 282 y 308 m | RR, UE 1–13 |
| RR: casi todos sus RB en CQI 15 | CQI 15 en todos sus RB hasta 205 m; a 308 m el CQI promedio es 14.96 | columnas CQI |
| RR: 174 kbps en el borde | 173.5 kbps a 1000 m | RR, UE 40 |
| BCQI: el UE junto a la radiobase recibe 93.8 % de los RB (21.9 Mbps) | UE 1 (0 m): 46 909 RB, 93.82 %, 21 887 kbps | BCQI, UE 1 |
| BCQI: el UE a 25.6 m recibe el resto (1.4 Mbps) | UE 2: 3091 RB, 6.18 %, 1442 kbps | BCQI, UE 2 |
| BCQI: 38 UE sin datos | UE 3–40 con 0 RB | BCQI |
| BET: 363 a 369 kbps | 362.8 a 368.7 kbps | BET |
| BET: de 1.6 % (UE más cercano) a 5.3 % (borde) | 1.56 % a 5.31 % | BET, columna `RB_pct` |
| PF: entre 2.42 % y 2.50 % por UE | 2.42 % a 2.50 % | PF |
| PF: 583 kbps hasta 487 m | 583.4–583.7 kbps hasta 487 m; 537 kbps a 513 m | PF, UE 1–21 |
| PF: 253 kbps en el borde, 45 % más que RR | 252.8 contra 173.5 kbps (+45.7 %) | PF y RR, UE 40 |
| PF: escalones por los niveles de CQI | 7 niveles, uno por CQI 15 a 9 | PF, columnas CQI y throughput |
| BCQI: 23.3 Mbps, 4.67 bits/s/Hz, J = 0.03 | 23.33 Mbps, 4.67, 0.028 | `metricas_globales.csv` |
| BET: J = 1.00 con el menor throughput (14.6 Mbps) | 14.64 Mbps, J = 1.000 | `metricas_globales.csv` |
| PF: 19.1 Mbps, 11 % más que RR, J = 0.94 | 19.14 contra 17.21 Mbps (+11.2 %), J = 0.938 | `metricas_globales.csv` |
| RR: J = 0.89 | 0.891 | `metricas_globales.csv` |

Nota: los porcentajes de RB no aparecen en ninguna tabla del paper; están en `datos_por_UE.csv`. Antes la Fig. 1 de las notas tenía un panel con el % de RB por UE, que se quitó (ver `notes/caracterizacion_citca.md`).

## Cómo regenerar

Correr `matlab/Caracterizacion.m`. Genera `results/citca/caracterizacion.mat`, `metricas.csv` y las figuras. Las dos tablas CSV de esta carpeta se calcularon a partir de `infoA` y `metA` de ese `.mat`.
