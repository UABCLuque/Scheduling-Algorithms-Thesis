# Justificación de los parámetros de simulación (Tabla 1)

Este texto acompaña a la Tabla 1 del paper. Se quitó del artículo para acortarlo. Las referencias numéricas son las de `references.bib`.

## Número de UE: N = 40

Es el número de usuarios de la Fig. 11 de Capozzi et al. (2013), que compara despachadores en una sola celda. Usar el mismo valor facilita comparar el comportamiento cualitativo con esa referencia.

## Radio de la celda: r = 1 km

Capozzi et al. (2013) usan r = 500 m. Con el modelo de canal de este simulador, la SNR sin interferencia da CQI 15 hasta unos 500 m y CQI 9 hasta unos 1040 m (`notes/caracterizacion_citca.md`). Por eso:

- Con r = 500 m y 20 a 40 UE, todos los RB quedan en CQI 15. En ese caso RR, BET y PF entregan los mismos resultados, y no se puede distinguir a los despachadores.
- Con r = 1 km, los UE van desde CQI 15 cerca de la radiobase hasta CQI 9 en el borde (ver las columnas de CQI en `datos_por_UE.csv`). Así aparecen las diferencias entre despachadores.
- Un radio mayor (≈ 2.8 km) daría más niveles de CQI, pero cambiaría todos los demás resultados. Se decidió mantener 1 km.

## Potencia de transmisión: P_tx = 43 dBm

Es el valor que usan Capozzi et al. (2013) para la radiobase.

## Modelo de pérdidas: 3GPP TR 38.901, UMa NLOS

Es el modelo estándar de 3GPP para una macrocelda urbana, que corresponde a una radiobase que cubre un radio de 1 km. Se usa la variante NLOS (sin línea de vista) por ser el caso más común en una zona urbana. **Falta agregar la referencia de TR 38.901 al `.bib`.**

## Ancho de banda: B = 5 MHz

Es el menor ancho de banda de NR en FR1. Con 5 MHz hay 25 RB por ranura de 0.5 ms y 500 RB por trama de 10 ms, que es el número de RB que usa el código.

## Frecuencia portadora: 2.6 GHz

**Pendiente de justificar con una fuente.** No se encontró en las notas de dónde sale este valor; conviene citar la banda o el artículo en que se basa.

## Factor de interferencia: f_I = 0.1

El término de interferencia es |N(0, σ_I)| dB con σ_I = N · f_I = 40 · 0.1 = 4 dB, y se sortea para cada UE y cada RB. Es la única variación del canal entre RB, porque el modelo no incluye desvanecimiento rápido. **Pendiente de justificar con una fuente.**

## Distribución de los UE

Los UE se colocan equiespaciados entre 0 y r (cada 25.6 m con r = 1 km), con la ec. (1) del paper. Así cada distancia aparece una vez y la Fig. 2 se puede leer directamente como throughput contra distancia.

## Tráfico: buffer infinito

Todos los UE tienen siempre datos por recibir y permanecen en la celda durante toda la simulación. Así, el reparto de RB depende solo del despachador y del canal, y no del tamaño de los paquetes ni de la llegada de UE nuevos. El simulador también tiene un modo de tráfico por paquetes (`buffer = 3`), que se dejó fuera del artículo.

## Duración: 100 tramas (1 s) y semilla fija

Cada despachador se simula 100 tramas de 10 ms. Antes de cada despachador se reinicia el generador con `rng(1)`, así que los cuatro ven la misma interferencia y las diferencias se deben solo al despachador.

## Limitaciones

- Sin desvanecimiento rápido: la ventaja de PF sobre RR depende del término de interferencia.
