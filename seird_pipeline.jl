#!/usr/bin/env julia
# -*- coding: utf-8 -*-
#=
╔══════════════════════════════════════════════════════════════════════╗
║  SEIRD-ПАЙПЛАЙН (Julia)                                              ║
║  Классическая + дробная (Капуто) модель                              ║
║  Калибровка · Статистическое обоснование α · Визуализация            ║
╚══════════════════════════════════════════════════════════════════════╝

Структура:
  1. Загрузка CSV → фильтрация волны → извлечение биопараметров штамма
  2. Классическая SEIRD (RK4)
  3. Дробная SEIRD с производной Капуто (предиктор-корректор ABM)
  4. Калибровка: сначала β по данным (остальное из CSV), затем полная
  5. Статистическое обоснование α:
     • AIC / BIC / скорректированный AIC
     • Тест отношения правдоподобия (LRT)
     • Профиль правдоподобия → доверительный интервал α
     • Анализ остатков: автокорреляция, QQ-plot
  6. Визуализация (4 панели)

Зависимости:
  using Pkg
  Pkg.add(["CSV", "DataFrames", "Dates", "Optim",
           "Plots", "StatsPlots", "Distributions",
           "SpecialFunctions", "Statistics", "StatsBase"])
=#

using CSV, DataFrames, Dates
using Optim
using Plots, StatsPlots
using Distributions
using SpecialFunctions: gamma as Γ
using Statistics, StatsBase
using Printf
using LinearAlgebra

# ════════════════════════════════════════════════════════════════════
# 0. КОНФИГУРАЦИЯ
# ════════════════════════════════════════════════════════════════════

"""Параметры запуска — настройте под свои данные."""
Base.@kwdef struct Config
    csv_path::String       = "russia_covid_waves.csv"  # путь к CSV
    country_col::String    = "Россия"                  # колонка с заболевшими
    wave_col::String       = "Россия_волна"            # колонка номера волны
    wave_number::Int       = 2                         # какую волну моделируем
    N_population::Float64  = 146_000_000.0             # население (Россия)
    I0::Float64            = 100.0                     # начальное число I
    E0_factor::Float64     = 3.0                       # E₀ = E0_factor × I₀
    maxiter_de::Int        = 500                       # итерации глоб. оптимизации
    n_restarts::Int        = 20                        # число рестартов
    α_profile_range::StepRangeLen = 0.50:0.02:1.00     # сетка для профиля α
end

# ════════════════════════════════════════════════════════════════════
# 1. ЗАГРУЗКА ДАННЫХ
# ════════════════════════════════════════════════════════════════════

"""
Загрузить CSV и извлечь данные одной волны.

Возвращает:
  - days::Vector{Float64}  — дни от начала волны (0, 1, 2, ...)
  - cases::Vector{Float64} — ежедневные заболевшие
  - bio::NamedTuple        — биологические параметры штамма из CSV
"""
function load_wave(cfg::Config)
    df = CSV.read(cfg.csv_path, DataFrame)

    # Фильтрация по волне
    wave_df = filter(row -> row[cfg.wave_col] == cfg.wave_number, df)
    sort!(wave_df, :date)

    cases = Float64.(wave_df[!, cfg.country_col])
    dates = wave_df.date
    days  = Float64.(0:length(cases)-1)

    # Биопараметры штамма (берём медиану по волне)
    R0_lit       = median(wave_df.R0)
    incubation   = median(wave_df.incubation)   # дни
    infectious   = median(wave_df.infectious)    # дни
    cfr          = median(wave_df.CFR)
    strain_name  = first(wave_df.strain)
    R0_min       = median(wave_df.R0_min)
    R0_max       = median(wave_df.R0_max)

    # Пересчёт в параметры SEIRD
    σ = 1.0 / incubation         # скорость перехода E → I
    γ = (1.0 - cfr) / infectious # скорость выздоровления I → R
    μ = cfr / infectious          # скорость смертности I → D
    β_lit = R0_lit * (γ + μ)      # из R₀ = β / (γ + μ)

    bio = (
        strain     = strain_name,
        R0_lit     = R0_lit,
        R0_min     = R0_min,
        R0_max     = R0_max,
        incubation = incubation,
        infectious = infectious,
        cfr        = cfr,
        σ          = σ,
        γ          = γ,
        μ          = μ,
        β_lit      = β_lit,
    )

    println("\n┌─────────────────────────────────────────────────┐")
    println("│  Волна $(cfg.wave_number): $(strain_name)")
    println("│  Период: $(first(dates)) — $(last(dates)) ($(length(cases)) дней)")
    println("│  Пик: $(round(maximum(cases), digits=0)) чел/день")
    println("│  Штамм R₀(лит.) = $R0_lit [$R0_min, $R0_max]")
    println("│  σ=$(round(σ,digits=4)), γ=$(round(γ,digits=4)), μ=$(round(μ,digits=5))")
    println("│  β(лит.) = $(round(β_lit,digits=4))")
    println("└─────────────────────────────────────────────────┘")

    return days, cases, bio, dates
