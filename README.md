# Replication Package for Algorithmic Collusion under Stochastic Costs: User's Guide

This repository contains the replication code for: Ballestero, G. (2026). Algorithmic collusion under sequential pricing and stochastic costs. _International Journal of Industrial Organization_, 106, 103281.  


This README was prepared following the guidelines of the International Journal of Industrial Organization Data Editor. Last updated: 2 March 2026

For questions about this replication package, please contact Gonzalo Ballestero (Pennsylvania State University) at gballestero@psu.edu.

---

## 1. Introduction

The structure of the folder is as follows:

- `\code` — contains the codes to generate the simulation experiments
- `\figures_and_tables` — contains the codes to generate figures and tables of the paper
- `\figures_and_tables_appendix` — contains the codes to generate figures and tables of the online appendix

> **Note on simulation data:** The folder `\data_simulation`, which contains the `.jld2` output files from the simulation experiments, is not included in this repository due to file size constraints (outputs can reach several GB). Simulation data will be shared upon request. Alternatively, all results can be reproduced by running the simulation codes described in Section 2.

---

## 2. Simulation Experiments

This section describes how to run the codes in `\code` and generate the results for the simulation experiments. All computations were completed using Julia 1.10, available at https://julialang.org/downloads/. The Julia script `main.jl` contains the calling program, and all other scripts contain modules implementing specific computations. Simulation results are stored in `.jld2` output files in `\data_simulation`, which are frequently quite large and may take up to several GB of disk space (not included in this repository — see note above). These output files are then fed to Julia scripts in `\figures_and_tables` and `\figures_and_tables_appendix` to generate figures and tables of the paper and the online appendix.

The folder `\code\master` contains the following scripts:

- **`main.jl`** — master script that calls other modules and defines the input parameters.
- **`init_deterministic.jl`** — defines the deterministic environment (i.e., no cost uncertainty).
- **`init_stochastic.jl`** — defines the stochastic cost environment.
- **`qlearning_deterministic.jl`** — implements the Q-learning simulations for the deterministic cost model. Contains subroutines for action selection, the learning process, and convergence checks. Output file: `outcomes_deterministic_XX.bin`, where `XX` is the experiment code.
- **`qlearning_stochastic.jl`** — implements the Q-learning simulations for the stochastic cost model. Contains subroutines for action selection, the learning process, and convergence checks. Output file: `outcomes_stochastic_XX.bin`, where `XX` is the experiment code.
- **`qlearning_stochastic_own_price.jl`** — implements the Q-learning simulations used in Section 5.2 of the paper.

---

## 3. Input Parameters

Model parameters are defined within the `main.jl` script. The key parameters are:

| Parameter | Description |
|-----------|-------------|
| `k` | Number of available prices |
| `cH` | High marginal costs |
| `δ` | Discount factor |
| `ρ` | Persistence parameter of the Markov cost process |

The baseline experiment is defined as:

```julia
k = 12, cH = 1/6, delta = 0.95, rho = [0.5, 0.9]
```

Users can modify these values to replicate alternative parameterizations discussed in the paper.

---

## 4. Figures and Tables

This section describes the scripts used to generate the figures and tables reported in the paper and in the online appendix. There are two folders:

- **`\figures_and_tables`** — Julia scripts for the main figures and tables of the paper.
- **`\figures_and_tables_appendix`** — scripts for the figures and tables of the online appendix.

Each file is named after the figure or table it reproduces. For example, `figure_1.jl` generates Figure 1 of the paper, and `table_D1.jl` generates Table D.1 of the appendix. Running a given script will automatically load the required simulation outputs from `data_simulation` and produce the corresponding figure or table in PDF or txt format.

In addition to the figure- and table-specific scripts, the folders include five supporting modules:

- **`pricing_classification.jl`** — classifies each simulation session according to its focal price behavior, following the classification scheme in Table 1 of the paper.
- **`compute_profit_normalized.jl`** — computes normalized profits as defined in Equation (4) of the paper.
- **`compute_nash_optimality.jl`** — calculates best responses from the learned Q-matrix and computes the frequency of Nash equilibria and Q-loss due to suboptimal response.
- **`price_deviation_analysis.jl`** — computes unilateral deviations from the limit path. Operates in two modes: `"price_deviation"` (temporary price cuts) and `"price_hike"` (temporary price increases).
- **`cost_shock_analysis.jl`** — computes the dynamic response of prices to an exogenous cost shock.
