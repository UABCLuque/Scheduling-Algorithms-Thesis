# CLAUDE.md

## Overview
Master's thesis: **"Evaluación de despachadores en redes celulares"**. It evaluates four basic downlink schedulers (Round Robin, Best CQI / Max C/I, Blind Equal Throughput, Proportional Fair) against throughput, fairness (Jain), spectral efficiency, delay and outage. The goal is to find, with sensitivity plots, the network conditions under which each scheduler best meets the requirements of the three 5G traffic classes (eMBB, URLLC, mMTC).
- **The thesis is the main project.** The MATLAB code supports it with simulations.
- Scope: **5G and beyond**. The simulator deliberately uses an LTE-A-like resource scheme as an approximation, because LTE-A and 5G NR share most of the resource structure. The thesis must state and justify this simplification.
- Author: Manuel Luque. University: Universidad Autónoma de Baja California (UABC). Program: [TODO]. Advisors: Guillermo Galaviz and Ángel Andrade. Deadline: [TODO]. LaTeX template: [TODO, the author will look for the university one].

## Repository structure
- `thesis/`: Word draft `5to_Borrador.docx` (current source of the text). `chapters/` is empty, intended for the LaTeX migration.
- `matlab/`: simulator. See the MATLAB section.
- `references/references.bib`: bibliography built from the draft's list. Each entry has a `% [n]` comment with its number in the Word draft, and unverified fields are marked `% TODO`.
- `references/papers/`: 74 PDFs of cited/candidate sources (git-ignored, read-only).
- `results/`: empty. Figure/data export location and format not decided yet [TODO].
- `notes/`: empty. Working notes.
- `README.md`: detailed description of the simulator, known code issues (§7) and the fixes applied (§7.4).

## Writing conventions
- Thesis text is **always in Spanish**, formal academic register, mostly impersonal ("se realizan simulaciones…", "en este trabajo…").
- Citations: numbered `[n]` in the text, pointing to an IEEE-style list in the final "Referencias" section (Spanish labels: "[En línea]. Disponible:"). In LaTeX this is done with `\cite{key}` plus a `.bib` file and the IEEE bibliography style, which generates the numbers and the list automatically. Keys in `references/references.bib` follow `authorYEAR` (e.g. `capozzi2013`); look up a draft number via its `% [n]` comment. Only add entries whose metadata is verified (PDF or user-provided).
- Migration Word → LaTeX is in progress.
- Terminology: despacho/despachador/estrategia de despacho (scheduling/scheduler), radiobase (gNB), UE, RB, RE, equidad (fairness), eficiencia espectral. Use **"throughput"**, not "caudal". Algorithm names stay in English (Round Robin, Best CQI, BET, PF).
- The draft still contains author notes to self (e.g. "Debo convertirlo en un capitulo", "Todo es muy general"). These are pending tasks, not thesis text.

## Notation: draft vs MATLAB
| Concept | Draft | MATLAB | Note |
|---|---|---|---|
| Distance UE–gNB | d | `d` (per UE), `r` cell radius | |
| Path loss | FSPL = (4πdf/c)² | `Modelo_de_canal(freq, d, Pout, plm)`: `'FSPL'` (default), `'36942_Urban'`, `'38901_UMa_LOS/NLOS'`, `'38901_UMi_LOS/NLOS'`; `Scheduling.m` uses `'38901_UMa_NLOS'` | ⚠ draft only describes FSPL; TR 38.901 / TR 36.942 not in `references.bib` yet |
| Rx power | P_señal (dBm) | `pot = Pout - L` | |
| Noise power | −174 dBm/Hz + 10·log10(B) | `Tn + 10*log10(BW)` | consistent (no noise figure) |
| SNR (dB) | P_señal − (−174 + 10log10 B) | `SNR = pot-(Tn+10*log10(BW)) - I` | ⚠ draft eq. drops the minus sign on 174 |
| Interference | P_interferencia inside SINR | `I = abs(normrnd(0, FN))`, `FN = Qty_UE*fi` (dB, subtracted) | ⚠ draft sums noise+interference in dB (should be linear); draft labels SINR as "SNR" |
| Bandwidth | B | `BW` | |
| Users | n | `Qty_UE` (grows as new users arrive) | |
| RB / RE | RB = 12 subcarriers × 7 symbols, 0.5 ms | `data = bRE*84` | consistent |
| TTI | 2 × 0.5 ms = 1 ms | `TTI = 10e-3` (a full frame) | ⚠ inconsistent |
| RBs per frame | — | `RBxFrame = (BW/1e6)*5*20` | ⚠ 140 at 1.4 MHz, LTE has 120 |
| CQI → bits/RE | 3GPP CQI tables (cites TS 38.214) | `CQI.m`: LTE 4-bit table (TS 36.213), `bRE = CR*Qm`, no BW scaling | ⚠ code uses the LTE table; SNR→CQI thresholds need a source |
| RR metric | m = t − T_i (eq. 1) | cyclic pointer in `RR_function.m` | equivalent in intent |
| Max C/I metric | argmax r_i(t) (eq. 2) | `argmax SNR(:,k)` per RB | ⚠ code ranks SNR, not rate |
| BET metric | no equation in draft | `1 ./ Ri`, `Ri = a*Ri_old + (1-a)*ri`, `ri` = bits of the RB just assigned (instantaneous rate), `a = 0.99999` | draft needs an equation |
| PF metric | argmax r_i(t)/R_i(t) (eq. 3) | `Cap ./ Ri`, `Cap = CQI(SNR)*84` (bits the RB would carry), β = `a = 0.5` | consistent |
| Spectral eff. | Ef = C_d / B | `Ef = atp/BW` | consistent |
| Jain fairness | (Σx_i)² / (n·Σx_i²) | `FT` over per-UE throughput `tp_UE = sumData ./ t_UE` (t_UE = time in the cell) | draft must state x_i = per-user throughput (needs a source); n includes late-arriving users |
| Throughput | C_d | `atp` (bps) | |
| Delay / outage | latencia | `delay` (mean over UEs that finished, 10 ms resolution, `Inf` if none), `outt` (% of unfinished UEs with 0 bits per frame) | outage not defined in draft; delay definition pending |
- ⚠ The draft describes 5G NR (FR1 starts at 5 MHz, SCS 15–240 kHz). The simulator uses LTE-A values (2.6 GHz, 1.4/3/5 MHz, 15 kHz SCS, LTE CQI table) by design (see Overview). The thesis should say so explicitly.
- ⚠ The simulator has no eMBB/URLLC/mMTC traffic classes yet. They are planned, with per-class requirements taken from the literature (sources still to be chosen; never invent the values).

