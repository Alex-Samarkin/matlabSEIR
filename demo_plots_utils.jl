# ════════════════════════════════════════════════════════════════════════════════
# demo_plots_utils.jl — Демонстрация графических утилит на базе Plots.jl
# ════════════════════════════════════════════════════════════════════════════════
#
# Назначение:
#   Этот файл демонстрирует все возможности plot_utils.jl для создания
#   публикационных графиков в стиле Nature/Science журналов
#
# Использование:
#   julia demo_plots_utils.jl
#   или в REPL: include("demo_plots_utils.jl")
#
# Зависимости:
#   using Pkg
#   Pkg.add(["Plots", "Statistics", "Dates", "Printf", "StatsBase"])
#
# ════════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# 0. ПОДГОТОВКА
# ──────────────────────────────────────────────────────────────────────────────

println("\n" * "═"^70)
println("  ДЕМО: Графические утилиты Plots.jl для научных публикаций")
println("═"^70 * "\n")

# Загружаем утилиты
include("plot_utils.jl")

# Импортируем дополнительные пакеты
using Plots
using Statistics
using Dates
using Printf
using DataFrames
using Random

# Фиксируем генератор случайных чисел для воспроизводимости
Random.seed!(42)

# ──────────────────────────────────────────────────────────────────────────────
# 1. БАЗОВЫЕ ГРАФИКИ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 1: Базовые графики")
println("─"^70)

# ── Пример 1.1: Простой линейный график ─────────────────────────────────────
println("\n  1.1. Простой линейный график (quick_plot)")

x = range(0, 4π, length=200)
y_sin = sin.(x)
y_cos = cos.(x)

# Быстрое построение: quick_plot(x, y; kwargs...)
p1 = quick_plot(x, y_sin,
                title = "Тригонометрические функции",
                label = "sin(x)",
                xlabel = "X (радианы)",
                ylabel = "Значение",
                linewidth = 2.5,
                color = :blue)

# Добавляем вторую кривую на существующий график
quick_plot!(p1, x, y_cos,
            label = "cos(x)",
            linewidth = 2.5,
            color = :red,
            linestyle = :dash)

# Сохраняем с темой Nature
save_plot(p1, filename="demo_01_basic_line.png", theme=:light)
println("    ✓ Сохранён: demo_01_basic_line.png")


# ── Пример 1.2: Точечный график (Scatter) ────────────────────────────────────
println("\n  1.2. Точечный график (quick_scatter)")

# Генерируем данные с корреляцией
x_scatter = randn(150)
y_scatter = 1.5 .* x_scatter .+ randn(150) .* 0.8

p2 = quick_scatter(x_scatter, y_scatter,
                   title = "Корреляция между переменными",
                   label = "Наблюдения",
                   xlabel = "X",
                   ylabel = "Y",
                   markeralpha = 0.6,
                   markersize = 6,
                   markerstrokewidth = 0.5)

# Добавляем линию тренда
slope = cov(x_scatter, y_scatter) / var(x_scatter)
intercept = mean(y_scatter) - slope * mean(x_scatter)
y_trend = slope .* x_scatter .+ intercept
plot!(p2, x_scatter[sortperm(x_scatter)], 
          y_trend[sortperm(x_scatter)],
      label = "Линия тренда",
      color = :red,
      linewidth = 2,
      linestyle = :dash)

save_plot(p2, filename="demo_02_scatter.png", theme=:light)
println("    ✓ Сохранён: demo_02_scatter.png")


# ── Пример 1.3: Столбчатая диаграмма (Bar) ───────────────────────────────────
println("\n  1.3. Столбчатая диаграмма (quick_bar)")

categories = ["Категория A", "Категория B", "Категория C", 
              "Категория D", "Категория E"]
values = [23, 45, 56, 78, 32]

p3 = quick_bar(values,
               labels = categories,
               title = "Сравнение категорий",
               xlabel = "Категория",
               ylabel = "Значение",
               color = :blue,
               fillalpha = 0.7)

# Поворачиваем подписи для читаемости
plot!(p3, xrotation = 45, size = (1400, 900))

