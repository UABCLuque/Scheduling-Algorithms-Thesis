# Scheduling-analysis

Scheduling algorithms on cellular networks. This MATLAB project simulates a simplified LTE-like downlink cell and compares four resource-block (RB) schedulers: **Round Robin (RR)**, **Best CQI (BCQI)**, **Blind Equal Throughput (BET)** and **Proportional Fair (PF)**. It reports throughput, fairness, spectral efficiency, delay and outage, and shows how each one changes with the number of users, the channel bandwidth and the packet size.

The script to run is **`matlab/Scheduling.m`**. All files listed below are in `matlab/`.

---

## 1. Project layout

| File | Role |
|---|---|
| `Scheduling.m` | **Main script.** Runs the three parameter sweeps, calls every scheduler and draws all the figures. |
| `RR_function.m` | Round Robin scheduler (used by `Scheduling.m`). |
| `BCQI_function.m` | Best CQI / Max C/I scheduler (used). |
| `BET_FAST_function.m` | Blind Equal Throughput scheduler (used). |
| `PF_FAST_function.m` | Proportional Fair scheduler (used). |
| `CQI.m` | Maps an SNR (dB) to a CQI index and returns the bits carried per resource element. |
| `Modelo_de_canal.m` | Channel model with a selectable path-loss model (free space, 3GPP TR 36.942, 3GPP TR 38.901 UMa/UMi). Returns received power in dBm. |
| `BET_function.m`, `PF_function.m` | Earlier, slower versions of BET and PF. **Not called** by `Scheduling.m`, and not updated with the fixes below. |
| `Scheduling_2.m`, `Scheduling_3.m`, `Scheduling - Copy.txt` | Earlier versions of the main script. Not needed to reproduce the current results. |
| `Despachadores individuales/` | Standalone script versions of each scheduler, from before they were turned into functions. Kept for reference, not updated. |

All four scheduler functions share one signature:

```matlab
[atp, FT, Ef, delay, outt] = <scheduler>(Qty_UE, r, freq, Pout, BW, TTI, buffer, Pkg, fi, frames, rdg, plm)
```

`plm` (path-loss model) is optional. Without it, the function uses free-space loss (`'FSPL'`).

---

## 2. Common simulation model (shared by every scheduler)

Each scheduler function contains its own copy of the same environment. Only the rule that decides **which user gets the next RB** differs between them.

### 2.1 Users and channel
- The gNB sits at the origin. `Qty_UE` users are placed at distances `d` from it, chosen by `rdg`:
  - `0`: `|N(0,1)|·r` (half-normal)
  - `1`: `U(0,1)·r` (uniform random)
  - `2`: `linspace(0,1,Qty_UE)·r`, evenly spaced from 0 to r. **This is the one `Scheduling.m` uses**, so the starting positions are the same in every run.