end


# ════════════════════════════════════════════════════════════════════
# 2. КЛАССИЧЕСКАЯ SEIRD (RK4)
# ════════════════════════════════════════════════════════════════════

"""
Правая часть системы SEIRD.
y = [S, E, I, R, D], параметры: β, σ, γ, μ, N.
"""
function seird_rhs!(dy, y, β, σ, γ, μ, N)
    S, E, I, R, D = y
    force = β * S * I / N
    dy[1] = -force
    dy[2] =  force - σ * E
    dy[3] =  σ * E - γ * I - μ * I
    dy[4] =  γ * I
    dy[5] =  μ * I
    return dy
end

"""
Решение классической SEIRD методом RK4.

Возвращает матрицу (n_days+1) × 5: [S E I R D] по дням.
"""
function solve_classical(β, σ, γ, μ, N, I0, E0, n_days; dt=0.25)
    steps = round(Int, n_days / dt)
    y = [N - I0 - E0, E0, I0, 0.0, 0.0]
    dy = similar(y)

    result = zeros(n_days + 1, 5)
    result[1, :] .= y

    day_saved = 0
    for n in 1:steps
        k1 = copy(seird_rhs!(dy, y, β, σ, γ, μ, N))
        k2 = copy(seird_rhs!(dy, y .+ dt/2 .* k1, β, σ, γ, μ, N))
        k3 = copy(seird_rhs!(dy, y .+ dt/2 .* k2, β, σ, γ, μ, N))
        k4 = copy(seird_rhs!(dy, y .+ dt .* k3, β, σ, γ, μ, N))
        y .= max.(y .+ (dt / 6) .* (k1 .+ 2k2 .+ 2k3 .+ k4), 0.0)

        current_day = round(Int, n * dt)
        if current_day > day_saved && current_day ≤ n_days
            day_saved = current_day
            result[current_day + 1, :] .= y
        end
    end
    return result
end


# ════════════════════════════════════════════════════════════════════
# 3. ДРОБНАЯ SEIRD — ПРОИЗВОДНАЯ КАПУТО (ABM)
# ════════════════════════════════════════════════════════════════════

"""
Решение дробной SEIRD с производной Капуто порядка α ∈ (0, 1].

Метод: предиктор-корректор Адамса–Башфорта–Мултона (ABM).

Система:
    D^α_C S = -β·S·I/N
    D^α_C E =  β·S·I/N − σ·E
    D^α_C I =  σ·E − γ·I − μ·I
    D^α_C R =  γ·I
    D^α_C D =  μ·I

При α = 1 вырождается в классическую SEIRD.
Вычислительная сложность: O(n²) по числу шагов (из-за ядра памяти).

Возвращает матрицу (n_days+1) × 5: [S E I R D].
"""
function solve_fractional(α, β, σ, γ, μ, N, I0, E0, n_days)
    h  = 1.0  # шаг = 1 день
    ns = n_days
    ne = 5

    y0 = [N - I0 - E0, E0, I0, 0.0, 0.0]
    Y  = zeros(ns + 1, ne)
    Y[1, :] .= y0

    Γα1 = Γ(α + 1)
    Γα2 = Γ(α + 2)

    function f(state)
        S, E, I, R, D = state
        force = β * S * I / N
        return [-force,
                 force - σ * E,
                 σ * E - γ * I - μ * I,
                 γ * I,
                 μ * I]
    end

    # История значений правой части
    fhist = zeros(ns + 1, ne)
    fhist[1, :] .= f(y0)

    for n in 1:ns
        # --- Предиктор ---
        pred = copy(y0)
        for j in 0:(n-1)
            a_j = ((n - j)^α - (n - 1 - j)^α) / Γα1
            pred .+= h^α * a_j .* fhist[j + 1, :]
        end
        pred .= max.(pred, 0.0)

        # --- Корректор ---
        fp = f(pred)
        corr = copy(y0)
        for j in 0:(n-1)
            if j == 0
                b_j = ((n-1)^(α+1) - (n - 1 - α) * n^α) / Γα2
            else
                b_j = ((n - j + 1)^(α+1) + (n - j - 1)^(α+1) - 2(n - j)^(α+1)) / Γα2
            end
            corr .+= h^α * b_j .* fhist[j + 1, :]
        end
        corr .+= h^α * (1.0 / Γα2) .* fp
        corr .= max.(corr, 0.0)

        Y[n + 1, :] .= corr
        fhist[n + 1, :] .= f(corr)
    end

    return Y
