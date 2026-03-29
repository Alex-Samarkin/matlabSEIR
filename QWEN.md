# COVID-19 SEIR Modeling Project (matlabSEIR)

## Project Overview

This is a **COVID-19 epidemiological modeling and data analysis project** focused on SEIR/SEIRD compartmental models. The project analyzes pandemic data across multiple countries, detects infection waves, correlates them with viral variant dominance periods, and compares classical vs. fractional-order differential equation models.

### Key Features

- **Data Pipeline**: Downloads and processes WHO COVID-19 daily case data
- **Wave Detection**: Algorithmically identifies infection waves using rolling averages and local minima detection
- **Variant Mapping**: Associates time periods with dominant SARS-CoV-2 strains (Wuhan, Alpha, Delta, Omicron sublineages)
- **SEIRD Modeling**: Implements both classical (RK4) and fractional Caputo derivative models
- **Statistical Validation**: Uses AIC/BIC, likelihood ratio tests, and profile likelihood for model comparison
- **Visualization**: Publication-quality plots with Nature/Science journal formatting standards

### Countries Analyzed

- USA (США), Russia (Россия), India (Индия), Brazil (Бразилия)
- United Kingdom (Великобритания), Germany (Германия), South Korea (Южная Корея)

---

## Directory Structure

```
matlabSEIR/
├── load_data.jl          # Data download & preprocessing (WHO source)
├── load_data2.jl         # Alternative data loader with cross-platform plotting
├── waves_detection.jl    # Wave detection algorithm & variant assignment
├── waves_and_stamms.jl   # Variant timeline & radar chart visualization
├── seir modelling.jl     # SEIRD model visualization for specific waves
├── seird_pipeline.jl     # Full SEIRD pipeline: classical + fractional Caputo model
├── r_load.r              # R script for Our World in Data fetch
│
├── covid_all_daily.csv           # Raw WHO daily data
├── covid_daily_smoothed.csv      # 7-day rolling average cases
├── cases_with_waves.csv          # Data with wave assignments per country
├── cases_with_variants.csv       # Data with variant parameters (R0, CFR, etc.)
├── covid_variants_seird.csv      # Variant biological parameters reference
│
└── *.png                   # Generated visualizations
```

---

## Building and Running

### Prerequisites

- **Julia** 1.8+ with the following packages:
  ```julia
  using Pkg
  Pkg.add(["CSV", "DataFrames", "Dates", "Downloads", 
           "Interpolations", "Plots", "StatsPlots", 
           "Optim", "Distributions", "SpecialFunctions", 
           "Statistics", "StatsBase", "Printf", "LinearAlgebra"])
  ```
- **R** (optional) — for `r_load.r` script

### Execution Order

1. **Load and preprocess data**:
   ```bash
   julia load_data.jl
   ```
   Downloads WHO data to `covid_all_daily.csv` and generates country-specific plots.

2. **Detect waves and assign variants**:
   ```bash
   julia waves_detection.jl
   ```
   Creates `cases_with_waves.csv` with wave boundaries for each country.

3. **Generate variant timeline visualizations**:
   ```bash
   julia waves_and_stamms.jl
   ```
   Creates `cases_with_variants.csv` with biological parameters per date.

4. **Run SEIRD modeling** (classical + fractional):
   ```bash
   julia seird_pipeline.jl
   ```
   Calibrates models, performs statistical validation, generates 6-panel result figure.

### Running Individual Wave Analysis

Edit `seir modelling.jl` to select country and wave number:
```julia
df = select_wave(cases, country_dict, country_idx::Int, wave_num::Int)
p = plot_wave_detail(df, :Россия, 2)  # Russia, wave 2
```

---

## Data Sources

| Source | File | Description |
|--------|------|-------------|
| WHO | `covid_all_daily.csv` | Daily new cases, cumulative cases, deaths |
| Our World in Data | (via `r_load.r`) | 7-day rolling average data |
| Literature | `covid_variants_seird.csv` | Variant parameters: R0, incubation, infectious period, CFR |

### Variant Parameters Table