- **Path loss** (`Modelo_de_canal.m`): received power = `Pout − PL(d)` (dBm). The path-loss model is chosen with `plm`:

  | `plm` | Model | Notes |
  |---|---|---|
  | `'FSPL'` (default) | Free space, MATLAB `fspl(d, λ)` | Far too optimistic for a macro cell (20 dB/decade). |
  | `'36942_Urban'` | 3GPP TR 36.942 §4.5.2, urban macro: `40(1−4e-3·Dhb)log10(R) − 18log10(Dhb) + 21log10(f) + 80` | R in km, f in MHz, Dhb = 15 m. Gives 128.1 + 37.6·log10(R) at 2 GHz. Minimum distance 35 m. |
  | `'38901_UMa_LOS'`, `'38901_UMa_NLOS'` | 3GPP TR 38.901 Table 7.4.1-1, Urban Macro | hBS = 25 m, hUT = 1.5 m, hE = 1 m. NLOS = max(LOS, NLOS'). Distances below 10 m are clamped to 10 m. |
  | `'38901_UMi_LOS'`, `'38901_UMi_NLOS'` | 3GPP TR 38.901 Table 7.4.1-1, Urban Micro (Street Canyon) | hBS = 10 m, hUT = 1.5 m, hE = 1 m. Same clamping. |

  The 3GPP models are deterministic: no shadow fading and no LOS probability. Every user is either LOS or NLOS, depending on the model chosen.
- **SNR per user per RB:**
  `SNR = P_rx − (−174 + 10·log10(BW)) − I`
  where `I = |N(0, FN)|` is a random interference/fading term with `FN = Qty_UE · fi`. **Interference grows with the number of users**, so adding users lowers everyone's SNR. A fresh SNR value is drawn for every user on every RB in every frame, so the channel varies quickly and independently over time and frequency. There is no receiver noise figure.

### 2.2 Link adaptation (`CQI.m`)
The SNR is mapped onto the 4-bit CQI table (3GPP TS 36.213, CQI 1–15: QPSK → 16QAM → 64QAM), which gives `bRE = code rate × bits/symbol`, the bits carried by one resource element (0.1523 for CQI 1 up to 5.5547 for CQI 15). Below −6.7 dB the CQI is 0 and nothing is sent. `bRE` does **not** depend on the bandwidth: BW enters only through the number of RBs per frame. The data carried by one RB is
`data = bRE · 84` (84 resource elements = 12 subcarriers × 7 OFDM symbols), i.e. ≈ 466.6 bits at CQI 15.

The `BW` argument of `CQI` is kept for compatibility with the callers but is unused (`~`).

### 2.3 Frame structure
- `TTI = 10 ms` is a full LTE **frame**, which is the scheduling round in this model.
- RBs per frame: `RBxFrame = (BW/1 MHz) · 5 · 20`, i.e. 5 RBs per MHz × 20 slots of 0.5 ms. That gives 140, 300 and 500 RBs for 1.4, 3 and 5 MHz.
- Inside a frame, the RBs are handed out **one at a time** (loop over `k = 1:RBxFrame`). Each RB goes to exactly one user.

### 2.4 Traffic / buffer model (`buffer`)
- `1`: finite buffer. Every user has `Pkg` bits, and the run ends when all are delivered.
- `2`: dynamic. When a user finishes, a new user with `Pkg` bits arrives at a random distance.
- `3`: **dynamic with random sizes, used by `Scheduling.m`.** Each user's packet is `N(Pkg, 0.2·Pkg)` bits. When a user finishes, it is removed and a new one arrives (random distance, new random packet size). The number of active users therefore stays at `Qty_UE`, but the total number of users seen during the run grows.
- `0`: infinite (full) buffer.

For every `buffer ≠ 1` the run stops after `frames` frames (`frames = 5`, i.e. **50 ms of simulated time**).

---

## 3. The schedulers

### 3.1 Round Robin: `RR_function.m`
Users take turns in a fixed cyclic order: RB *k* goes to the next active user after the one served last, and finished users are skipped. The channel is ignored completely.
- **Expected behaviour:** very fair in RB count, but it gives RBs to users in deep fades and wastes them, so throughput is moderate. When `Qty_UE` exceeds the RBs per frame, some users get nothing in a frame.

### 3.2 Best CQI (Max C/I): `BCQI_function.m`
For each RB, the scheduler picks the user with the **highest SNR on that RB**: `active_UE = argmax SNR(:,k)`. Finished users are excluded.
- **Expected behaviour:** maximum cell throughput and spectral efficiency, because every RB uses the best available modulation. Fairness is very poor: users near the gNB get almost everything and users at the cell edge are starved (high outage).

### 3.3 Blind Equal Throughput: `BET_FAST_function.m`
Picks the user with the **lowest average throughput so far**, regardless of the channel:
- `R_i(t) = a·R_i(t−1) + (1−a)·r_i`, where `r_i` is the user's accumulated bits and `a = 0.99999`.
- Metric `m_i = 1 / R_i`, and the RB goes to `argmax m_i`. Ties (for example several users who have not been served yet, `R_i = 0 → m_i = ∞`) are broken at random.
- **Expected behaviour:** high fairness, because it tries to equalise throughput across users. Throughput is the lowest, because users with a bad channel get as many bits as users with a good one and therefore need many more RBs.

### 3.4 Proportional Fair: `PF_FAST_function.m`
Balances channel quality against past service:
- Instantaneous rate per RB: `r_i(t) = CQI(SNR_i)·84`, the bits that RB would actually carry for user *i* (stored in `Cap`).
- Average rate: `R_i(t) = β·R_i(t−1) + (1−β)·dataRate_i` with `β = 0.5`, where `dataRate_i = bits_i / (time since user i arrived)`.
- Metric `m_i = r_i(t) / R_i(t)`, and the RB goes to `argmax m_i` (random tie-break).
- Because `r_i` saturates at CQI 15 just like the real rate, users above 22.7 dB all look equally good and PF serves whoever has received less. Users with a worse channel are served when their average falls far enough below the others' (e.g. a CQI 10 user wins once its average is below ≈ 60 % of a CQI 15 user's).
- **Expected behaviour:** the middle ground. Throughput close to BCQI and fairness at least as high as RR/BET.

---

## 4. Metrics (returned by every scheduler)