end


# ════════════════════════════════════════════════════════════════════
# 4. ЦЕЛЕВЫЕ ФУНКЦИИ И КАЛИБРОВКА
# ════════════════════════════════════════════════════════════════════

"""
Модельные «новые случаи» ≈ σ · E(t).
"""
model_new_cases(sol, σ) = σ .* sol[:, 2]

"""
Сумма квадратов ошибок (SSE) с защитой от ошибок.
"""
function sse(model_cases, data_cases)
    n = min(length(model_cases), length(data_cases))
    return sum((data_cases[1:n] .- model_cases[1:n]).^2)
end

"""
Отрицательное лог-правдоподобие (нормальная модель ошибок).
NLL = (n/2)·log(2π) + (n/2)·log(σ²) + SSE/(2σ²)
где σ² = SSE/n (MLE-оценка дисперсии).
"""
function neg_loglik(model_cases, data_cases)
    n = min(length(model_cases), length(data_cases))
    residuals = data_cases[1:n] .- model_cases[1:n]
    ss = sum(residuals.^2)
    σ² = ss / n
    σ² < 1e-20 && return Inf
    return n/2 * log(2π) + n/2 * log(σ²) + n/2
end

"""
Калибровка классической SEIRD.

Стратегия:
  • σ, γ, μ фиксированы из литературы (CSV)
  • Оптимизируется β (эффективная скорость заражения)
  • Опционально: оптимизация [β, σ, γ, μ] целиком (full=true)

Возвращает NamedTuple с оптимальными параметрами.
"""
function calibrate_classical(data_cases, bio, cfg::Config; full=false)
    N  = cfg.N_population
    I0 = cfg.I0
    E0 = cfg.E0_factor * I0
    n_days = length(data_cases) - 1

    if !full
        # --- Только β ---
        function obj_β(x)
            β = x[1]
            β ≤ 0 && return Inf
            try
                sol = solve_classical(β, bio.σ, bio.γ, bio.μ, N, I0, E0, n_days)
                mc = model_new_cases(sol, bio.σ)
                return sse(mc, data_cases)
            catch
                return Inf
            end
        end

        best_sse = Inf
        best_β   = bio.β_lit
        for _ in 1:cfg.n_restarts
            β_init = bio.β_lit * (0.2 + 1.6 * rand())
            try
                res = optimize(obj_β, [0.01], [3.0], [β_init], Fminbox(LBFGS()),
                               Optim.Options(iterations=200, show_trace=false))
                if Optim.minimum(res) < best_sse
                    best_sse = Optim.minimum(res)
                    best_β   = Optim.minimizer(res)[1]
                end
            catch; end
        end

        return (β=best_β, σ=bio.σ, γ=bio.γ, μ=bio.μ,
                sse=best_sse, R0=best_β/(bio.γ+bio.μ),
                n_params=1)
    else
        # --- Полная калибровка [β, σ, γ, μ] ---
        function obj_full(x)
            β, σ, γ, μ = x
            any(x .≤ 0) && return Inf
            try
                sol = solve_classical(β, σ, γ, μ, N, I0, E0, n_days)
                mc = model_new_cases(sol, σ)
                return sse(mc, data_cases)
            catch
                return Inf
            end
        end

        lower = [0.01, 0.02, 0.005, 0.0001]
        upper = [3.0,  0.5,  0.5,   0.1]
        x0    = [bio.β_lit, bio.σ, bio.γ, bio.μ]

        best_sse = Inf
        best_x   = x0

        for _ in 1:cfg.n_restarts
            x_init = x0 .* (0.3 .+ 1.4 .* rand(4))
            x_init .= clamp.(x_init, lower .+ 1e-6, upper .- 1e-6)
            try
                res = optimize(obj_full, lower, upper, x_init,
                               Fminbox(LBFGS()),
                               Optim.Options(iterations=300, show_trace=false))
                if Optim.minimum(res) < best_sse
                    best_sse = Optim.minimum(res)
                    best_x   = Optim.minimizer(res)
                end
            catch; end
        end

        β, σ, γ, μ = best_x
        return (β=β, σ=σ, γ=γ, μ=μ,
                sse=best_sse, R0=β/(γ+μ),
                n_params=4)
    end
end


