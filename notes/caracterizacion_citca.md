# Figuras de caracterización para el artículo CITCA

Script: `matlab/Caracterizacion.m`. Salida: `results/citca/`.

Objetivo: mostrar que cada despachador funciona como se espera, con un solo escenario y sin barridos. El análisis de sensibilidad de `Scheduling.m` se reserva para otro congreso.

## Escenarios

Parámetros comunes: 40 UE (como en la Fig. 11 de Capozzi 2013), r = 1000 m, 5 MHz, 2.6 GHz, Pout = 43 dBm, UMa NLOS, fi = 0.1, distancias equiespaciadas (`rdg = 2`, de 0 a 1000 m en pasos de ~25.6 m), 100 tramas (1 s) y `rng(1)` antes de cada corrida de cada despachador.

- **A: buffer lleno** (`buffer = 0`). Todos los UE tienen siempre datos por recibir. Se usa en las Figs. 1, 2 y 4.
- **B: tráfico por paquetes** (`buffer = 3`), como se describe en la metodología. El tamaño de paquete es ~N(50 kbit, 10 kbit) y cada UE que termina se reemplaza por uno nuevo a una distancia aleatoria, de modo que siempre hay 40 UE activos. Se usa en la Fig. 3.

En el modelo, la SNR de cada UE en cada RB es la potencia recibida (que depende solo de la distancia) menos el ruido y menos un término de interferencia |N(0, FN)| dB, con FN = 40 · 0.1 = 4 dB, que se sortea por UE y por RB. Ese término es la única variación entre RB, y es lo que pueden aprovechar BCQI y PF. Hasta ~300–480 m, los UE quedan en CQI 15 en casi todos los RB.

## Figuras

### Fig. 1: `fig_tp_distancia`, throughput por UE contra la distancia (escenario A)

Una sola gráfica con el throughput promedio de cada UE durante 1 s, en eje logarítmico, contra su distancia a la gNB. Cada despachador es una curva. El reparto de RB ya no se grafica, pero se cita abajo porque explica cada curva (está en `infoA{a}.RB_UE` de `caracterizacion.mat`).

- **RR:** cada UE recibe exactamente 1/40 = 2.5 % de los RB, sin importar su canal. Por eso la curva sigue directamente la calidad del canal. Es plana en ~583 kbps hasta ~310 m (13 UE en CQI 15) y luego cae hasta 174 kbps en el borde (1000 m). Es la referencia: misma porción de recursos y throughput dictado por la distancia.
- **BCQI:** asigna cada RB al UE con mejor SNR, así que solo atiende a los dos UE más cercanos. El UE a 0 m recibe 93.8 % de los RB (21.9 Mbps) y el UE a 25.6 m el 6.2 % restante (~1.4 Mbps). Los otros 38 UE reciben 0 bits y no aparecen en la gráfica, porque el eje logarítmico no dibuja ceros. El texto debe decirlo para que no parezca un error.
- **BET:** iguala el throughput. Todos los UE quedan entre 366.3 y 366.8 kbps, una línea horizontal. Para lograrlo da más RB a quien tiene peor canal: del 1.57 % para el UE más cercano al 5.24 % para el del borde (~3.3×). El precio es que los UE cercanos quedan por debajo de lo que obtienen con RR o PF.
- **PF:** reparte los RB casi igual que RR (entre 2.42 % y 2.50 % por UE), pero a cada UE le asigna sus RB con menos interferencia. Hasta ~310 m coincide con RR, porque ahí todos los RB están en CQI 15 y no hay nada que elegir. A partir de ahí supera a RR: mantiene 583 kbps hasta ~490 m (20 UE) y en el borde obtiene 253 kbps contra 174 kbps de RR (~1.45×). La curva baja en escalones porque el CQI es discreto.
- Mensaje de la figura: RR y PF dan los mismos recursos pero PF los aprovecha mejor. BET sacrifica throughput de los UE cercanos para igualar, y BCQI maximiza el total dejando sin servicio a casi todos.

### Fig. 2: `fig_datos_tiempo`, datos acumulados por UE en el tiempo (escenario A)

Cuatro paneles (RR, BCQI, BET, PF), uno por despachador. Cada línea es un UE: los datos que ha recibido (Mbit) contra el tiempo (s), con un punto por trama de 10 ms. El color indica la distancia a la gNB (barra de color, 0–1000 m). Es el mismo tipo de gráfica que la Fig. 11 de Capozzi 2013. Las escalas verticales son distintas en cada panel.