| Output | Name | How it is computed | Unit |
|---|---|---|---|
| `atp` | Average cell throughput | Total bits delivered to all users / simulated time (`numTTI · TTI`) | bps |
| `FT` | Fairness | **Jain's index over each user's throughput**: `(Σx_i)² / (N · Σx_i²)` with `x_i = bits_i / t_i`, where `t_i` is the time user *i* spent in the cell (arrival to finish, or to the end of the run). 1 = perfectly equal; 1/N = one user gets everything. N includes users that arrived during the run. | 0–1 |
| `Ef` | Spectral efficiency | `atp / BW` | bps/Hz |
| `delay` | Average delay | Mean of `(finish time − arrival time)` over the users that **completed** their packet. Resolution is one frame (10 ms). `Inf` if no user finished. | s |
| `outt` | Outage | For each frame, the % of users still waiting for data that received **0 bits** in that frame (not scheduled, or scheduled at CQI 0), averaged over frames. Users that have already finished are not counted as outage. | % |

Note that `Ef` is just `atp` divided by a constant whenever BW is fixed, so in the user-count and packet-size sweeps the efficiency curve has exactly the same shape as the throughput curve.

With an infinite buffer (`buffer = 0`) every user is in the cell for the whole run, and the throughput-based fairness is identical to Jain's index over total bits. The two differ only when users finish and are replaced: the old version penalised users that arrived late and had little time to be served.

---

## 5. What `Scheduling.m` does (main script)

`Scheduling.m` is the experiment driver. It does no scheduling itself: it sets up the parameters, runs three **one-at-a-time sweeps** over all four schedulers, stores the results and plots them.

### Step 1: Fixed simulation parameters
| Variable | Value | Meaning |
|---|---|---|
| `r` | 500 m | Cell radius (Capozzi et al. 2013) |
| `freq` | 2.6 GHz | Carrier frequency (LTE band 7) |
| `Pout` | 43 dBm | gNB transmit power (Capozzi et al. 2013) |
| `TTI` | 10 ms | Scheduling round (one LTE frame) |
| `fi` | 0.1 | Interference factor, `FN = 0.1 · Qty_UE` (dB) |
| `frames` | 5 | Frames simulated per run (50 ms) |
| `buffer` | 3 | Dynamic traffic with random packet sizes |
| `rdg` | 2 | Evenly spaced initial user distances |
| `plm` | `'38901_UMa_NLOS'` | Path-loss model (see §2.1) |

### Step 2: Sweep definitions and baseline
| Sweep | Values | Held fixed at |
|---|---|---|
| Number of users `Qty_UE_vec` | 50, 100, 150, 200, 250 | BW = 1.4 MHz, Pkg = 5 kbit |
| Bandwidth `BW_values` | 1.4, 3, 5 MHz | Qty_UE = 100, Pkg = 5 kbit |
| Packet size `Pkg_values` | 1, 2, 10 kbit | Qty_UE = 100, BW = 1.4 MHz |

The packet sizes are placeholders until the per-class (eMBB/URLLC/mMTC) requirements are taken from the literature.

The schedulers are stored as function handles:
```matlab
algoCalls = {@RR_function, @BCQI_function, @BET_FAST_function, @PF_FAST_function};
```
so the same loop can call each one in turn.

### Step 3: Result storage
For each sweep there is one `nAlg × nPoints` matrix per metric (`ATP_*`, `FT_*`, `Ef_*`, `delay_*`, `outt_*`, with suffix `_qty`, `_bw` or `_pkg`). Row = scheduler, column = sweep value.

### Step 4: Run the three sweeps
Three nested loops (sweep value × scheduler) call `algoCalls{a}(...)` and fill the matrices. In total that is (5 + 3 + 3) × 4 = **44 independent simulations**. Each is a **single random realisation**: there is no averaging over seeds and no fixed `rng`, so the numbers change slightly from run to run.

### Step 5: Figures
`Scheduling.m` opens **seven figures**:

1. **Throughput vs Fairness, Qty_UE sweep.** One curve per scheduler, each point labelled with its user count. This is the key trade-off plot: the top-right corner is ideal, BCQI sits bottom-right (high throughput, low fairness), RR/BET sit to the left, and PF is closest to the top-right.
2. **Throughput vs Fairness, BW sweep.** Same plot, points labelled with BW in MHz.
3. **Throughput vs Fairness, Pkg sweep.** Same plot, points labelled with packet size in kbit.
4. **Metrics vs Qty_UE** (2×2): throughput, fairness, spectral efficiency and delay against the number of users.
5. **Outage vs Qty_UE.**
6. **Metrics vs BW** (2×2, Qty_UE = 100): throughput, fairness, spectral efficiency and outage.
7. **Metrics vs packet size** (2×2, Qty_UE = 100, x-axis in kbit): throughput, fairness, delay and outage.