"""
Калибровка дробной SEIRD (Капуто).

Оптимизируется [α, β] при фиксированных σ, γ, μ из литературы,
или [α, β, σ, γ, μ] целиком (full=true).
"""
function calibrate_fractional(data_cases, bio, cfg::Config; full=false)
    N  = cfg.N_population
    I0 = cfg.I0
    E0 = cfg.E0_factor * I0
    n_days = length(data_cases) - 1

    if !full
        # --- [α, β] ---
        function obj_αβ(x)
            α, β = x
            (α ≤ 0.3 || α > 1.0 || β ≤ 0) && return Inf
            try
                sol = solve_fractional(α, β, bio.σ, bio.γ, bio.μ, N, I0, E0, n_days)
                mc = model_new_cases(sol, bio.σ)
                return sse(mc, data_cases)
            catch
                return Inf
            end
        end

        lower = [0.40, 0.01]
        upper = [1.00, 3.0]
        x0    = [0.90, bio.β_lit]

        best_sse = Inf
        best_x   = x0

        for i in 1:cfg.n_restarts
            α_init = 0.5 + 0.5 * rand()
            β_init = bio.β_lit * (0.2 + 1.6 * rand())
            x_init = clamp.([α_init, β_init], lower .+ 1e-6, upper .- 1e-6)
            try
                res = optimize(obj_αβ, lower, upper, x_init,
                               Fminbox(LBFGS()),
                               Optim.Options(iterations=300, show_trace=false))
                if Optim.minimum(res) < best_sse
                    best_sse = Optim.minimum(res)
                    best_x   = Optim.minimizer(res)
                end
            catch; end
        end

        α, β = best_x
        return (α=α, β=β, σ=bio.σ, γ=bio.γ, μ=bio.μ,
                sse=best_sse, R0=β/(bio.γ+bio.μ),
                n_params=2)
    else
        # --- [α, β, σ, γ, μ] ---
        function obj_all(x)
            α, β, σ, γ, μ = x
            (α ≤ 0.3 || α > 1.0 || any(x[2:end] .≤ 0)) && return Inf
            try
                sol = solve_fractional(α, β, σ, γ, μ, N, I0, E0, n_days)
                mc = model_new_cases(sol, σ)
                return sse(mc, data_cases)
            catch
                return Inf
            end
        end

        lower = [0.40, 0.01, 0.02, 0.005, 0.0001]
        upper = [1.00, 3.0,  0.5,  0.5,   0.1]
        x0    = [0.90, bio.β_lit, bio.σ, bio.γ, bio.μ]

        best_sse = Inf
        best_x   = x0

        for _ in 1:cfg.n_restarts
            x_init = [0.5 + 0.5rand(),
                      bio.β_lit * (0.3 + 1.4rand()),
                      bio.σ * (0.5 + rand()),
                      bio.γ * (0.5 + rand()),
                      bio.μ * (0.5 + rand())]
            x_init .= clamp.(x_init, lower .+ 1e-6, upper .- 1e-6)
            try
                res = optimize(obj_all, lower, upper, x_init,
                               Fminbox(LBFGS()),
                               Optim.Options(iterations=300, show_trace=false))
                if Optim.minimum(res) < best_sse
                    best_sse = Optim.minimum(res)
                    best_x   = Optim.minimizer(res)
                end
            catch; end
        end

        α, β, σ, γ, μ = best_x
        return (α=α, β=β, σ=σ, γ=γ, μ=μ,
                sse=best_sse, R0=β/(γ+μ),
                n_params=5)
    end
end


# ════════════════════════════════════════════════════════════════════
# 5. СТАТИСТИЧЕСКОЕ ОБОСНОВАНИЕ α
# ════════════════════════════════════════════════════════════════════

"""
Вычислить AIC, BIC, AICc для модели.

Аргументы:
  sse_val  — сумма квадратов ошибок
  n        — число наблюдений
  k        — число параметров

Возвращает NamedTuple (AIC, BIC, AICc, NLL).
"""
function information_criteria(sse_val, n, k)
    σ² = sse_val / n
    nll = n/2 * log(2π) + n/2 * log(σ²) + n/2  # NLL при MLE σ²

    aic  = 2k + 2nll
    bic  = k * log(n) + 2nll
    aicc = (n > k + 2) ? aic + 2k*(k+1)/(n-k-1) : Inf

    return (AIC=aic, BIC=bic, AICc=aicc, NLL=nll)
end