save_plot(p3, filename="demo_03_bar.png", theme=:light)
println("    ✓ Сохранён: demo_03_bar.png")


# ── Пример 1.4: Гистограмма (Histogram) ──────────────────────────────────────
println("\n  1.4. Гистограмма (quick_histogram)")

# Генерируем нормальное распределение
data_hist = randn(1000) .* 2 .+ 5  # μ=5, σ=2

p4 = quick_histogram(data_hist,
                     title = "Распределение данных",
                     xlabel = "Значение",
                     ylabel = "Частота",
                     label = "N(5, 2)",
                     color = :teal,
                     fillalpha = 0.6,
                     normalize = false)

# Добавляем теоретическую кривую нормального распределения
using Distributions
dist = Normal(5, 2)
x_pdf = range(0, 10, length=100)
y_pdf = pdf.(dist, x_pdf) .* length(data_hist) .* 0.5  # Масштабирование
plot!(p4, x_pdf, y_pdf,
      label = "Теоретическое N(5,2)",
      color = :red,
      linewidth = 3,
      linestyle = :dash)

save_plot(p4, filename="demo_04_histogram.png", theme=:light)
println("    ✓ Сохранён: demo_04_histogram.png")


# ──────────────────────────────────────────────────────────────────────────────
# 2. СТАТИСТИЧЕСКИЕ ГРАФИКИ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 2: Статистические графики")
println("─"^70)

# ── Пример 2.1: График с доверительным интервалом ───────────────────────────
println("\n  2.1. Доверительный интервал (plot_with_confidence)")

x_ci = 1:100
y_ci = cumsum(randn(100)) .+ 50
ci_width = 1.96 .* std(y_ci) ./ sqrt.(x_ci)  # 95% CI

p5 = plot_with_confidence(x_ci, y_ci, 
                          y_ci .- ci_width, 
                          y_ci .+ ci_width,
                          title = "Модель с 95% доверительным интервалом",
                          label = "Предсказание модели",
                          xlabel = "Время (дни)",
                          ylabel = "Значение",
                          color = :blue)

save_plot(p5, filename="demo_05_confidence.png", theme=:light)
println("    ✓ Сохранён: demo_05_confidence.png")


# ── Пример 2.2: QQ-plot для проверки нормальности ────────────────────────────
println("\n  2.2. QQ-plot (qqplot)")

# Генерируем данные с разными распределениями
data_normal = randn(200)
data_skewed = randexp(200) .- 1

p6a = qqplot(data_normal,
             title = "Нормальное распределение",
             label = "N(0,1)",
             markercolor = :blue,
             markeralpha = 0.5)

p6b = qqplot(data_skewed,
             title = "Скошенное распределение",
             label = "Exp(1)",
             markercolor = :red,
             markeralpha = 0.5)

p6 = plot(p6a, p6b, layout=(1, 2), size=(1800, 800))
save_plot(p6, filename="demo_06_qqplot.png", theme=:light)
println("    ✓ Сохранён: demo_06_qqplot.png")


# ── Пример 2.3: Корреляционная матрица (Heatmap) ─────────────────────────────
println("\n  2.3. Корреляционная матрица (plot_correlation_matrix)")

# Создаём DataFrame с коррелированными переменными
n = 200
df_corr = DataFrame(
    A = randn(n),
    B = randn(n) .* 0.5 .+ randn(n) .* 0.5,  # корреляция с A
    C = randn(n) .* 0.8 .+ randn(n) .* 0.2,  # сильная корреляция с A
    D = randn(n),                             # независима
    E = randn(n) .* 0.3 .+ randn(n) .* 0.7   # слабая корреляция
)

# Добавляем искусственные корреляции
df_corr.B .= df_corr.B .+ 0.6 .* df_corr.A
df_corr.C .= df_corr.C .+ 0.7 .* df_corr.A
df_corr.E .= df_corr.E .+ 0.4 .* df_corr.D

p7 = plot_correlation_matrix(df_corr,
                             title = "Корреляционная матрица",
                             c = :balance,
                             aspect_ratio = 1)