Each scheduler function also prints its run time (`tic/toc`) and `Frames simulados` to the command window. `Frames simulados` is only printed by RR, and it actually counts **completed users**, not frames.

---

## 6. Example results and how to read them

Mean of 10 seeded runs (`rng(1)` … `rng(10)` before each call) for the **user-count sweep** with the parameters of §5 (BW = 1.4 MHz, Pkg = 5 kbit, UMa NLOS). These are a check of the model, not thesis results.

| Qty_UE | | 50 | 100 | 150 | 200 | 250 |
|---|---|---|---|---|---|---|
| Throughput (Mbps) | RR | 6.49 | 6.22 | 5.83 | 5.34 | 4.84 |
| | BCQI | 6.53 | 6.53 | 6.53 | 6.53 | 6.53 |
| | BET | 6.49 | 6.20 | 5.67 | 5.07 | 4.47 |
| | PF | 6.52 | 6.48 | 6.36 | 6.17 | 6.00 |
| Fairness | RR | 0.91 | 0.97 | 0.95 | 0.89 | 0.86 |
| | BCQI | 0.45 | 0.30 | 0.22 | 0.17 | 0.15 |
| | BET | 0.87 | 0.96 | 0.97 | 0.96 | 0.89 |
| | PF | 0.98 | 0.99 | 0.99 | 0.99 | 0.97 |
| Outage (%) | RR | 3.4 | 0.5 | 7.0 | 31.6 | 47.7 |
| | BCQI | 49.4 | 65.4 | 73.1 | 78.0 | 81.3 |
| | BET | 4.8 | 20.7 | 40.9 | 55.7 | 64.1 |
| | PF | 0.2 | 2.4 | 16.0 | 33.3 | 45.2 |
| Delay (ms) | RR | 42.5 | Inf | Inf | Inf | Inf |
| | BCQI | 20.1 | 22.9 | 25.4 | 26.9 | 27.9 |
| | BET | 41.2 | 48.9 | Inf | Inf | Inf |
| | PF | 42.9 | Inf | Inf | Inf | Inf |

How to read them:
- **BCQI** has the highest throughput, and it stays flat because every RB is used at the top CQI (there is always some user close enough to the gNB). Its fairness and outage are the worst, and it has the shortest delay because it finishes the strongest users first.
- **PF** gives the best balance: within 1–8 % of BCQI's throughput, with the highest fairness (0.97–0.99). Its outage is the lowest at 50 users; at 100 users RR's is lower (0.5 % vs 2.4 %).
- **RR and BET** lose throughput as users are added, because they keep serving users with a poor channel. Their fairness also falls once there are more users than RBs per frame (140 at 1.4 MHz).
- **The 50-user point is a different regime.** A 5 kbit packet needs ≈ 11 RBs at CQI 15. With 50 users each one gets ≈ 14 RBs in 50 ms, so users finish and are replaced; with 100 or more users each gets ≤ 7 RBs and almost nobody finishes (hence `Inf` delay).
- **More users** → more interference (`FN ∝ Qty_UE`) → lower SNR, so throughput drops for every scheduler except BCQI.
- **More bandwidth** → more RBs per frame → throughput rises in proportion (≈ 14 Mbps at 3 MHz and 23 Mbps at 5 MHz for BCQI/PF).

The absolute values are now in the range of single-antenna LTE (3–5 bps/Hz), but see §7 before using them in the thesis.

---

## 7. Review: known issues and limitations

### 7.1 Model and scaling
1. **SNRs are still optimistic.** Even with UMa NLOS, about 83 % of RBs are at CQI 15 (median SNR ≈ 33 dB at 1.4 MHz, 100 UEs). Missing pieces: shadow fading (TR 38.901 gives σ = 4–6 dB for UMa), LOS probability, a receiver noise figure, and real inter-cell interference instead of `|N(0, Qty_UE·fi)|`.
2. **RBs per frame at 1.4 MHz** are 140, but LTE has 6 RBs × 20 slots = 120. The 3 MHz and 5 MHz values (300 and 500) are correct.
3. **Simulation length is 5 frames (50 ms) with a single realisation.** Results vary between runs because `Scheduling.m` has no `rng` seed and no Monte Carlo averaging.
4. **Packet sizes are placeholders.** Whether users finish within 50 ms depends on `Pkg`, `frames` and `Qty_UE`, and the current sweeps cross that boundary (see §6). `Pkg` and `frames` should come from the eMBB/URLLC/mMTC requirements.
5. **Time is recorded per frame.** Arrival and finish times are multiples of 10 ms, so the shortest possible delay is 10 ms. This is too coarse for URLLC and adds rounding noise to the per-user throughput in the fairness metric when packets are very small (e.g. 1 kbit finishes in ≈ 3 RBs).