"""
Тест отношения правдоподобия (LRT).

H₀: классическая модель (α = 1) достаточна
H₁: дробная модель (α ≠ 1) значимо лучше

Статистика: Λ = -2(NLL₀ - NLL₁) ~ χ²(Δk)
где Δk = разница числа параметров.
"""
function likelihood_ratio_test(sse_classic, k_classic,
                                sse_frac, k_frac, n)
    ic_c = information_criteria(sse_classic, n, k_classic)
    ic_f = information_criteria(sse_frac, n, k_frac)

    Δk = k_frac - k_classic
    Λ  = -2 * (ic_f.NLL - ic_c.NLL)  # > 0 если дробная лучше (но NLL ниже)
    # Корректно: Λ = 2*(NLL_null - NLL_alt)
    Λ  = 2 * (ic_c.NLL - ic_f.NLL)

    p_value = Λ > 0 ? ccdf(Chisq(Δk), Λ) : 1.0

    return (Λ=Λ, Δk=Δk, p_value=p_value, ic_classic=ic_c, ic_frac=ic_f)
end


"""
Профиль правдоподобия для α.

Для каждого фиксированного α оптимизируем β (или [β,σ,γ,μ]),
строим зависимость SSE(α). Доверительный интервал: SSE ≤ SSE_min + χ²₁(0.95).
"""
function profile_likelihood_alpha(data_cases, bio, cfg::Config)
    N  = cfg.N_population
    I0 = cfg.I0
    E0 = cfg.E0_factor * I0
    n_days = length(data_cases) - 1
    n = length(data_cases)

    α_grid = collect(cfg.α_profile_range)
    results = DataFrame(α=Float64[], SSE=Float64[], NLL=Float64[],
                        β=Float64[])

    println("\n  Профиль правдоподобия α:")
    for α_val in α_grid
        function obj_fix(x)
            β = x[1]
            β ≤ 0 && return Inf
            try
                sol = solve_fractional(α_val, β, bio.σ, bio.γ, bio.μ, N, I0, E0, n_days)
                mc = model_new_cases(sol, bio.σ)
                return sse(mc, data_cases)
            catch
                return Inf
            end
        end

        best_s = Inf
        best_β = bio.β_lit
        for _ in 1:10
            β0 = bio.β_lit * (0.2 + 1.6rand())
            try
                res = optimize(obj_fix, [0.01], [3.0], [β0],
                               Fminbox(LBFGS()),
                               Optim.Options(iterations=200, show_trace=false))
                if Optim.minimum(res) < best_s
                    best_s = Optim.minimum(res)
                    best_β = Optim.minimizer(res)[1]
                end
            catch; end
        end

        σ² = best_s / n
        nll = n/2 * log(2π) + n/2 * log(max(σ², 1e-20)) + n/2
        push!(results, (α=α_val, SSE=best_s, NLL=nll, β=best_β))
        @printf("    α = %.2f  |  SSE = %.0f  |  β = %.4f\n", α_val, best_s, best_β)
    end

    # Доверительный интервал (χ² с 1 df, уровень 95%)
    min_sse = minimum(results.SSE)
    threshold = min_sse + quantile(Chisq(1), 0.95) * (min_sse / n)
    ci_mask = results.SSE .≤ threshold
    if any(ci_mask)
        ci_low  = minimum(results.α[ci_mask])
        ci_high = maximum(results.α[ci_mask])
    else
        ci_low = ci_high = results.α[argmin(results.SSE)]
    end

    best_α = results.α[argmin(results.SSE)]
    println(@sprintf("    → α* = %.3f, 95%% ДИ: [%.3f, %.3f]", best_α, ci_low, ci_high))

    return results, (α_best=best_α, ci_low=ci_low, ci_high=ci_high)
end


