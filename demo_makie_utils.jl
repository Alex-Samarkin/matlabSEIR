# ════════════════════════════════════════════════════════════════════════════════
# demo_makie_utils.jl — Демонстрация графических утилит на базе Makie.jl
# ════════════════════════════════════════════════════════════════════════════════
#
# Назначение:
#   Этот файл демонстрирует все возможности makie_utils.jl для создания
#   высококачественных графиков для научных публикаций с использованием Makie.jl
#
# Преимущества Makie.jl:
#   • Векторная графика высокого качества (SVG, PDF)
#   • Быстрая отрисовка больших данных
#   • Современный API с отличной типографикой
#   • Поддержка CairoMakie (статичные) и GLMakie (интерактивные)
#
# Использование:
#   julia demo_makie_utils.jl
#   или в REPL: include("demo_makie_utils.jl")
#
# Зависимости:
#   using Pkg
#   Pkg.add(["CairoMakie", "GLMakie", "Statistics", "Dates", "Printf", "Distributions"])
#
# ════════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# 0. ПОДГОТОВКА
# ──────────────────────────────────────────────────────────────────────────────

println("\n" * "═"^70)
println("  ДЕМО: Графические утилиты Makie.jl для научных публикаций")
println("═"^70 * "\n")

# Загружаем утилиты
include("makie_utils.jl")

# Импортируем дополнительные пакеты
using CairoMakie   # Статичные изображения
using Statistics
using Dates
using Printf
using Distributions
using Random
using DataFrames

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
fig1, ax1 = quick_plot(x, y_sin,
                       label = "sin(x)",
                       color = :blue,
                       linewidth = 2.5)

# Добавляем вторую кривую
lines!(ax1, x, y_cos,
       label = "cos(x)",
       color = :red,
       linestyle = :dash)

# Добавляем заголовок и подписи
ax1.title = "Тригонометрические функции"
ax1.xlabel = "X (радианы)"
ax1.ylabel = "Значение"

# Сохраняем
save_plot(fig1, filename="makie_demo_01_basic_line.png")
println("    ✓ Сохранён: makie_demo_01_basic_line.png")


# ── Пример 1.2: Точечный график (Scatter) ────────────────────────────────────
println("\n  1.2. Точечный график (quick_scatter)")

# Генерируем данные с корреляцией
x_scatter = randn(150)
y_scatter = 1.5 .* x_scatter .+ randn(150) .* 0.8

fig2, ax2 = quick_scatter(x_scatter, y_scatter,
                          label = "Наблюдения",
                          color = :blue,
                          markersize = 8,
                          marker = :circle,
                          alpha = 0.6)

# Добавляем линию тренда
slope = cov(x_scatter, y_scatter) / var(x_scatter)
intercept = mean(y_scatter) - slope * mean(x_scatter)
x_trend = range(minimum(x_scatter), maximum(x_scatter), length=100)
y_trend = slope .* x_trend .+ intercept

lines!(ax2, x_trend, y_trend,
       label = "Линия тренда",
       color = :red,
       linewidth = 2,
       linestyle = :dash)

ax2.title = "Корреляция между переменными"
ax2.xlabel = "X"
ax2.ylabel = "Y"

save_plot(fig2, filename="makie_demo_02_scatter.png")
println("    ✓ Сохранён: makie_demo_02_scatter.png")


# ── Пример 1.3: Столбчатая диаграмма (Bar) ───────────────────────────────────
println("\n  1.3. Столбчатая диаграмма (quick_bar)")

categories = ["Категория A", "Категория B", "Категория C", 
              "Категория D", "Категория E"]
values = [23, 45, 56, 78, 32]

fig3, ax3 = quick_bar(values,
                      color = :teal,
                      strokecolor = :black,
                      strokewidth = 1)

ax3.title = "Сравнение категорий"
ax3.xlabel = "Категория"
ax3.ylabel = "Значение"

# Подписи по X
ax3.xticks = (1:5, categories)

save_plot(fig3, filename="makie_demo_03_bar.png")
println("    ✓ Сохранён: makie_demo_03_bar.png")


# ── Пример 1.4: Гистограмма (Histogram) ──────────────────────────────────────
println("\n  1.4. Гистограмма (quick_histogram)")

# Генерируем нормальное распределение
data_hist = randn(1000) .* 2 .+ 5  # μ=5, σ=2

