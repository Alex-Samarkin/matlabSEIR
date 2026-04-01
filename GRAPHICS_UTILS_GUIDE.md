# Graphics Utilities Guide

**Project:** matlabSEIR — COVID-19 Epidemiological Modeling  
**Location:** `C:\Users\AlexSam\Documents\html2026\matlabSEIR`

This guide covers two complementary plotting utility libraries for creating publication-quality scientific visualizations in Julia.

---

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [plot_utils.jl (Plots.jl)](#plot_utilsjl-plotsjl)
4. [makie_utils.jl (Makie.jl)](#makie_utilsjl-makiejl)
5. [Comparison](#comparison)
6. [Examples](#examples)
7. [Troubleshooting](#troubleshooting)

---

## Overview

| Feature | plot_utils.jl | makie_utils.jl |
|---------|---------------|----------------|
| **Backend** | Plots.jl (GR, PlotlyJS) | Makie.jl (CairoMakie, GLMakie) |
| **Best For** | Quick prototyping, interactive plots | Publication-quality, vector graphics |
| **Output Formats** | PNG, SVG, PDF, HTML (interactive) | PNG, SVG, PDF, MP4 (animations) |
| **Learning Curve** | Low | Medium |
| **Performance** | Good for small-medium datasets | Excellent for large datasets |
| **Theme Support** | Nature/Science journal standards | Custom themes with fine control |

---

## Installation

### Prerequisites

```julia
using Pkg

# For plot_utils.jl
Pkg.add(["Plots", "Statistics", "Dates", "Printf", "DataFrames"])

# For makie_utils.jl
Pkg.add(["CairoMakie", "GLMakie", "Statistics", "Dates", "Printf", "Colors"])
```

### Quick Start

```julia
# Include the utility file
include("plot_utils.jl")    # For Plots.jl utilities
include("makie_utils.jl")   # For Makie.jl utilities
```

---

## plot_utils.jl (Plots.jl)

### Quick Start

```julia
include("plot_utils.jl")

# Apply publication theme
use_nature_theme()

# Create a simple plot
x = range(0, 10, length=100)
y = sin.(x)
p = quick_plot(x, y, title="Sine Wave", label="sin(x)")

# Save the plot
save_plot(p, filename="my_plot.png")
```

### Available Functions

#### Themes

| Function | Description |
|----------|-------------|
| `use_nature_theme()` | Apply Nature/Science journal theme (600 DPI) |
| `use_light_theme()` | Apply light theme for quick debugging (150 DPI) |

#### Basic Plots

| Function | Description | Example |
|----------|-------------|---------|
| `quick_plot(x, y)` | Line plot | `quick_plot(x, y, label="Series")` |
| `quick_scatter(x, y)` | Scatter plot | `quick_scatter(x, y, label="Data")` |
| `quick_bar(values)` | Bar chart | `quick_bar(values, labels=categories)` |
| `quick_histogram(data)` | Histogram | `quick_histogram(data, bins=30)` |
| `quick_boxplot(data)` | Box plot | `quick_boxplot(data, labels=groups)` |

#### Statistical Plots

| Function | Description |
|----------|-------------|
| `plot_with_confidence(x, y_mean, y_lower, y_upper)` | Line plot with confidence interval |
| `plot_residuals(y_true, y_pred)` | Residuals analysis (3 panels) |
| `qqplot(data)` | QQ-plot for normality testing |
| `plot_correlation_matrix(df)` | Heatmap of correlation matrix |

#### Time Series

| Function | Description |
|----------|-------------|
| `plot_timeseries(dates, values)` | Single time series |
| `plot_multi_timeseries(dates, dict)` | Multiple time series |
| `plot_comparison(x, y1, y2)` | Compare two series (2 panels) |

#### Panels & Dashboards

| Function | Description |
|----------|-------------|
| `quick_panel([p1, p2, ...])` | Create panel from existing plots |
| `create_dashboard()` | Create empty dashboard |
| `add_plot!(dash, plot)` | Add plot to dashboard |

#### Saving

| Function | Description |
|----------|-------------|
| `save_plot(p, filename="...")` | Save plot to file |
| `save_plot(p, format=:svg)` | Save as vector SVG |
| `save_panel(plots, filename)` | Save panel of plots |

### Example: Complete Workflow

```julia
include("plot_utils.jl")
using Statistics, Dates

# Apply theme
use_nature_theme()

# Generate data
dates = Date(2020,1,1):Day(1):Date(2020,12,31)
cases = cumsum(randn(length(dates)) .+ 100) .* 10

# Create plot
p = plot_timeseries(dates, cases,
                    title="COVID-19 Cases",
                    ylabel="Cumulative Cases")

# Save
save_plot(p, filename="covid_timeseries.png")
```

---

## makie_utils.jl (Makie.jl)

### Quick Start

```julia
include("makie_utils.jl")

# Apply publication theme
use_makie_theme(:publication)

# Create a simple plot
x = range(0, 10, length=100)
y = sin.(x)
fig, ax = quick_plot(x, y, label="sin(x)")

# Add legend
Legend(fig, ax, :rt)

# Save the plot
save_plot(fig, filename="my_plot.png", dpi=600)
```

### Available Functions

#### Themes

| Function | Description |
|----------|-------------|
| `use_makie_theme(:default)` | Default theme (600×450 @ 300 DPI) |
| `use_makie_theme(:publication)` | Publication theme (900×600 @ 600 DPI) |
| `use_makie_theme(:light)` | Light theme for debugging (400×300 @ 150 DPI) |

#### Backends

| Function | Description |
|----------|-------------|
| `use_makie_backend(:cairo)` | Static images (PNG, SVG, PDF) |
| `use_makie_backend(:gl)` | Interactive 3D and animations |

#### Basic Plots

| Function | Returns | Example |
|----------|---------|---------|
| `quick_plot(x, y)` | `(fig, ax)` | `quick_plot(x, y, color=:blue)` |
| `quick_scatter(x, y)` | `(fig, ax)` | `quick_scatter(x, y, markersize=6)` |
| `quick_bar(values)` | `(fig, ax)` | `quick_bar(values, color=:teal)` |
| `quick_histogram(data)` | `(fig, ax)` | `quick_histogram(data, bins=30)` |
| `quick_boxplot(data)` | `(fig, ax)` | `quick_boxplot(data, labels=groups)` |

#### Statistical Plots

| Function | Description |
|----------|-------------|
| `plot_with_band(x, y_mean, y_lower, y_upper)` | Line plot with shaded confidence band |
| `plot_residuals_makie(y_true, y_pred)` | Residuals analysis (3 panels) |
| `qqplot_makie(data)` | QQ-plot for normality testing |
| `plot_correlation_matrix_makie(df)` | Heatmap of correlation matrix |

#### Time Series

| Function | Description |
|----------|-------------|
| `plot_timeseries_makie(dates, values)` | Single time series |
| `plot_multi_timeseries_makie(dates, dict)` | Multiple time series |
| `plot_comparison_makie(x, y1, y2)` | Compare two series (2 panels) |

#### Specialized Plots

| Function | Description |
|----------|-------------|
| `plot_error_bars_makie(x, y, yerr)` | Error bars |
| `plot_contour(x, y, z)` | Contour plot |
| `plot_surface(x, y, z)` | 3D surface (requires GLMakie) |

#### Panels & Dashboards

| Function | Description |
|----------|-------------|
| `create_figure(rows, cols, size)` | Create figure with grid of axes |
| `quick_panel_makie(data)` | Create panel from plot functions |
| `add_colorbar!(fig, plot)` | Add colorbar to figure |
| `add_legend!(ax)` | Add legend to axis |

#### Saving

| Function | Description |
|----------|-------------|
| `save_plot(fig, filename="...")` | Save figure to file |
| `save_plot(fig, format=:svg)` | Save as vector SVG |
| `save_plot(fig, format=:pdf)` | Save as vector PDF |
| `save_plot_series(figs, filenames)` | Save multiple figures |

#### Animations

```julia
function animate(frame)
    # Update plot based on frame number
    return fig
end

create_animation(animate, frames=60, filename="animation.mp4", fps=15)
```

### Example: Complete Workflow

```julia
include("makie_utils.jl")
using Statistics, Dates

# Apply theme
use_makie_theme(:publication)

# Generate data
dates = Date(2020,1,1):Day(1):Date(2020,12,31)
cases = cumsum(randn(length(dates)) .+ 100) .* 10

# Create figure
fig = Figure(size=(900, 600))
ax = Axis(fig[1, 1],
          title="COVID-19 Cases",
          xlabel="Date",
          ylabel="Cumulative Cases",
          xticklabelrotation=π/4)

# Plot data
lines!(ax, dates, cases, color=:blue, linewidth=2)

# Save
save_plot(fig, filename="covid_timeseries.png", dpi=600)
```

---

## Comparison

### When to Use plot_utils.jl

✅ **Choose Plots.jl when:**
- You need quick, simple plots
- You want interactive HTML output (PlotlyJS)
- You're prototyping and need fast iteration
- You prefer simpler syntax
- You need 3D surface plots without extra setup

### When to Use makie_utils.jl

✅ **Choose Makie.jl when:**
- You need publication-quality vector graphics
- You're working with large datasets
- You need fine control over every visual element
- You want to create animations
- You need modern, GPU-accelerated rendering

### Feature Comparison Table

| Feature | plot_utils.jl | makie_utils.jl |
|---------|---------------|----------------|
| **Vector Output (SVG/PDF)** | ✅ | ✅ |
| **Interactive HTML** | ✅ (PlotlyJS) | ❌ |
| **Animations** | Limited | ✅ (MP4, GIF) |
| **3D Plots** | ✅ | ✅ (GLMakie) |
| **Large Dataset Performance** | Good | Excellent |
| **Theme Customization** | Basic | Advanced |
| **Learning Curve** | Low | Medium |
| **Memory Usage** | Low | Higher |

---

## Examples

### Example 1: Multi-Panel Figure (Plots.jl)

```julia
include("plot_utils.jl")

# Create individual plots
p1 = plot(1:10, rand(10), title="Panel 1")
p2 = plot(1:10, rand(10), title="Panel 2")
p3 = plot(1:10, rand(10), title="Panel 3")
p4 = plot(1:10, rand(10), title="Panel 4")

# Combine into panel
panel = quick_panel([p1, p2, p3, p4], 
                    layout=(2, 2), 
                    size=(1600, 1200))

save_plot(panel, filename="multi_panel.png")
```

### Example 2: Multi-Panel Figure (Makie.jl)

```julia
include("makie_utils.jl")

# Create figure with 2x2 grid
fig = Figure(size=(1200, 1000))
axes = [Axis(fig[i, j]) for i in 1:2, j in 1:2]

# Fill axes
for (i, ax) in enumerate(axes)
    lines!(ax, 1:10, rand(10), color=i)
    ax.title = "Panel $i"
end

save_plot(fig, filename="multi_panel.png", dpi=300)
```

### Example 3: Statistical Analysis Plot

```julia
# Using Plots.jl
include("plot_utils.jl")

y_true = rand(100) .* 10
y_pred = y_true .+ randn(100) .* 2

# Residuals analysis
plot_residuals(y_true, y_pred)
```

```julia
# Using Makie.jl
include("makie_utils.jl")

y_true = rand(100) .* 10
y_pred = y_true .+ randn(100) .* 2

# Residuals analysis
plot_residuals_makie(y_true, y_pred)
```

### Example 4: Correlation Heatmap

```julia
# Using Plots.jl
include("plot_utils.jl")
using DataFrames

df = DataFrame(A=randn(100), B=randn(100), C=randn(100), D=randn(100))
plot_correlation_matrix(df)
```

```julia
# Using Makie.jl
include("makie_utils.jl")
using DataFrames

df = DataFrame(A=randn(100), B=randn(100), C=randn(100), D=randn(100))
fig, ax = plot_correlation_matrix_makie(df)
save_plot(fig, filename="correlation.png")
```

---

## Troubleshooting

### Common Issues

#### 1. "Font not found" warnings

**Solution:** Install Arial or change font in theme:
```julia
# In plot_utils.jl theme
fontfamily = "TeX Gyre Heros"  # Alternative to Arial
```

#### 2. Makie Legend errors

The Makie API for legends has changed. Use:
```julia
Legend(fig, ax, :rt)  # Correct
# Not: Legend(ax, :rt)
```

#### 3. Box plot not working in Makie

Box plots have issues in newer Makie versions. Use scatter alternative:
```julia
for (i, data) in enumerate(groups)
    x_jitter = fill(i, length(data)) .+ (rand(length(data)) .- 0.5) .* 0.3
    scatter!(ax, x_jitter, data)
end
```

#### 4. Plots not displaying

**For Plots.jl:**
```julia
display(p)  # Explicitly display
gui()       # Open GUI window
```

**For Makie.jl:**
```julia
display(fig)  # Explicitly display
```

#### 5. Low resolution output

**Plots.jl:**
```julia
use_nature_theme()  # 600 DPI
save_plot(p, filename="plot.png")
```

**Makie.jl:**
```julia
use_makie_theme(:publication)  # 600 DPI
save_plot(fig, filename="plot.png", dpi=600)
```

### Performance Tips

1. **For large datasets (>100k points):** Use Makie.jl with CairoMakie
2. **For interactive exploration:** Use Plots.jl with PlotlyJS backend
3. **For publications:** Use Makie.jl with SVG/PDF output
4. **For quick debugging:** Use light themes (150 DPI)

---

## Demo Files

Both utilities include comprehensive demo files:

```bash
# Run Plots.jl demo
julia demo_plots_utils.jl

# Run Makie.jl demo
julia demo_makie_utils.jl
```

These demos generate 20+ example plots demonstrating all available features.

---

## References

- **Plots.jl Documentation:** https://docs.juliaplots.org/
- **Makie.jl Documentation:** https://docs.makie.org/
- **Colorblind-safe palettes:** Wong, B. (2011). Nature Methods 8:441
- **Nature Publishing Guidelines:** https://www.nature.com/nature/for-authors/illustrations

---

*Last updated: 2026-04-01*