"""
Анализ остатков: автокорреляция и тест Дарбина–Уотсона.

Высокая автокорреляция у классической модели + низкая у дробной
→ α захватывает структурированные отклонения, а не просто шум.
"""
function residual_analysis(data_cases, sol_classical, sol_fractional,
                            σ_c, σ_f)
    mc_c = model_new_cases(sol_classical, σ_c)
    mc_f = model_new_cases(sol_fractional, σ_f)
    n = min(length(data_cases), length(mc_c), length(mc_f))

    res_c = data_cases[1:n] .- mc_c[1:n]
    res_f = data_cases[1:n] .- mc_f[1:n]

    # Автокорреляция (лаг 1)
    acf_c = cor(res_c[1:end-1], res_c[2:end])
    acf_f = cor(res_f[1:end-1], res_f[2:end])

    # Дарбин–Уотсон
    dw_c = sum(diff(res_c).^2) / sum(res_c.^2)
    dw_f = sum(diff(res_f).^2) / sum(res_f.^2)

    # RMSE
    rmse_c = sqrt(mean(res_c.^2))
    rmse_f = sqrt(mean(res_f.^2))

    # MAE
    mae_c = mean(abs.(res_c))
    mae_f = mean(abs.(res_f))

    println("\n┌──────────────────────────────────────────────────┐")
    println("│  АНАЛИЗ ОСТАТКОВ                                 │")
    println("├──────────────────────────────────────────────────┤")
    @printf("│  Классическая:  RMSE=%.1f  MAE=%.1f           \n", rmse_c, mae_c)
    @printf("│    ACF(1)=%.3f  DW=%.3f                        \n", acf_c, dw_c)
    @printf("│  Дробная:       RMSE=%.1f  MAE=%.1f           \n", rmse_f, mae_f)
    @printf("│    ACF(1)=%.3f  DW=%.3f                        \n", acf_f, dw_f)
    println("├──────────────────────────────────────────────────┤")
    if abs(acf_f) < abs(acf_c)
        println("│  ✓ Дробная модель снижает автокорреляцию остатков│")
        println("│    → α объясняет структурированные отклонения   │")
    else
        println("│  ⚠ Автокорреляция не снизилась — возможно,      │")
        println("│    нужна модификация модели (SEIRD+V и т.д.)    │")
    end
    println("└──────────────────────────────────────────────────┘")

    return (res_classical=res_c, res_fractional=res_f,
            acf_c=acf_c, acf_f=acf_f,
            dw_c=dw_c, dw_f=dw_f,
            rmse_c=rmse_c, rmse_f=rmse_f,
            mae_c=mae_c, mae_f=mae_f)
end


# ════════════════════════════════════════════════════════════════════
# 6. ВИЗУАЛИЗАЦИЯ
# ════════════════════════════════════════════════════════════════════

"""
Построить 6-панельную визуализацию результатов.
"""
function plot_results(days, data_cases, dates,
                      sol_c, sol_f, params_c, params_f,
                      profile_df, profile_ci,
                      resid_info, bio;
                      save_path="seird_caputo_results.png")

    gr(size=(1400, 1000), dpi=150)

    mc_c = model_new_cases(sol_c, params_c.σ)
    mc_f = model_new_cases(sol_f, params_f.σ)

    # --- (a) Данные vs модели ---
    p1 = scatter(days, data_cases, ms=2, msw=0, alpha=0.4,
                 color=:red, label="Данные (ежедн.)",
                 xlabel="Дни от начала волны", ylabel="Новые случаи/день",
                 title="(a) Калибровка: данные vs модели")
    plot!(p1, 0:length(mc_c)-1, mc_c, lw=2, color=:purple,
          label=@sprintf("Классическая (SSE=%.0f)", params_c.sse))
    plot!(p1, 0:length(mc_f)-1, mc_f, lw=2, ls=:dash, color=:darkorange,
          label=@sprintf("Дробная α=%.3f (SSE=%.0f)", params_f.α, params_f.sse))

    # --- (b) Все компартменты дробной модели ---
    t = 0:size(sol_f, 1)-1
    p2 = plot(t, sol_f[:, 1], lw=2, color=:teal, label="S",
              xlabel="Дни", ylabel="Человек",
              title=@sprintf("(b) Дробная SEIRD (α=%.3f)", params_f.α))
    plot!(p2, t, sol_f[:, 2], lw=2, color=:orange, label="E")
    plot!(p2, t, sol_f[:, 3], lw=2, color=:red, label="I")
    plot!(p2, t, sol_f[:, 4], lw=2, color=:blue, label="R")
    plot!(p2, t, sol_f[:, 5], lw=2, color=:gray, label="D")

    # --- (c) Профиль правдоподобия α ---
    p3 = plot(profile_df.α, profile_df.SSE, lw=2, marker=:circle, ms=4,
              color=:darkorange, label="SSE(α)",
              xlabel="α (порядок производной)", ylabel="SSE",
              title="(c) Профиль правдоподобия α")
    vline!(p3, [profile_ci.α_best], ls=:dash, color=:purple, lw=1.5,
           label=@sprintf("α* = %.3f", profile_ci.α_best))
    vspan!(p3, [profile_ci.ci_low, profile_ci.ci_high], alpha=0.15,
           color=:purple, label="95% ДИ")

    # --- (d) Остатки: автокорреляция ---
    n_res = length(resid_info.res_classical)
    lags_max = min(20, n_res ÷ 3)
    acf_c_vals = [cor(resid_info.res_classical[1:end-l],
                      resid_info.res_classical[l+1:end]) for l in 1:lags_max]
    acf_f_vals = [cor(resid_info.res_fractional[1:end-l],
                      resid_info.res_fractional[l+1:end]) for l in 1:lags_max]

    p4 = groupedbar(1:lags_max, hcat(acf_c_vals, acf_f_vals),
                    bar_position=:dodge, bar_width=0.4,
                    color=[:purple :darkorange],
                    label=["Классическая" "Дробная"],
                    xlabel="Лаг (дни)", ylabel="Автокорреляция",
                    title="(d) ACF остатков")
    hline!(p4, [1.96/sqrt(n_res), -1.96/sqrt(n_res)],
           ls=:dot, color=:gray, label="95% границы", alpha=0.5)

    # --- (e) Остатки: временной ряд ---
    p5 = plot(days[1:n_res], resid_info.res_classical, lw=1, alpha=0.6,
              color=:purple, label="Классическая",
              xlabel="Дни", ylabel="Остаток (данные − модель)",
              title="(e) Остатки во времени")
    plot!(p5, days[1:n_res], resid_info.res_fractional, lw=1, alpha=0.6,
          color=:darkorange, label="Дробная")
    hline!(p5, [0], ls=:dash, color=:black, alpha=0.3, label="")

    # --- (f) Сводная таблица ---
    p6 = plot(axis=false, grid=false, ticks=nothing,
              title="(f) Сводка", xlim=(0,1), ylim=(0,1))
    text_lines = [
        @sprintf("Штамм: %s", bio.strain),
        "",
        "─── Классическая SEIRD ───",
        @sprintf("β=%.4f  σ=%.4f  γ=%.4f  μ=%.5f", params_c.β, params_c.σ, params_c.γ, params_c.μ),
        @sprintf("R₀=%.2f   SSE=%.0f", params_c.R0, params_c.sse),
        "",
        "─── Дробная SEIRD (Капуто) ───",
        @sprintf("α = %.4f  [%.3f, %.3f]", params_f.α, profile_ci.ci_low, profile_ci.ci_high),
        @sprintf("β=%.4f  σ=%.4f  γ=%.4f  μ=%.5f", params_f.β, params_f.σ, params_f.γ, params_f.μ),
        @sprintf("R₀=%.2f   SSE=%.0f", params_f.R0, params_f.sse),
        "",
        @sprintf("Снижение SSE: %.1f%%", (1-params_f.sse/params_c.sse)*100),
        @sprintf("ACF(1): %.3f → %.3f", resid_info.acf_c, resid_info.acf_f),
        @sprintf("RMSE:   %.1f → %.1f", resid_info.rmse_c, resid_info.rmse_f),
    ]
    for (i, line) in enumerate(text_lines)
        annotate!(p6, 0.05, 1.0 - i * 0.065, text(line, :left, 9, :black))
    end

    # Собираем
    fig = plot(p1, p2, p3, p4, p5, p6,
               layout=(3, 2), size=(1400, 1000),
               margin=8Plots.mm)
    savefig(fig, save_path)
    println("\n✓ Графики сохранены: $save_path")
    return fig