- Todas las líneas son rectas, porque con buffer lleno y sin movilidad el reparto es estable desde la primera trama, sin transitorios. La pendiente de cada línea es el throughput de la Fig. 1, así que esta figura muestra lo mismo desde el punto de vista temporal y deja ver que el comportamiento se mantiene durante todo 1 s.
- **RR:** abanico ordenado por color. Los UE cercanos (azules) llegan a ~0.58 Mbit y los del borde (amarillos) a ~0.17 Mbit.
- **BCQI:** solo dos líneas crecen, la del UE a 0 m (~21.9 Mbit) y la del UE a 25.6 m (~1.4 Mbit). Las otras 38 se quedan en 0 y se ven como una sola línea amarilla sobre el eje. Su escala (0–25 Mbit) es ~40 veces la de los otros paneles. La explicación está abajo, en "Efectos del modelo en las Figs. 1, 2 y 4".
- **BET:** todas las líneas están encimadas en un solo haz que llega a ~0.37 Mbit, sin importar el color. Es la forma más directa de ver la igualdad de throughput.
- **PF:** se ven menos líneas que en RR porque los 20 UE dentro de ~490 m tienen el mismo throughput y quedan encimados en la línea superior (~0.58 Mbit). Las líneas que se separan son las de los UE lejanos, agrupadas por escalón de CQI, y la más baja llega a ~0.25 Mbit, arriba de las ~0.17 Mbit de RR. Las 40 líneas sí están dibujadas: se enciman porque varios UE tienen exactamente el mismo throughput (ver "Efectos del modelo en las Figs. 1, 2 y 4").

### Efectos del modelo en las Figs. 1, 2 y 4

Ambos efectos vienen de cómo se calcula la SNR por RB: SNR sin interferencia (depende solo de la distancia) menos un término aleatorio |N(0, 4 dB)| que se sortea por UE y por RB. Ese término es la única variación entre RB. No hay desvanecimiento rápido (fast fading).

**PF: las líneas se agrupan en bandas de CQI.** En la Fig. 2, RR tiene 32 valores distintos de throughput final entre sus 40 UE y PF solo 16, agrupados en 7 niveles:

| Throughput PF (kbps) | UE | Distancia (m) | bits/RE | CQI |
|---|---|---|---|---|
| ~583.5 | 20 | 0–487 | 5.555 | 15 |
| ~537.4 | 2 | 513–538 | 5.115 | 14 |
| 475.3 | 3 | 564–615 | 4.523 | 13 |
| ~410 | 4 | 641–718 | 3.902 | 12 |
| ~349 | 4 | 744–821 | 3.322 | 11 |
| ~287 / 277 | 5 | 846–949 | 2.73 | 10 |
| ~253 | 2 | 974–1000 | 2.406 | 9 |

- Cada UE recibe 2.5 % de los RB (1250 RB en 1 s; uno recibió 2.42 %), así que su throughput es 1250 × 84 × bits/RE. Cada nivel coincide exactamente con una fila de la tabla de CQI de LTE: cada UE recibió todos sus RB en un solo valor de CQI.
- Por qué: entre 500 RB por trama, cada UE tiene algunos RB donde el término de interferencia es casi 0. La métrica de PF (bits que llevaría el RB / throughput promedio) prefiere esos RB, y los 40 UE casi no compiten por los mismos. Así, cada UE siempre opera en el CQI de su SNR sin interferencia, que depende solo de la distancia y es discreto. Todos los UE de la misma banda de CQI tienen el mismo throughput y sus líneas se enciman. La línea superior se ve turquesa porque el último UE dibujado de ese grupo (487 m) tapa a los más azules.
- RR, en cambio, toma los RB que le tocan en el ciclo, con la interferencia que traigan. Su throughput es un promedio sobre varios CQI, que cambia de forma continua con la distancia, y por eso sus líneas se separan (aun así, 13 UE cercanos se enciman porque todos sus RB están en CQI 15).
- Es el mismo mecanismo que produce los escalones de PF en las Figs. 1 y 4. Es el comportamiento correcto de PF (aprovecha la diversidad multiusuario), pero también es una limitación del modelo: con desvanecimiento rápido real (p. ej. Rayleigh, distinto por RB y por TTI), los mejores RB de cada UE cambiarían y no siempre estarían en el techo sin interferencia, así que las bandas se difuminarían.
- Aumentar r no lo resuelve: el número de bandas está limitado por los niveles de CQI. Con el modelo actual, la SNR sin interferencia da CQI 15 hasta 500 m, 9 hasta 1040 m, 1 hasta 2830 m y 0 más allá. Con r ≈ 2.8 km se tendrían como máximo 15 bandas (2–3 UE por banda), y cambiarían todos los demás resultados. Se decidió dejar r = 1 km y presentar las bandas como resultado.