save_plot(p7, filename="demo_07_correlation.png", theme=:light)
println("    ✓ Сохранён: demo_07_correlation.png")


# ── Пример 2.4: Остатки модели (Residuals Plot) ──────────────────────────────
println("\n  2.4. Анализ остатков модели (plot_residuals)")

# Генерируем данные с нелинейностью
x_res = range(0, 10, length=100)
y_true = 2 .* x_res .+ 0.5 .* x_res.^2 .+ randn(100) .* 5
y_pred = 3 .* x_res .+ 10  # Линейная модель (недообучение)

p8 = plot_residuals(y_true, y_pred,
                    title = "Анализ остатков линейной модели",
                    markercolor = :purple,
                    markeralpha = 0.6)

save_plot(p8, filename="demo_08_residuals.png", theme=:light)
println("    ✓ Сохранён: demo_08_residuals.png")


# ──────────────────────────────────────────────────────────────────────────────
# 3. ВРЕМЕННЫЕ РЯДЫ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 3: Временные ряды")
println("─"^70)

# ── Пример 3.1: Одиночный временной ряд ──────────────────────────────────────
println("\n  3.1. Временной ряд (plot_timeseries)")

dates = Date(2020, 1, 1):Day(1):Date(2020, 12, 31)
cases = cumsum(randn(length(dates)) .+ 100) .* 10
cases = max.(cases, 0)  # Отрицательные случаи невозможны

p9 = plot_timeseries(dates, cases,
                     title = "Динамика случаев COVID-19 (2020)",
                     ylabel = "Накопленные случаи",
                     color = :blue,
                     linewidth = 2)

save_plot(p9, filename="demo_09_timeseries.png", theme=:light)
println("    ✓ Сохранён: demo_09_timeseries.png")


# ── Пример 3.2: Несколько временных рядов ────────────────────────────────────
println("\n  3.2. Несколько временных рядов (plot_multi_timeseries)")

# Генерируем данные для нескольких стран
data_multi = Dict(
    "Россия" => cumsum(randn(length(dates)) .+ 50) .* 5,
    "США" => cumsum(randn(length(dates)) .+ 200) .* 15,
    "Германия" => cumsum(randn(length(dates)) .+ 80) .* 8,
)

# Делаем положительные
for k in keys(data_multi)
    data_multi[k] .= max.(data_multi[k], 0)
end

p10 = plot_multi_timeseries(dates, data_multi,
                            title = "COVID-19: накопленные случаи по странам",
                            ylabel = "Случаи",
                            linewidth = 2.5,
                            legend = :topleft)

save_plot(p10, filename="demo_10_multi_timeseries.png", theme=:light)
println("    ✓ Сохранён: demo_10_multi_timeseries.png")


# ── Пример 3.3: Сравнение двух серий ─────────────────────────────────────────
println("\n  3.3. Сравнение серий (plot_comparison)")

x_comp = 1:50
y_model = 100 .* exp.(-0.1 .* x_comp) .* sin.(0.3 .* x_comp) .+ 50
y_data = y_model .+ randn(50) .* 10

p11 = plot_comparison(x_comp, y_data, y_model,
                      labels = ("Данные", "Модель"),
                      xlabel = "Время",
                      ylabel = "Значение")

save_plot(p11, filename="demo_11_comparison.png", theme=:light)
println("    ✓ Сохранён: demo_11_comparison.png")


# ──────────────────────────────────────────────────────────────────────────────
# 4. ПАНЕЛИ И ДАШБОАРДЫ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 4: Панели и дашборды")
println("─"^70)

# ── Пример 4.1: Быстрая панель (quick_panel) ─────────────────────────────────
println("\n  4.1. Быстрая панель графиков (quick_panel)")

# Создаём несколько разных графиков
p_a = plot(1:10, rand(10), title="A", label="Series 1", linewidth=2)
p_b = plot(1:10, rand(10), title="B", label="Series 2", linewidth=2)
p_c = plot(1:10, rand(10), title="C", label="Series 3", linewidth=2)
p_d = plot(1:10, rand(10), title="D", label="Series 4", linewidth=2)