end


# ════════════════════════════════════════════════════════════════════
# 7. ГЛАВНЫЙ ЗАПУСК
# ════════════════════════════════════════════════════════════════════

function main(; config_overrides...)
    cfg = Config(; config_overrides...)

    println("╔══════════════════════════════════════════════════╗")
    println("║  SEIRD: классика + Капуто (Julia)               ║")
    println("╚══════════════════════════════════════════════════╝")

    # 1. Данные
    days, cases, bio, dates = load_wave(cfg)
    n_days = length(cases) - 1
    n = length(cases)

    # 2. Калибровка классической SEIRD
    println("\n▸ Калибровка классической SEIRD (оптимизация β)...")
    params_c = calibrate_classical(cases, bio, cfg; full=false)
    @printf("  β = %.4f, R₀ = %.2f, SSE = %.0f\n", params_c.β, params_c.R0, params_c.sse)

    sol_c = solve_classical(params_c.β, params_c.σ, params_c.γ, params_c.μ,
                            cfg.N_population, cfg.I0, cfg.E0_factor * cfg.I0, n_days)

    # 3. Калибровка дробной SEIRD
    println("\n▸ Калибровка дробной SEIRD (оптимизация [α, β])...")
    params_f = calibrate_fractional(cases, bio, cfg; full=false)
    @printf("  α = %.4f, β = %.4f, R₀ = %.2f, SSE = %.0f\n",
            params_f.α, params_f.β, params_f.R0, params_f.sse)

    sol_f = solve_fractional(params_f.α, params_f.β, params_f.σ, params_f.γ, params_f.μ,
                             cfg.N_population, cfg.I0, cfg.E0_factor * cfg.I0, n_days)

    # 4. Статистическое обоснование
    println("\n" * "═"^55)
    println("  СТАТИСТИЧЕСКОЕ ОБОСНОВАНИЕ α")
    println("═"^55)

    # 4a. Информационные критерии
    ic_c = information_criteria(params_c.sse, n, params_c.n_params)
    ic_f = information_criteria(params_f.sse, n, params_f.n_params)

    println("\n  Информационные критерии:")
    @printf("  Классическая:  AIC=%.1f  BIC=%.1f  AICc=%.1f\n", ic_c.AIC, ic_c.BIC, ic_c.AICc)
    @printf("  Дробная:       AIC=%.1f  BIC=%.1f  AICc=%.1f\n", ic_f.AIC, ic_f.BIC, ic_f.AICc)
    @printf("  ΔAIC = %.1f (< 0 → дробная лучше)\n", ic_f.AIC - ic_c.AIC)
    @printf("  ΔBIC = %.1f (< 0 → дробная лучше)\n", ic_f.BIC - ic_c.BIC)

    if ic_f.AIC < ic_c.AIC
        println("  ✓ Дробная модель предпочтительна по AIC")
    end
    if ic_f.BIC < ic_c.BIC
        println("  ✓ Дробная модель предпочтительна по BIC (более строгий штраф)")
    end

    # 4b. Тест отношения правдоподобия
    lrt = likelihood_ratio_test(params_c.sse, params_c.n_params,
                                 params_f.sse, params_f.n_params, n)
    println("\n  Тест отношения правдоподобия (LRT):")
    @printf("  Λ = %.2f, Δk = %d, p-value = %.2e\n", lrt.Λ, lrt.Δk, lrt.p_value)
    if lrt.p_value < 0.05
        println("  ✓ α статистически значим (p < 0.05)")
    elseif lrt.p_value < 0.10
        println("  ~ α маргинально значим (p < 0.10)")
    else
        println("  ⚠ α не значим при данном объёме данных")
    end

    # 4c. Профиль правдоподобия
    profile_df, profile_ci = profile_likelihood_alpha(cases, bio, cfg)

    # 4d. Анализ остатков
    resid_info = residual_analysis(cases, sol_c, sol_f, params_c.σ, params_f.σ)

    # 5. Интерпретация α
    println("\n" * "═"^55)
    println("  ИНТЕРПРЕТАЦИЯ α = $(round(params_f.α, digits=4))")
    println("═"^55)
    if params_f.α > 0.95
        println("""
  α ≈ 1 → динамика близка к марковской.
  Социальная реакция быстрая, эффект мер мгновенный.
  Дробная модель не даёт существенного улучшения.
  Вывод: классическая SEIRD достаточна для этой волны.""")
    elseif params_f.α > 0.80
        println("""
  α ∈ [0.80, 0.95] → умеренный эффект памяти.
  Общество адаптируется постепенно; ограничительные меры
  проявляются с задержкой; есть инерция поведения.
  Вывод: дробная модель значимо лучше описывает динамику.""")
    elseif params_f.α > 0.65
        println("""
  α ∈ [0.65, 0.80] → сильный эффект памяти.
  Вероятна «социальная усталость», неоднородная реакция
  населения, отложенные последствия мер.
  Вывод: немарковская динамика существенна.""")
    else
        println("""
  α < 0.65 → экстремальная память.
  Волна затяжная, возможны структурные причины:
  неоднородность популяции, суперспредеры, региональные волны.
  Вывод: рассмотреть также пространственные модели.""")
    end

    # 6. Визуализация
    println("\n▸ Построение графиков...")
    plot_results(days, cases, dates, sol_c, sol_f,
                 params_c, params_f, profile_df, profile_ci,
                 resid_info, bio)

    return (data=cases, days=days, dates=dates, bio=bio,
            params_c=params_c, params_f=params_f,
            sol_c=sol_c, sol_f=sol_f,
            profile=profile_df, profile_ci=profile_ci,
            resid=resid_info, lrt=lrt, ic_c=ic_c, ic_f=ic_f)
end


# ════════════════════════════════════════════════════════════════════
# ЗАПУСК
# ════════════════════════════════════════════════════════════════════

# Раскомментируйте и настройте:
#
results = main(
     csv_path       = "russia_covid_waves.csv",
     country_col    = "Россия",
     wave_col       = "Россия_волна",
     wave_number    = 2,
     N_population   = 146_000_000.0,
     I0             = 100.0,
     E0_factor      = 3.0,
     n_restarts     = 30,
     α_profile_range = 0.50:0.02:1.00,
 )
#
# Для другой страны / волны:
# results = main(csv_path="data.csv", country_col="Германия",
#                wave_col="Германия_волна", wave_number=3,
#                N_population=83_000_000.0)