fig4, ax4 = quick_histogram(data_hist,
                            color = :teal,
                            strokecolor = :black,
                            strokewidth = 0.5,
                            bins = 30)

ax4.title = "Распределение данных"
ax4.xlabel = "Значение"
ax4.ylabel = "Частота"

# Добавляем теоретическую кривую нормального распределения
dist = Normal(5, 2)
x_pdf = range(-2, 12, length=200)
y_pdf = pdf.(dist, x_pdf) .* length(data_hist) .* (12 - (-2)) / 30  # Масштабирование

lines!(ax4, x_pdf, y_pdf,
       label = "Теоретическое N(5,2)",
       color = :red,
       linewidth = 3,
       linestyle = :dash)

save_plot(fig4, filename="makie_demo_04_histogram.png")
println("    ✓ Сохранён: makie_demo_04_histogram.png")


# ──────────────────────────────────────────────────────────────────────────────
# 2. СТАТИСТИЧЕСКИЕ ГРАФИКИ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 2: Статистические графики")
println("─"^70)

# ── Пример 2.1: График с доверительным интервалом ───────────────────────────
println("\n  2.1. Доверительный интервал (plot_with_band)")

x_ci = 1:100
y_ci = cumsum(randn(100)) .+ 50
ci_width = 1.96 .* std(y_ci) ./ sqrt.(x_ci)  # 95% CI

fig5, ax5 = plot_with_band(x_ci, y_ci, 
                           y_ci .- ci_width, 
                           y_ci .+ ci_width,
                           color = :blue,
                           linewidth = 2)

ax5.title = "Модель с 95% доверительным интервалом"
ax5.xlabel = "Время (дни)"
ax5.ylabel = "Значение"

# Добавляем легенду вручную
Label(fig5[1, 1], "Предсказание ± CI", fontsize = 14, halign = :left)

save_plot(fig5, filename="makie_demo_05_confidence.png")
println("    ✓ Сохранён: makie_demo_05_confidence.png")


# ── Пример 2.2: QQ-plot для проверки нормальности ────────────────────────────
println("\n  2.2. QQ-plot (qqplot_makie)")

# Генерируем данные с разными распределениями
data_normal = randn(200)
data_skewed = randexp(200) .- 1

fig6a, ax6a = qqplot_makie(data_normal,
                           color = :blue,
                           markersize = 6,
                           alpha = 0.5)

ax6a.title = "QQ-plot (нормальное)"

fig6b, ax6b = qqplot_makie(data_skewed,
                           color = :red,
                           markersize = 6,
                           alpha = 0.5)

ax6b.title = "QQ-plot (скошенное)"

# Сохраняем отдельно
save_plot(fig6a, filename="makie_demo_06a_qqplot_normal.png")
save_plot(fig6b, filename="makie_demo_06b_qqplot_skewed.png")
println("    ✓ Сохранены: makie_demo_06a_qqplot_normal.png, makie_demo_06b_qqplot_skewed.png")


# ── Пример 2.3: Корреляционная матрица (Heatmap) ─────────────────────────────
println("\n  2.3. Корреляционная матрица (plot_correlation_matrix_makie)")

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

fig7, ax7 = plot_correlation_matrix_makie(df_corr,
                                          colormap = :balance)

save_plot(fig7, filename="makie_demo_07_correlation.png")
println("    ✓ Сохранён: makie_demo_07_correlation.png")


# ── Пример 2.4: Остатки модели (Residuals Plot) ──────────────────────────────
println("\n  2.4. Анализ остатков модели (plot_residuals_makie)")

# Генерируем данные с нелинейностью
x_res = range(0, 10, length=100)
y_true = 2 .* x_res .+ 0.5 .* x_res.^2 .+ randn(100) .* 5
y_pred = 3 .* x_res .+ 10  # Линейная модель (недообучение)

fig8 = plot_residuals_makie(y_true, y_pred)

save_plot(fig8, filename="makie_demo_08_residuals.png")
println("    ✓ Сохранён: makie_demo_08_residuals.png")


# ──────────────────────────────────────────────────────────────────────────────
# 3. ВРЕМЕННЫЕ РЯДЫ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 3: Временные ряды")
println("─"^70)

# ── Пример 3.1: Одиночный временной ряд ──────────────────────────────────────
println("\n  3.1. Временной ряд (plot_timeseries_makie)")

dates = Date(2020, 1, 1):Day(1):Date(2020, 12, 31)
cases = cumsum(randn(length(dates)) .+ 100) .* 10
cases = max.(cases, 0)  # Отрицательные случаи невозможны