# Автоматическая раскладка (2x2)
p12 = quick_panel([p_a, p_b, p_c, p_d],
                  titles = ["Панель A", "Панель B", "Панель C", "Панель D"],
                  layout = (2, 2),
                  size = (1600, 1200))

save_plot(p12, filename="demo_12_panel_2x2.png", theme=:light)
println("    ✓ Сохранён: demo_12_panel_2x2.png")


# ── Пример 4.2: Сложная панель (3x2) ─────────────────────────────────────────
println("\n  4.2. Сложная панель 3×2")

# Создаём 6 разных типов графиков
plots_3x2 = Plots.Plot[]

# 1. Линейный
push!(plots_3x2, plot(1:20, cumsum(randn(20)), 
                      title="Временной ряд", label="", linewidth=2))

# 2. Scatter
push!(plots_3x2, scatter(randn(50), randn(50),
                         title="Scatter", label="", markeralpha=0.6))

# 3. Гистограмма
push!(plots_3x2, histogram(randn(100), title="Гистограмма", label=""))

# 4. Bar
push!(plots_3x2, bar(["A","B","C","D"], rand(4),
                      title="Bar", label=""))

# 5. Box plot (альтернатива - scatter с jitter)
# boxplot требует StatsPlots.jl, поэтому используем альтернативу
p_box_alt = plot(;title="Box Plot (альтернатива)", legend=:topleft)
grp1_data = randn(30)
grp2_data = randn(30) .+ 1
scatter!(p_box_alt, fill(1, length(grp1_data)) .+ (rand(30) .- 0.5).*0.3, grp1_data, 
         label="Группа 1", markeralpha=0.6, markersize=6)
scatter!(p_box_alt, fill(2, length(grp2_data)) .+ (rand(30) .- 0.5).*0.3, grp2_data, 
         label="Группа 2", markeralpha=0.6, markersize=6)
hline!(p_box_alt, [mean(grp1_data)], linewidth=2, linestyle=:dash, label="")
hline!(p_box_alt, [mean(grp2_data)], linewidth=2, linestyle=:dash, label="")
plot!(p_box_alt, xticks=([1, 2], ["Группа 1", "Группа 2"]))
push!(plots_3x2, p_box_alt)

# 6. Error bars
x_err = 1:10
y_err = cumsum(randn(10))
yerr = rand(10) .* 2
push!(plots_3x2, scatter(x_err, y_err, yerror=yerr,
                         title="Error Bars", label="",
                         markeralpha=0.8))

p13 = quick_panel(plots_3x2,
                  titles = ["Линейный", "Scatter", "Гистограмма",
                           "Bar", "Box Plot", "Error Bars"],
                  layout = (3, 2),
                  size = (1800, 1400))

save_plot(p13, filename="demo_13_panel_3x2.png", theme=:light)
println("    ✓ Сохранён: demo_13_panel_3x2.png")


# ── Пример 4.3: Dashboard (программное создание) ─────────────────────────────
println("\n  4.3. Программное создание Dashboard")

# Создаём 6 графиков для dashboard
dash_plots = Plots.Plot[]
for i in 1:6
    p_temp = plot(1:15, cumsum(randn(15)),
                  title="График $i",
                  label="",
                  linewidth=2)
    push!(dash_plots, p_temp)
end

# Собираем и сохраняем
p14 = quick_panel(dash_plots,
                  titles = ["Панель $i" for i in 1:6],
                  layout = (3, 2),
                  size = (1600, 1000))

save_plot(p14, filename="demo_14_dashboard.png", theme=:light)
println("    ✓ Сохранён: demo_14_dashboard.png")


# ──────────────────────────────────────────────────────────────────────────────
# 5. СПЕЦИАЛИЗИРОВАННЫЕ ГРАФИКИ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 5: Специализированные графики")
println("─"^70)

# ── Пример 5.1: Error Bars ───────────────────────────────────────────────────
println("\n  5.1. Error Bars (plot_error_bars)")

x_err = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
y_err = [2.3, 4.1, 5.8, 7.2, 8.9, 10.5, 12.1, 13.8, 15.2, 16.9]
yerr = [0.3, 0.5, 0.4, 0.6, 0.5, 0.7, 0.4, 0.6, 0.5, 0.4]