## Chapter outline (from `5to_Borrador.docx`)
1. **Capítulo 1** (introduction): evolution 1G→6G, spectrum. *Estrategias de despacho y categorías de uso*. *Problema de investigación*. *Trabajos relacionados* (author note: turn into its own chapter). *Objetivos* (general + 3 specific).
2. **Capítulo 2 – Fundamentos**: 3GPP and Releases (NR, FR1/FR2, SCS, slot table, physical channels). 1. Estructura de recursos en LTE y 5G NR. 2. Modelo de canal y SNR (FSPL, SNR/SINR, noise, CQI, BLER). Estrategias de despacho (metrics; RR, Max C/I, BET, PF).
3. **Metodología**: only an intro paragraph plus notes (model, flowcharts, per-scheduler plots).
4. **Resultados**: empty (notes: evaluation, comparison).
5. **Discusión**: notes only (why the user distribution; review interference and Shannon capacity).
6. **Referencias** (in progress): [2]–[52]. Numbers 1, 3, 7, 14, 33, 35 are missing, and [43]–[52] are titles only.

## MATLAB (`matlab/`)
- **Main script: `Scheduling.m`.** It runs three one-at-a-time sweeps over the four schedulers (44 runs, a single realisation each, no `rng` seed):
  - `Qty_UE` ∈ {50,100,150,200,250} (BW 1.4 MHz, Pkg 5 kbit)
  - `BW` ∈ {1.4,3,5} MHz (100 UEs, 5 kbit)
  - `Pkg` ∈ {1,2,10} kbit (100 UEs, 1.4 MHz)
  - Packet sizes are placeholders until the eMBB/URLLC/mMTC requirements are sourced.
- Fixed parameters: `r=500` m and `Pout=43` dBm (both from `capozzi2013`), `freq=2.6e9`, `plm='38901_UMa_NLOS'`, `TTI=10e-3`, `fi=0.1`, `frames=5` (50 ms), `buffer=3` (dynamic, packet ~N(Pkg, 0.2·Pkg), finished UEs replaced), `rdg=2` (evenly spaced distances).
- Schedulers (common signature `[atp, FT, Ef, delay, outt] = f(Qty_UE, r, freq, Pout, BW, TTI, buffer, Pkg, fi, frames, rdg, plm)`, `plm` optional, default `'FSPL'`):
  - RR → `RR_function.m`
  - Best CQI → `BCQI_function.m`
  - BET → `BET_FAST_function.m`
  - PF → `PF_FAST_function.m`
- Helpers: `CQI.m` (SNR→bits/RE), `Modelo_de_canal.m` (selectable path-loss model, see README §2.1).
- Legacy, not called and not updated with the October 2026 fixes: `BET_function.m`, `PF_function.m`, `Scheduling_2.m`, `Scheduling_3.m`, `Scheduling - Copy.txt`, `Despachadores individuales/`.
- Run: in MATLAB, `cd matlab` and then `Scheduling`. Needs `fspl`/`physconst` (Phased Array System Toolbox).
- **Figures are not exported.** `Scheduling.m` opens 7 figures (3 throughput-vs-fairness plots, metrics vs Qty_UE, outage vs Qty_UE, metrics vs BW, metrics vs Pkg) but saves nothing. Export location/format: [TODO].
- Open issues that affect the plotted results (details in `README.md` §7): BET/PF reset `Ri` on every arrival; delay averages only finished UEs (`Inf` if none); times are recorded per 10 ms frame; SNRs are still optimistic (no shadowing, noise figure or real interference; ~83 % of RBs at CQI 15); `Pkg`/`frames` are placeholders.
- Fixed in October 2026 (README §7.4): noise used 20·log10(BW); `CQI.m` scaled bits/RE by `mag2db(BW)`; CQI 15 threshold used `>`; PF numerator was Shannon capacity; BET/PF delay was always 0; BET/PF outage counted finished UEs; fairness was Jain over total bits; BET's `ri` was the accumulated bits instead of the instantaneous rate (per-frame fairness drifted down to ~0.65).

## Rules
- Never invent references, citation keys, data or simulation results. If a claim needs a source, say so and leave `[CITA REQUERIDA]`.
- Ask before rewriting existing paragraphs. Propose changes (diff or alternative text) instead.
- Keep thesis equations consistent with the MATLAB implementation. When they diverge, flag it and don't silently "fix" either side.
- Don't modify anything in `references/papers/`.
- Thesis text is always in Spanish. Code comments may stay as they are (Spanish).
- Numbers quoted in the thesis must come from a reproducible run (seeded `rng`, saved output in `results/`).