fig9, ax9 = plot_timeseries_makie(dates, cases,
                                  color = :blue,
                                  linewidth = 2)

ax9.title = "Динамика случаев COVID-19 (2020)"
ax9.ylabel = "Накопленные случаи"

save_plot(fig9, filename="makie_demo_09_timeseries.png")
println("    ✓ Сохранён: makie_demo_09_timeseries.png")


# ── Пример 3.2: Несколько временных рядов ────────────────────────────────────
println("\n  3.2. Несколько временных рядов (plot_multi_timeseries_makie)")

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

fig10, ax10 = plot_multi_timeseries_makie(dates, data_multi,
                                          linewidth = 2.5)

ax10.title = "COVID-19: накопленные случаи по странам"
ax10.ylabel = "Случаи"

save_plot(fig10, filename="makie_demo_10_multi_timeseries.png")
println("    ✓ Сохранён: makie_demo_10_multi_timeseries.png")


# ── Пример 3.3: Сравнение двух серий ─────────────────────────────────────────
println("\n  3.3. Сравнение серий (plot_comparison_makie)")

x_comp = 1:50
y_model = 100 .* exp.(-0.1 .* x_comp) .* sin.(0.3 .* x_comp) .+ 50
y_data = y_model .+ randn(50) .* 10

fig11 = plot_comparison_makie(x_comp, y_data, y_model,
                              labels = ("Данные", "Модель"))

save_plot(fig11, filename="makie_demo_11_comparison.png")
println("    ✓ Сохранён: makie_demo_11_comparison.png")


# ──────────────────────────────────────────────────────────────────────────────
# 4. ПАНЕЛИ И ДАШБОАРДЫ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 4: Панели и дашборды")
println("─"^70)

# ── Пример 4.1: Быстрая панель (quick_panel_makie) ───────────────────────────
println("\n  4.1. Быстрая панель графиков (create_figure)")

# Создаём данные для панелей
x1 = range(0, 10, length=100)
y1 = sin.(x1)
x2 = randn(100)
y2 = randn(100)
x3 = randn(500)
x4 = 1:20
y4 = cumsum(randn(20))

# Создаём фигуру с сеткой 2×2
fig12 = Figure(size = (1200, 1000))
axes12 = [Axis(fig12[i, j]) for i in 1:2, j in 1:2]

# Заполняем оси
lines!(axes12[1, 1], x1, y1, color = :blue)
axes12[1, 1].title = "Линейный"

scatter!(axes12[1, 2], x2, y2, color = :red)
axes12[1, 2].title = "Scatter"

hist!(axes12[2, 1], x3, color = :green)
axes12[2, 1].title = "Гистограмма"

lines!(axes12[2, 2], x4, y4, color = :purple)
axes12[2, 2].title = "Временной ряд"

save_plot(fig12, filename="makie_demo_12_panel_2x2.png")
println("    ✓ Сохранён: makie_demo_12_panel_2x2.png")


# ── Пример 4.2: Сложная панель (3x2) ─────────────────────────────────────────
println("\n  4.2. Сложная панель 3×2")

# Создаём фигуру с сеткой 3×2
fig13 = Figure(size = (1400, 1200))

# Создаём 6 осей
axes13 = [Axis(fig13[i, j]) for i in 1:3, j in 1:2]

# 1. Линейный график
lines!(axes13[1, 1], 1:20, cumsum(randn(20)), color = :blue, linewidth = 2)
axes13[1, 1].title = "Временной ряд"

# 2. Scatter
scatter!(axes13[1, 2], randn(50), randn(50), color = :red, markersize = 6)
axes13[1, 2].title = "Scatter"

# 3. Гистограмма
hist!(axes13[2, 1], randn(100), color = :green)
axes13[2, 1].title = "Гистограмма"

# 4. Bar
barplot!(axes13[2, 2], 1:4, rand(4), color = :purple)
axes13[2, 2].title = "Bar"

# 5. Scatter с группами (альтернатива Box Plot)
grp1 = randn(30)
grp2 = randn(30) .+ 1
scatter!(axes13[3, 1], fill(1, length(grp1)) .+ (rand(30) .- 0.5).*0.3, grp1, 
         color = :teal, markersize = 6, alpha = 0.6)