p15 = plot_error_bars(x_err, y_err, yerr,
                      title = "Измерения с погрешностями",
                      xlabel = "X",
                      ylabel = "Y ± погрешность",
                      markercolor = :blue,
                      markersize = 8,
                      linewidth = 0)

save_plot(p15, filename="demo_15_errorbars.png", theme=:light)
println("    ✓ Сохранён: demo_15_errorbars.png")


# ── Пример 5.2: Box Plot ─────────────────────────────────────────────────────
println("\n  5.2. Box Plot (quick_boxplot)")

println("    ⚠ Box plot требует StatsPlots.jl")
println("    Для установки: using Pkg; Pkg.add(\"StatsPlots\")")
println("    Пропускаем этот пример...")

# Создаём заглушку - используем violin plot вместо boxplot
# или просто создаём простой scatter
groups = ["Контроль", "Группа A", "Группа B", "Группа C"]
data_box = [
    randn(50) .+ 10,
    randn(50) .+ 12,
    randn(50) .+ 15,
    randn(50) .+ 11,
]

# Альтернатива: используем scatter с jitter
p16 = plot(;title="Сравнение групп (альтернатива Box Plot)",
           xlabel="Группа",
           ylabel="Значение",
           legend=:topleft)

for (i, (grp, data)) in enumerate(zip(groups, data_box))
    x_jitter = fill(i, length(data)) .+ (rand(length(data)) .- 0.5) .* 0.3
    scatter!(p16, x_jitter, data, label=grp, markeralpha=0.6, markersize=6)
    # Добавляем среднее
    hline!(p16, [mean(data)], linewidth=2, linestyle=:dash, label="")
end

# Подписи по X
plot!(p16, xticks=(1:4, groups), xrotation=0)

save_plot(p16, filename="demo_16_boxplot_alt.png", theme=:light)
println("    ✓ Сохранён: demo_16_boxplot_alt.png (альтернатива)")


# ──────────────────────────────────────────────────────────────────────────────
# 6. ТЕМИРОВАНИЕ И СОХРАНЕНИЕ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 6: Темы и сохранение")
println("─"^70)

# ── Пример 6.1: Nature Theme (полная тема для публикаций) ───────────────────
println("\n  6.1. Тема Nature/Science (use_nature_theme)")

use_nature_theme()

x_nat = range(0, 2π, length=100)
y1_nat = sin.(x_nat)
y2_nat = cos.(x_nat)

p17 = plot(x_nat, y1_nat,
           title = "Пример темы Nature/Science",
           label = "sin(x)",
           xlabel = "X",
           ylabel = "Y",
           linewidth = 3,
           color = :blue)
plot!(p17, x_nat, y2_nat,
      label = "cos(x)",
      linewidth = 3,
      color = :red,
      linestyle = :dash)

# Сохраняем с полной темой (высокое DPI)
save_plot(p17, filename="demo_17_nature_theme.png", theme=:nature)
println("    ✓ Сохранён: demo_17_nature_theme.png (600 DPI)")


# ── Пример 6.2: Light Theme (для отладки) ────────────────────────────────────
println("\n  6.2. Облегчённая тема (use_light_theme)")

use_light_theme()

p18 = plot(x_nat, y1_nat,
           title = "Облегчённая тема (быстрая отрисовка)",
           label = "sin(x)",
           linewidth = 2)

save_plot(p18, filename="demo_18_light_theme.png", theme=:light)
println("    ✓ Сохранён: demo_18_light_theme.png (150 DPI)")


# ── Пример 6.3: Векторный SVG ────────────────────────────────────────────────
println("\n  6.3. Векторный формат SVG")

p19 = plot(x_nat, y1_nat,
           title = "Векторный график (SVG)",
           label = "sin(x)",
           linewidth = 2)

save_plot(p19, filename="demo_19_vector.svg", format=:svg)
println("    ✓ Сохранён: demo_19_vector.svg (масштабируемый)")