**BCQI: solo dos UE reciben servicio.** BCQI asigna cada RB al UE con mayor SNR. El código compara SNR, no tasa (ver la tabla de notación en `CLAUDE.md`), así que el UE más cercano gana aunque otros también estén en CQI 15.

- SNR sin interferencia: 73.2 dB a 0 m, 67.9 dB a 25.6 m y 59.7 dB a 51.3 m.
- El UE a 25.6 m solo gana un RB cuando la interferencia sorteada para el UE a 0 m es mayor que la suya por más de ~5.2 dB. Con |N(0, 4 dB)| eso pasa ~6.3 % de las veces, lo que coincide con el 6.2 % de los RB que recibió en la simulación.
- El UE a 51.3 m ya está 13.4 dB debajo del primero, y la interferencia casi nunca cierra esa diferencia (probabilidad ≈ 0 en 10⁶ sorteos). Los 38 UE restantes nunca ganan un RB y reciben 0 bits.
- Es inanición (starvation) pura: el throughput total es el mayor de los cuatro (23.3 Mbps), pero lo reciben uno o dos UE. En las Figs. 1 y 4 los 38 UE sin servicio no aparecen porque el eje logarítmico no dibuja ceros; en la Fig. 2 se ven como una línea plana en 0.
- En el escenario B (Fig. 3) el efecto es el mismo, pero los UE cercanos terminan su paquete y se reemplazan. Los UE lejanos se van acumulando sin servicio, de ahí los 38 de 40 UE en espera en el intervalo de 800–1000 m.

### Fig. 3: `fig_retardo_distancia`, retardo y UE en espera contra la distancia (escenario B)

Dos paneles, con los UE agrupados en intervalos de 200 m (centros en 100, 300, …, 900 m). Durante 1 s llegaron 312 UE en RR, 395 en BCQI, 311 en BET y 376 en PF (incluidos los 40 iniciales). Más llegadas significa que se terminaron más paquetes.

- **(a) Retardo promedio** de los UE que terminaron su paquete, medido desde su llegada hasta que lo terminan (resolución de 10 ms).

  | Intervalo (m) | 0–200 | 200–400 | 400–600 | 600–800 | 800–1000 |
  |---|---|---|---|---|---|
  | RR (ms) | 95 | 95 | 113 | 164 | 251 |
  | BCQI (ms) | 13 | 16 | 26 | 67 | 306 |
  | BET (ms) | 139 | 142 | 145 | 151 | 161 |
  | PF (ms) | 91 | 97 | 100 | 136 | 184 |

  - BET es la curva más plana (~139–161 ms): al igualar el throughput, un paquete tarda casi lo mismo sin importar la distancia. La ligera subida hacia el borde contrasta con RR (95–251 ms) y PF (91–184 ms).
  - RR y PF crecen con la distancia porque el throughput baja. PF es menor o igual que RR en todos los intervalos, y la diferencia crece hacia el borde (184 contra 251 ms).
  - BCQI tiene el menor retardo cerca de la gNB (~13 ms) y el mayor en el borde (306 ms). Ojo: en el borde solo 37 de 75 UE terminaron, así que ese promedio solo cuenta a los que sí lograron terminar. Por eso se agrega el panel (b).
- **(b) UE en espera al final**: cuántos de los 40 UE activos al terminar la corrida siguen sin terminar su paquete, por intervalo de distancia (barras agrupadas por despachador).

  | Intervalo (m) | 0–200 | 200–400 | 400–600 | 600–800 | 800–1000 |
  |---|---|---|---|---|---|
  | RR | 3 | 5 | 9 | 6 | 17 |
  | BCQI | 0 | 0 | 1 | 1 | 38 |
  | BET | 7 | 9 | 10 | 5 | 9 |
  | PF | 6 | 2 | 7 | 9 | 16 |

  - En BCQI, 38 de los 40 están en el borde: los UE cercanos terminan rápido y se reemplazan, y los lejanos se van acumulando sin servicio. Es la inanición (starvation) de BCQI vista desde el tráfico por paquetes.
  - En BET los UE en espera se reparten de forma pareja en todas las distancias.
  - RR y PF tienen más UE en espera en el borde, pero sin llegar al extremo de BCQI.