| Strain | R0 Range | Incubation (days) | Infectious (days) | CFR |
|--------|----------|-------------------|-------------------|-----|
| Wuhan | 2.5–3.5 | 5.2 | 10.6 | 2.0% |
| Alpha | 4.0–6.0 | 4.8 | 8.4 | 2.0% |
| Delta | 5.0–8.0 | 4.5 | 6.75 | 1.5% |
| Omicron BA.1 | 8.0–10.0 | 3.2 | 5.2 | 0.3% |
| Omicron BA.2 | 9.0–12.0 | 3.0 | 5.0 | 0.25% |
| Omicron BA.5 | 10.0–15.0 | 2.8 | 4.4 | 0.2% |
| Omicron XBB | 12.0–18.0 | 2.5 | 3.5 | 0.1% |
| Omicron JN.1 | 15.0–20.0 | 2.3 | 3.15 | 0.1% |

---

## SEIRD Model Details

### Classical SEIRD (RK4)

System of ODEs:
```
dS/dt = -β·S·I/N
dE/dt = β·S·I/N - σ·E
dI/dt = σ·E - γ·I - μ·I
dR/dt = γ·I
dD/dt = μ·I
```

Where:
- β = transmission rate (calibrated)
- σ = 1/incubation_period
- γ = (1-CFR)/infectious_period
- μ = CFR/infectious_period

### Fractional SEIRD (Caputo Derivative)

Uses Caputo fractional derivative of order α ∈ (0, 1]:
```
D^α_C S = -β·S·I/N
D^α_C E = β·S·I/N - σ·E
...
```

Solved using Adams-Bashforth-Moulton predictor-corrector method. The α parameter captures "memory effects" in epidemic dynamics (social behavior inertia, delayed policy effects).

### Calibration Strategy

1. Fix σ, γ, μ from literature (variant CSV)
2. Optimize β to minimize SSE against daily case data
3. For fractional model: jointly optimize [α, β]
4. Validate using:
   - **AIC/BIC**: Model selection with complexity penalty
   - **Likelihood Ratio Test**: Statistical significance of α
   - **Profile Likelihood**: 95% confidence interval for α
   - **Residual Analysis**: Autocorrelation, Durbin-Watson test

---

## Visualization Standards

Plots follow Nature/Science journal guidelines:

- **Size**: Single-column 89mm @ 600dpi = 2102px width
- **Font**: Arial/Helvetica, title 28pt, axis 24pt, ticks 20pt
- **Colors**: Wong 2011 colorblind-safe palette
- **Frame**: Box style with inward ticks
- **Line width**: 2.5pt, marker stroke 1.5pt

---

## Key Output Files

| File | Description |
|------|-------------|
| `cases_with_waves.csv` | Daily cases with wave number assignments |
| `cases_with_variants.csv` | Cases with variant parameters per date |
| `seird_caputo_results.png` | 6-panel model comparison figure |
| `waves_*.png` | Wave detection plots per country |
| `wave_detail_*.png` | Detailed single-wave analysis with variant zones |
| `radar_*.png` | Radar charts comparing variant characteristics |

---

## Development Conventions

- **Language**: Julia (primary), R (auxiliary)
- **Data Format**: CSV for intermediate results, Parquet/XLSX for archives
- **Plotting**: Plots.jl with GR backend
- **Optimization**: Optim.jl with L-BFGS and box constraints
- **Naming**: Russian labels in plots, English in code
- **Wave Detection**: 21-day rolling mean, prominence threshold 0.18, min distance 31 days

---

## Troubleshooting

### Common Issues

1. **"GR backend not displaying plots"**: Run `gui()` after plot creation or use `display(p)`
2. **"Optimization fails to converge"**: Increase `n_restarts` in Config struct
3. **"Date parsing errors"**: Ensure CSV dates are in ISO format (YYYY-MM-DD)
4. **"Memory error in fractional solver"**: Reduce `n_days` or increase step size `dt`

### α Interpretation Guide

| α Range | Interpretation |
|---------|----------------|
| > 0.95 | Near-Markovian; classical SEIRD sufficient |
| 0.80–0.95 | Moderate memory; fractional model preferred |
| 0.65–0.80 | Strong memory; heterogeneous population response |
| < 0.65 | Extreme memory; consider spatial models |