scatter!(axes13[3, 1], fill(2, length(grp2)) .+ (rand(30) .- 0.5).*0.3, grp2, 
         color = :orange, markersize = 6, alpha = 0.6)
axes13[3, 1].title = "Группы (scatter)"
axes13[3, 1].xticks = ([1, 2], ["Группа 1", "Группа 2"])

# 6. Error bars
x_err = 1:10
y_err = cumsum(randn(10))
yerr = rand(10) .* 2
scatter!(axes13[3, 2], x_err, y_err, color = :orange, markersize = 8)
errorbars!(axes13[3, 2], x_err, y_err, yerr, direction = :y, whiskerwidth = 10)
axes13[3, 2].title = "Error Bars"

save_plot(fig13, filename="makie_demo_13_panel_3x2.png")
println("    ✓ Сохранён: makie_demo_13_panel_3x2.png")


# ── Пример 4.3: Dashboard (программное создание) ─────────────────────────────
println("\n  4.3. Программное создание Dashboard")

# Создаём фигуру с сеткой 3×2
fig14 = Figure(size = (1200, 1000))
axes14 = [Axis(fig14[i, j]) for i in 1:3, j in 1:2]

# Заполняем оси
for i in 1:6
    row = ceil(Int, i / 2)
    col = ((i - 1) % 2) + 1
    x_dash = 1:15
    y_dash = cumsum(randn(15)) .+ i * 5
    lines!(axes14[row, col], x_dash, y_dash, color = i, linewidth = 2)
    axes14[row, col].title = "Панель $i"
end

save_plot(fig14, filename="makie_demo_14_dashboard.png")
println("    ✓ Сохранён: makie_demo_14_dashboard.png")


# ──────────────────────────────────────────────────────────────────────────────
# 5. СПЕЦИАЛИЗИРОВАННЫЕ ГРАФИКИ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 5: Специализированные графики")
println("─"^70)

# ── Пример 5.1: Error Bars ───────────────────────────────────────────────────
println("\n  5.1. Error Bars (plot_error_bars_makie)")

x_err = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
y_err = [2.3, 4.1, 5.8, 7.2, 8.9, 10.5, 12.1, 13.8, 15.2, 16.9]
yerr = [0.3, 0.5, 0.4, 0.6, 0.5, 0.7, 0.4, 0.6, 0.5, 0.4]

fig15, ax15 = plot_error_bars_makie(x_err, y_err, yerr,
                                    color = :blue,
                                    markersize = 8,
                                    marker = :circle)

ax15.title = "Измерения с погрешностями"
ax15.xlabel = "X"
ax15.ylabel = "Y ± погрешность"

save_plot(fig15, filename="makie_demo_15_errorbars.png")
println("    ✓ Сохранён: makie_demo_15_errorbars.png")


# ── Пример 5.2: Box Plot (альтернатива) ─────────────────────────────────────
println("\n  5.2. Box Plot (альтернатива - scatter с jitter)")

# Box plot в Makie имеет проблемы - используем альтернативу
groups = ["Контроль", "Группа A", "Группа B", "Группа C"]
data_box = [
    randn(50) .+ 10,
    randn(50) .+ 12,
    randn(50) .+ 15,
    randn(50) .+ 11,
]

# Создаём фигуру напрямую
fig16 = Figure()
ax16 = Axis(fig16[1, 1])

# Рисуем scatter с jitter для каждой группы
for (i, (grp, data)) in enumerate(zip(groups, data_box))
    x_jitter = fill(i, length(data)) .+ (rand(length(data)) .- 0.5) .* 0.3
    scatter!(ax16, x_jitter, data, color = i, markersize = 6, alpha = 0.6, label = grp)
    # Добавляем среднее
    hlines!(ax16, [mean(data)], linewidth = 2, linestyle = :dash, label = "")
end

ax16.title = "Сравнение групп (scatter + jitter)"
ax16.xlabel = "Группа"
ax16.ylabel = "Значение"
ax16.xticks = (1:4, groups)

save_plot(fig16, filename="makie_demo_16_boxplot_alt.png")
println("    ✓ Сохранён: makie_demo_16_boxplot_alt.png (альтернатива)")


# ── Пример 5.3: Contour Plot ─────────────────────────────────────────────────
println("\n  5.3. Контурный график (plot_contour)")

# Создаём данные для контурного графика
x_contour = range(-3, 3, length=100)
y_contour = range(-3, 3, length=100)
z_contour = [sin(sqrt(x^2 + y^2)) for x in x_contour, y in y_contour]