### Fig. 4: `fig_equidad_distancia`, equidad por UE contra la distancia (escenario A)

> **Pendiente:** esta gráfica todavía está por actualizarse.

Misma forma que la Fig. 1, pero el eje vertical es el throughput de cada UE dividido entre el throughput medio de su despachador (x_i / x̄, eje logarítmico). El índice de Jain es un solo número por despachador y no se puede graficar contra la distancia. Esta figura muestra lo que el índice resume: J = 1 / promedio((x_i/x̄)²), así que J = 1 solo si todos los UE están sobre la línea punteada en 1, y J baja a medida que los UE se alejan de ella. La leyenda muestra el J de cada despachador, que es el mismo `FT` que calcula el simulador.

- **BET (J = 1.00):** todos los UE están entre 0.99 y 1.01, sobre la línea de equidad perfecta.
- **PF (J = 0.94):** de 1.22 cerca de la gNB a 0.53 en el borde. Se aleja menos de la línea que RR en ambos extremos.
- **RR (J = 0.89):** de 1.36 cerca de la gNB a 0.40 en el borde. Al repartir los RB por igual, la desigualdad de throughput es la del canal.
- **BCQI (J = 0.03):** el UE a 0 m tiene 37.5 veces el throughput medio y el de 25.6 m tiene 2.4 veces. Los 38 restantes valen 0 y, como en la Fig. 1, no se dibujan en el eje logarítmico.
- Mensaje de la figura: el orden de equidad BET > PF > RR > BCQI y de dónde sale. Con RR y PF, los UE cercanos quedan arriba de la media y los lejanos abajo. BET los pone a todos en la media. BCQI concentra todo en uno o dos UE.
- La escala la fija BCQI (hasta 37.5) y la parte superior queda libre para la leyenda, así que RR, PF y BET se ven en una franja angosta (0.4–1.4). Si en el artículo se quiere más detalle en esa franja, otra opción es un eje lineal de 0 a 1.5 con BCQI fuera de escala, indicando su valor en el pie de figura.

### Fig. 5: `fig_equidad_tiempo`, índice de Jain en cada trama (escenario A)

Una sola gráfica con el índice de Jain calculado en cada trama de 10 ms, con x_i = bits que recibe el UE i en esa trama (no acumulados), contra el tiempo (ms). Cada despachador es una curva. Los valores están en `jainTrama` (despachador × trama) de `caracterizacion.mat`.

| | mín | media | máx |
|---|---|---|---|
| RR | 0.864 | 0.890 | 0.916 |
| BCQI | 0.027 | 0.028 | 0.030 |
| BET | 0.996 | 0.999 | 1.000 |
| PF | 0.923 | 0.936 | 0.946 |

- Las cuatro curvas son estables desde la primera trama y quedan en el mismo nivel que su J global de la Fig. 4, en el orden BET > PF > RR > BCQI. Es decir, la equidad de cada despachador no es solo un promedio de 1 s: se cumple en cada trama.
- **BET** queda en ~1 en todas las tramas: iguala el throughput también dentro de cada trama de 10 ms, no solo al final.
- **PF** se mantiene en ~0.94, arriba de RR, con muy poca variación.
- **RR** oscila en zigzag (0.86–0.92) porque 500 RB / 40 UE = 12.5 RB por UE, así que en cada trama unos UE reciben 12 y otros 13.
- **BCQI** queda en ~0.03 en todas las tramas: los mismos dos UE reciben todo, trama tras trama.
- Antes de corregir BET (ver "Cambios en el código"), su índice por trama bajaba de 0.99 a ~0.65 con oscilaciones cada vez mayores, aunque su J global era 1.00.

`metricas.csv` tiene las métricas globales de ambos escenarios, y `caracterizacion.mat` los parámetros y los datos por UE. Las demás métricas no aparecen en ninguna figura (solo el J del escenario A, en la leyenda de la Fig. 4): aun para un solo escenario se parecen a la comparación que se reserva para el otro congreso.