### 7.2 Bugs that affect the plotted metrics
1. **BET and PF reset every user's history whenever someone finishes.** On each arrival, `Ri = ones(Qty_UE,1)*mean(Ri)` (and, for BET, `BET_metric = ones*mean(...)`) overwrite all users' averages with the mean. Every completion erases the fairness memory, and the next decisions become random tie-breaks. With small packets (many completions) this visibly lowers BET's fairness (e.g. 0.72 at 1 kbit vs 0.86 for RR).
2. **Average delay only includes users who finished.** Users still waiting are left out, and the result is `Inf` when nobody finished. A scheduler with a few late completions can therefore show a finite delay while another shows `Inf`. Delay should also count unfinished users, or be reported with the fraction of users that finished.
3. **The "Round Robin warm-up" in PF_FAST is dead code.** It checks `numTTI == 0`, but `numTTI` has already been incremented to 1 before the RB loop. (It also checks for `-999`, while PF marks finished users with `999`.)
4. **PF's average `R_i` has no forgetting window.** It is a 0.5-weighted average of the cumulative mean rate since arrival, so in practice it is the cumulative mean. Standard PF uses an exponential average over a window of many TTIs.

### 7.3 Minor / code quality
- `length(active_UE>1)` in BET/PF should be `length(active_UE) > 1`. It works by accident, because `randi(1)` returns 1.
- `UE_tp(active_UE) = UE_tp(Active_QtyUE) + ...` uses the wrong index. It is harmless because `UE_tp` is recomputed later and is not an output.
- The functions inside `RR_function.m`, `BCQI_function.m`, `BET_FAST_function.m` and `PF_FAST_function.m` are named `RR`, `BCQI`, `BET_FAST` and `PF`. MATLAB uses the file name, so they work, but the mismatch triggers a Code Analyzer warning.
- `Scheduling.m` starts with `clear all`, which also clears breakpoints and cached functions. `clear` or `clearvars` is enough.
- `TTI` actually holds the frame duration (10 ms). An LTE TTI is 1 ms.
- The SNR→CQI thresholds in `CQI.m` (−6.7 … 22.7 dB) are not standardised by 3GPP; they need a source in the thesis.

### 7.4 Fixed (October 2026)
- **Noise power** used `mag2db(BW)` = 20·log10(BW) instead of 10·log10(BW), putting the noise floor ~61 dB too high. Together with `r = 1 m` and `Pout = 10 dBm` this happened to give SNRs in the CQI range. Fixed to `10*log10(BW)`; `r` and `Pout` changed to 500 m and 43 dBm, and the selectable 3GPP path-loss models were added because free-space loss alone saturates every user at CQI 15.
- **Data per RB was scaled by `mag2db(BW)` in `CQI.m`** (≈ 123× at 1.4 MHz), giving ~800 Mbps and ~570 bps/Hz. Removed: bits per RE come straight from the CQI table.
- **CQI 15 threshold:** an SNR of exactly 22.7 dB returned CQI 0 (`>` instead of `>=`). The CQI 15 comment said 16QAM instead of 64QAM.
- **PF numerator** was `BW·log2(1+db2mag(SNR))`: Shannon capacity (with an amplitude instead of power conversion) that kept growing above CQI 15, so PF favoured users near the gNB for no throughput gain (fairness ≈ 0.92). It now uses the CQI rate, which matches the thesis definition and raised fairness to 0.97–1.00 with the same throughput.
- **BET and PF delay was always 0**: `UE_tend` started at `zeros`, so unfinished initial users counted as 0 s. Now `Inf`, as in RR/BCQI.
- **BET and PF overstated outage**: finished users were counted as receiving 0 bits. Now excluded, as in RR/BCQI (e.g. BET at 1 kbit: 47 % → 20 %).
- **Fairness** was Jain's index over total bits, which penalised users that arrived late in the run (it produced a dip at 50 users). Now computed over per-user throughput; identical results with `buffer = 0`.

---

## 8. How to run

1. Open MATLAB in the `matlab/` folder.
2. Run `Scheduling` (it needs a toolbox that provides `fspl` and `physconst`, such as the Phased Array System Toolbox).
3. Seven figures open. To make results reproducible, add `rng(<seed>)` at the top of `Scheduling.m`.
4. To change the path-loss model, set `plm` in `Scheduling.m` to one of the names in §2.1.