fig17, ax17 = plot_contour(x_contour, y_contour, z_contour,
                           colormap = :viridis)

ax17.title = "Контурный график"
ax17.xlabel = "X"
ax17.ylabel = "Y"

# Добавляем цветовую шкалу
Colorbar(fig17[1, 2], height = Relative(0.9))

save_plot(fig17, filename="makie_demo_17_contour.png")
println("    ✓ Сохранён: makie_demo_17_contour.png")


# ──────────────────────────────────────────────────────────────────────────────
# 6. ТЕМИРОВАНИЕ И СОХРАНЕНИЕ
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 6: Темы и сохранение")
println("─"^70)

# ── Пример 6.1: Publication Theme (полная тема для публикаций) ───────────────
println("\n  6.1. Тема Publication (use_makie_theme)")

use_makie_theme(:publication)

x_nat = range(0, 2π, length=100)
y1_nat = sin.(x_nat)
y2_nat = cos.(x_nat)

fig18, ax18 = quick_plot(x_nat, y1_nat,
                         label = "sin(x)",
                         color = :blue,
                         linewidth = 3)

lines!(ax18, x_nat, y2_nat,
       label = "cos(x)",
       color = :red,
       linewidth = 3,
       linestyle = :dash)

ax18.title = "Пример темы Publication"
ax18.xlabel = "X"
ax18.ylabel = "Y"

# Сохраняем с полной темой (высокое DPI)
save_plot(fig18, filename="makie_demo_18_publication_theme.png", dpi = 600)
println("    ✓ Сохранён: makie_demo_18_publication_theme.png (600 DPI)")


# ── Пример 6.2: Light Theme (для отладки) ────────────────────────────────────
println("\n  6.2. Облегчённая тема (use_makie_theme)")

use_makie_theme(:light)

fig19, ax19 = quick_plot(x_nat, y1_nat,
                         label = "sin(x)",
                         linewidth = 2)

ax19.title = "Облегчённая тема (быстрая отрисовка)"

save_plot(fig19, filename="makie_demo_19_light_theme.png")
println("    ✓ Сохранён: makie_demo_19_light_theme.png (150 DPI)")


# ── Пример 6.3: Векторный SVG ────────────────────────────────────────────────
println("\n  6.3. Векторный формат SVG")

use_makie_theme(:default)

fig20, ax20 = quick_plot(x_nat, y1_nat,
                         label = "sin(x)",
                         linewidth = 2)

ax20.title = "Векторный график (SVG)"

save_plot(fig20, filename="makie_demo_20_vector.svg", format = :svg)
println("    ✓ Сохранён: makie_demo_20_vector.svg (масштабируемый)")


# ── Пример 6.4: PDF формат ───────────────────────────────────────────────────
println("\n  6.4. Векторный формат PDF")

save_plot(fig20, filename="makie_demo_21_vector.pdf", format = :pdf)
println("    ✓ Сохранён: makie_demo_21_vector.pdf (масштабируемый)")


# ──────────────────────────────────────────────────────────────────────────────
# 7. ФИНАЛЬНЫЙ ДАШБОАРД
# ──────────────────────────────────────────────────────────────────────────────

println("\n▸ Раздел 7: Финальный дашборд")
println("─"^70)

println("\n  7.1. Создание итогового дашборда")

# Собираем лучшие графики в один дашборд
# Используем create_figure для большей гибкости

fig_final = Figure(size = (1800, 1400))
axes_final = [Axis(fig_final[i, j]) for i in 1:3, j in 1:2]

# 1. Линейный график
lines!(axes_final[1, 1], x, y_sin, color = :blue, linewidth = 2)
axes_final[1, 1].title = "Линейный график"

# 2. Scatter
scatter!(axes_final[1, 2], x_scatter, y_scatter, color = :red, markersize = 6)
axes_final[1, 2].title = "Scatter plot"

# 3. Доверительный интервал
lines!(axes_final[2, 1], x_ci, y_ci, color = :blue, linewidth = 2)
band!(axes_final[2, 1], x_ci, y_ci .- ci_width, y_ci .+ ci_width, 
      color = (:blue, 0.2))
axes_final[2, 1].title = "Доверительный интервал"

# 4. Временной ряд
lines!(axes_final[2, 2], dates, cases, color = :green, linewidth = 2)
axes_final[2, 2].title = "Временной ряд"
axes_final[2, 2].xticklabelrotation = π/4