# ──────────────────────────────────────────────────────────────────────────────
# 7. ФИНАЛЬНЫЙ ДАШБОАРД
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 7: Финальный дашборд")
println("─"^70)

println("\n  7.1. Создание итогового дашборда")

# Собираем лучшие графики в один дашборд
final_plots = [
    p1,   # Базовый линейный
    p2,   # Scatter
    p5,   # Доверительный интервал
    p9,   # Временной ряд
    p12,  # Панель 2x2
    p15,  # Error bars
]

final_titles = [
    "Линейный график",
    "Scatter plot",
    "Доверительный интервал",
    "Временной ряд",
    "Панель 2×2",
    "Error Bars"
]

p_final = quick_panel(final_plots,
                      titles = final_titles,
                      layout = (3, 2),
                      size = (2000, 1600),
                      bottom_margin = 10Plots.mm)

save_plot(p_final, filename="demo_20_final_dashboard.png", theme=:light)
println("    ✓ Сохранён: demo_20_final_dashboard.png")


# ──────────────────────────────────────────────────────────────────────────────
# ИТОГИ
# ──────────────────────────────────────────────────────────────────────────────

println("\n" * "═"^70)
println("  ДЕМО ЗАВЕРШЕНО")
println("═"^70)
println("""

  Созданные файлы:
  ─────────────────
  Базовые графики:
    • demo_01_basic_line.png    — линейный график
    • demo_02_scatter.png       — точечный график
    • demo_03_bar.png           — столбчатая диаграмма
    • demo_04_histogram.png     — гистограмма

  Статистические:
    • demo_05_confidence.png    — доверительный интервал
    • demo_06_qqplot.png        — QQ-plot
    • demo_07_correlation.png   — корреляционная матрица
    • demo_08_residuals.png     — анализ остатков

  Временные ряды:
    • demo_09_timeseries.png    — одиночный временной ряд
    • demo_10_multi_timeseries  — несколько рядов
    • demo_11_comparison.png    — сравнение серий

  Панели:
    • demo_12_panel_2x2.png     — панель 2×2
    • demo_13_panel_3x2.png     — панель 3×2
    • demo_14_dashboard.png     — программный dashboard

  Специализированные:
    • demo_15_errorbars.png     — error bars
    • demo_16_boxplot_alt.png   — альтернатива box plot (scatter + jitter)

  Темы и форматы:
    • demo_17_nature_theme.png  — Nature/Science тема (600 DPI)
    • demo_18_light_theme.png   — облегчённая тема (150 DPI)
    • demo_19_vector.svg        — векторный SVG

  Финальный:
    • demo_20_final_dashboard.png — итоговый дашборд

  Всего: 20 файлов


  Доступные функции plot_utils.jl:
  ────────────────────────────────
  Темы:
    • use_nature_theme()        — тема для публикаций
    • use_light_theme()         — облегчённая тема

  Быстрые графики:
    • quick_plot(x, y)          — линейный
    • quick_scatter(x, y)       — scatter
    • quick_bar(values)         — bar chart
    • quick_histogram(data)     — гистограмма
    • quick_boxplot(data)       — box plot

  Статистические:
    • plot_with_confidence(...) — с доверительным интервалом
    • qqplot(data)              — QQ-plot
    • plot_correlation_matrix(df) — heatmap корреляций
    • plot_residuals(y_true, y_pred) — анализ остатков

  Временные ряды:
    • plot_timeseries(dates, values)
    • plot_multi_timeseries(dates, dict)
    • plot_comparison(x, y1, y2)

  Панели:
    • quick_panel([p1, p2, ...])      — быстрая панель
    • create_dashboard()              — создание dashboard
    • add_plot!(dash, plot)           — добавить в dashboard

  Сохранение:
    • save_plot(p, filename="...")    — сохранить график
    • save_plot(p, format=:svg)       — векторный формат

  Для получения помощи:
    ?quick_plot    # в REPL: знак вопроса перед функцией

""")

println("═"^70 * "\n")

# ──────────────────────────────────────────────────────────────────────────────
# КОНЕЦ ФАЙЛА
# ──────────────────────────────────────────────────────────────────────────────