## Por qué estos parámetros

- **r = 1 km en lugar de 500 m (Capozzi 2013).** Con r = 500 m y 20–40 UE, todos los RB están en CQI 15, así que RR, BET y PF dan resultados idénticos. Con 100 UE a 5 MHz, el 66 % de los RB sigue en CQI 15, y PF alcanza el throughput de BCQI con equidad ≈ 1, lo que parece un resultado final más que una caracterización. Con 1 km los UE cubren CQI ~7–15. El artículo debe mencionar y justificar este cambio.
- **5 MHz** es el menor ancho de banda de NR FR1, y su número de RB (500 por trama) es correcto. A 1.4 MHz el código usa 140 RB por trama, mientras que LTE tiene 120.
- **50 kbit** es un valor ilustrativo. No corresponde a ningún requisito de eMBB/URLLC/mMTC.

## Pendiente para el texto del artículo

- Agregar una tabla de parámetros.
- Agregar una frase que presente el escenario de buffer lleno: la metodología solo describe tráfico por paquetes.
- Justificar r = 1 km.
- Aclarar en las Figs. 1 y 4 que los UE de BCQI sin servicio (throughput 0) no se dibujan en el eje logarítmico.
- Decidir el orden de las figuras: la Fig. 4 (equidad) va naturalmente junto a la Fig. 1 (throughput).
- Actualizar la gráfica de equidad (Fig. 4, `fig_equidad_distancia`).

## Cambios en el código

- Cada función de despachador (`RR_function`, `BCQI_function`, `BET_FAST_function`, `PF_FAST_function`) tiene una 6.ª salida opcional, `info`, con datos por UE:
  - distancia, bits recibidos, RB asignados, tiempos de llegada y de término, throughput;
  - el mapa de asignación RB→UE y los bits que lleva cada RB asignado (trama × RB).
- La distancia de los UE que llegan durante la corrida ahora se guarda en `d`.
- Las primeras 5 salidas no cambian, así que `Scheduling.m` funciona igual que antes.
- **Corrección de BET (`BET_FAST_function.m`).** `ri` era `BET_metric`, los bits *acumulados* de cada UE. Con `a = 0.99999`, `Ri` era un promedio muy lento de un total acumulado, así que la métrica integraba dos veces y el reparto llegaba en ráfagas cada vez mayores. Ahora `ri` son los bits del último RB asignado (tasa instantánea), como en la definición usual de BET. Efecto con `rng(1)`:
  - Escenario A: casi sin cambios (throughput 14.64 → 14.66 Mbps, J 0.99999 → 1.00000). Las Figs. 1, 2 y 4 se ven igual. Solo cambia la Fig. 5.
  - Escenario B: retardo medio 137 → 148 ms, outage 0.20 → 0.10 %, llegadas 327 → 311. Parte de la diferencia puede ser solo otra realización aleatoria, porque con otro reparto los números aleatorios se consumen en otro orden.
  - También cambian los resultados de BET en `Scheduling.m` (README §6 y §7.4).
- La Fig. 1 antes tenía un panel extra con el porcentaje de RB por UE. Se quitó, y el archivo se renombró de `fig_rb_tp_distancia` a `fig_tp_distancia`.

## Advertencias

- **No se necesitan toolboxes.** El MATLAB local (R2026b) no tiene Phased Array ni Statistics Toolbox. El código activo (`Modelo_de_canal.m` y las cuatro funciones de despachador) usa equivalentes de MATLAB base: `c = 299792458` en lugar de `physconst`, la fórmula de FSPL en lugar de `fspl`, y `mu + sigma*randn` en lugar de `normrnd` (que calcula exactamente eso, así que los resultados con semilla no cambian). Las líneas originales quedan comentadas junto con una nota. Al volver a correr, `metricas.csv` salió idéntico al generado antes con los sustitutos externos.
- **Problemas conocidos de README §7.2 que afectan al escenario B:**
  - BET y PF reinician el historial de todos los UE cada vez que llega uno nuevo.
  - El retardo solo cuenta a los UE que terminaron; el panel 3(b) lo compensa en parte.
  - Los tiempos se registran por trama de 10 ms.
- **Una sola corrida.** Cada resultado viene de una corrida con semilla, sin promediar varias realizaciones.