# 5. Гистограмма
hist!(axes_final[3, 1], data_hist, color = :teal)
axes_final[3, 1].title = "Гистограмма"

# 6. Корреляционная матрица (упрощённая)
corr_data = randn(100, 5)
corr_matrix = cor(corr_data)
heatmap!(axes_final[3, 2], 1:5, 1:5, corr_matrix, colormap = :balance)
axes_final[3, 2].title = "Корреляционная матрица"

save_plot(fig_final, filename="makie_demo_22_final_dashboard.png", dpi = 300)
println("    ✓ Сохранён: makie_demo_22_final_dashboard.png")


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
    • makie_demo_01_basic_line.png  — линейный график
    • makie_demo_02_scatter.png     — точечный график
    • makie_demo_03_bar.png         — столбчатая диаграмма
    • makie_demo_04_histogram.png   — гистограмма

  Статистические:
    • makie_demo_05_confidence.png  — доверительный интервал
    • makie_demo_06a_qqplot_normal.png    — QQ-plot (нормальное)
    • makie_demo_06b_qqplot_skewed.png    — QQ-plot (скошенное)
    • makie_demo_07_correlation.png — корреляционная матрица
    • makie_demo_08_residuals.png   — анализ остатков

  Временные ряды:
    • makie_demo_09_timeseries.png        — одиночный временной ряд
    • makie_demo_10_multi_timeseries.png  — несколько рядов
    • makie_demo_11_comparison.png        — сравнение серий

  Панели:
    • makie_demo_12_panel_2x2.png   — панель 2×2
    • makie_demo_13_panel_3x2.png   — панель 3×2
    • makie_demo_14_dashboard.png   — программный dashboard

  Специализированные:
    • makie_demo_15_errorbars.png   — error bars
    • makie_demo_16_boxplot.png     — box plot
    • makie_demo_17_contour.png     — контурный график

  Темы и форматы:
    • makie_demo_18_publication_theme.png — Publication тема (600 DPI)
    • makie_demo_19_light_theme.png       — облегчённая тема (150 DPI)
    • makie_demo_20_vector.svg            — векторный SVG
    • makie_demo_21_vector.pdf            — векторный PDF

  Финальный:
    • makie_demo_22_final_dashboard.png — итоговый дашборд

  Всего: 22 файла


  Доступные функции makie_utils.jl:
  ──────────────────────────────────
  Темы:
    • use_makie_theme(:default)       — стандартная тема
    • use_makie_theme(:publication)   — тема для публикаций
    • use_makie_theme(:light)         — облегчённая тема
    • set_theme!(theme)               — применение темы

  Бэкенды:
    • use_makie_backend(:cairo)       — статичные изображения
    • use_makie_backend(:gl)          — интерактивный режим

  Быстрые графики:
    • quick_plot(x, y)                — линейный
    • quick_scatter(x, y)             — scatter
    • quick_bar(values)               — bar chart
    • quick_histogram(data)           — гистограмма
    • quick_boxplot(data)             — box plot

  Статистические:
    • plot_with_band(...)             — с доверительным интервалом
    • qqplot_makie(data)              — QQ-plot
    • plot_correlation_matrix_makie(df) — heatmap корреляций
    • plot_residuals_makie(y_true, y_pred) — анализ остатков

  Временные ряды:
    • plot_timeseries_makie(dates, values)
    • plot_multi_timeseries_makie(dates, dict)
    • plot_comparison_makie(x, y1, y2)

  Панели:
    • create_figure(rows, cols)       — создание сетки
    • quick_panel_makie(data)         — быстрая панель

  Сохранение:
    • save_plot(fig, filename="...")  — сохранить график
    • save_plot(fig, format=:svg)     — векторный формат
    • save_plot_series(figs, names)   — серия графиков

  Специализированные:
    • plot_error_bars_makie(x, y, yerr) — error bars
    • plot_contour(x, y, z)           — контурный график
    • plot_surface(x, y, z)           — 3D поверхность (GLMakie)

  Анимации:
    • create_animation(func, frames)  — создание анимации

  Для получения помощи в REPL:
    ?quick_plot    # знак вопроса перед функцией

""")

println("═"^70 * "\n")

# ──────────────────────────────────────────────────────────────────────────────
# КОНЕЦ ФАЙЛА
# ──────────────────────────────────────────────────────────────────────────────
