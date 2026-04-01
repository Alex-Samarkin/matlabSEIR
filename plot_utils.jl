# ════════════════════════════════════════════════════════════════════════════════
# plot_utils.jl — Унифицированные утилиты для построения графиков (Plots.jl)
# ════════════════════════════════════════════════════════════════════════════════
#
# Назначение:
#   Быстрое создание качественных графиков для научных публикаций
#   с поддержкой панелей/дашбордов и экспортом в PNG/SVG
#
# Бэкенды: GR (по умолчанию), PlotlyJS (интерактивный)
#
# Использование:
#   include("plot_utils.jl")
#   p = quick_plot(x, y, title="График")
#   save_plot(p, "output.png")  # или "output.svg"
#
# ════════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# 1. ИМПОРТ БИБЛИОТЕК
# ──────────────────────────────────────────────────────────────────────────────

using Plots
using Statistics
using Dates
using Printf
using StatsBase: cors

# ──────────────────────────────────────────────────────────────────────────────
# 2. НАСТРОЙКИ И ТЕМЫ
# ──────────────────────────────────────────────────────────────────────────────

"""
    NatureTheme

Структура с параметрами темы для научных публикаций (Nature/Science стиль)
"""
Base.@kwdef struct NatureTheme
    # Размеры
    width::Int = 2102
    height::Int = 1600
    dpi::Int = 600
    
    # Шрифты
    fontfamily::String = "Arial"
    titlefontsize::Int = 28
    guidefontsize::Int = 24
    tickfontsize::Int = 20
    legendfontsize::Int = 20
    
    # Линии
    linewidth::Float64 = 2.5
    markerstrokewidth::Float64 = 1.5
    markersize::Float64 = 8
    
    # Сетка
    grid::Bool = true
    gridalpha::Float64 = 0.25
    gridlinewidth::Float64 = 1.0
    gridstyle::Symbol = :dot
    
    # Оси
    framestyle::Symbol = :box
    tick_direction::Symbol = :in
    
    # Отступы (мм)
    margin::Float64 = 8
    left_margin::Float64 = 12
    bottom_margin::Float64 = 10
    
    # Цвета (Wong 2011 colorblind-safe)
    palette::Vector{RGB} = [
        RGB(0/255,  114/255, 178/255),   # синий
        RGB(230/255, 159/255,   0/255),   # жёлтый
        RGB(  0/255, 158/255, 115/255),   # зелёный
        RGB(213/255,  94/255,   0/255),   # оранжевый
        RGB( 86/255, 180/255, 233/255),   # голубой
        RGB(204/255, 121/255, 167/255),   # лиловый
        RGB(  0/255,   0/255,   0/255),   # чёрный
    ]
    
    # Фон
    background_color::Symbol = :white
    foreground_color::Symbol = :black
end

"""
    LightTheme

Облегчённая тема для быстрой отладки
"""
Base.@kwdef struct LightTheme
    width::Int = 1200
    height::Int = 800
    dpi::Int = 150
    fontfamily::String = "Arial"
    titlefontsize::Int = 18
    guidefontsize::Int = 16
    tickfontsize::Int = 14
    legendfontsize::Int = 12
    linewidth::Float64 = 2.0
    gridalpha::Float64 = 0.2
end

# Глобальная тема по умолчанию
const DEFAULT_THEME = NatureTheme()
const LIGHT_THEME = LightTheme()

# ──────────────────────────────────────────────────────────────────────────────
# 3. ПРИМЕНЕНИЕ ТЕМ
# ──────────────────────────────────────────────────────────────────────────────

"""
    apply_theme(theme::NatureTheme)

Применяет тему к Plots.default
"""
function apply_theme(theme::NatureTheme)
    Plots.default(
        size = (theme.width, theme.height),
        dpi = theme.dpi,
        fontfamily = theme.fontfamily,
        titlefontsize = theme.titlefontsize,
        guidefontsize = theme.guidefontsize,
        tickfontsize = theme.tickfontsize,
        legendfontsize = theme.legendfontsize,
        linewidth = theme.linewidth,
        markerstrokewidth = theme.markerstrokewidth,
        markersize = theme.markersize,
        grid = theme.grid,
        gridalpha = theme.gridalpha,
        gridlinewidth = theme.gridlinewidth,
        gridstyle = theme.gridstyle,
        framestyle = theme.framestyle,
        tick_direction = theme.tick_direction,
        left_margin = Plots.mm(theme.left_margin),
        bottom_margin = Plots.mm(theme.bottom_margin),
        right_margin = Plots.mm(theme.margin),
        top_margin = Plots.mm(theme.margin),
        palette = theme.palette,
        background_color = theme.background_color,
        foreground_color = theme.foreground_color,
        legend = :topright,
        legendlinewidth = 2.5,
    )
    return nothing
end

"""
    apply_theme(theme::LightTheme)

Применяет облегчённую тему
"""
function apply_theme(theme::LightTheme)
    Plots.default(
        size = (theme.width, theme.height),
        dpi = theme.dpi,
        fontfamily = theme.fontfamily,
        titlefontsize = theme.titlefontsize,
        guidefontsize = theme.guidefontsize,
        tickfontsize = theme.tickfontsize,
        legendfontsize = theme.legendfontsize,
        linewidth = theme.linewidth,
        grid = true,
        gridalpha = theme.gridalpha,
        framestyle = :box,
        tick_direction = :in,
        margin = Plots.mm(8),
        left_margin = Plots.mm(10),
        bottom_margin = Plots.mm(8),
        background_color = :white,
        legend = :topright,
    )
    return nothing
end

"""
    use_nature_theme()

Устанавливает тему для научных публикаций
"""
function use_nature_theme()
    apply_theme(DEFAULT_THEME)
    @info "Применена тема Nature/Science"
    return nothing
end

"""
    use_light_theme()

Устанавливает облегчённую тему для отладки
"""
function use_light_theme()
    apply_theme(LIGHT_THEME)
    @info "Применена облегчённая тема"
    return nothing
end

# ──────────────────────────────────────────────────────────────────────────────
# 4. БЭКЕНДЫ
# ──────────────────────────────────────────────────────────────────────────────

"""
    use_backend(backend::Symbol)

Переключает бэкенд: :gr, :plotlyjs, :pyplot

Пример:
    use_backend(:gr)        # статичные PNG/SVG
    use_backend(:plotlyjs)  # интерактивные HTML
"""
function use_backend(backend::Symbol)
    if backend == :gr
        Plots.gr()
        @info "Бэкенд: GR (статичные графики)"
    elseif backend == :plotlyjs
        Plots.plotlyjs()
        @info "Бэкенд: PlotlyJS (интерактивные графики)"
    elseif backend == :pyplot
        Plots.pyplot()
        @info "Бэкенд: PyPlot"
    else
        @warn "Неизвестный бэкенд: $backend, используется GR"
        Plots.gr()
    end
    return nothing
end

# ──────────────────────────────────────────────────────────────────────────────
# 5. БЫСТРОЕ ПОСТРОЕНИЕ ГРАФИКОВ
# ──────────────────────────────────────────────────────────────────────────────

"""
    quick_plot(x, y; kwargs...)

Быстрое построение линейного графика с настройками по умолчанию.

Аргументы:
  - `x`, `y`: данные (векторы, диапазоны)
  - `kwargs`: любые параметры Plots.plot

Возвращает:
  Plot object

Пример:
    x = range(0, 10, length=100)
    y = sin.(x)
    p = quick_plot(x, y, title="Синус", label="sin(x)")
"""
function quick_plot(x, y; kwargs...)
    p = plot(x, y; kwargs...)
    display(p)
    return p
end

"""
    quick_plot!(p, x, y; kwargs...)

Добавить данные на существующий график
"""
function quick_plot!(p::Plots.Plot, x, y; kwargs...)
    plot!(p, x, y; kwargs...)
    return p
end

"""
    quick_scatter(x, y; kwargs...)

Быстрое построение точечного графика (scatter)
"""
function quick_scatter(x, y; kwargs...)
    p = scatter(x, y; kwargs...)
    display(p)
    return p
end

"""
    quick_bar(values; labels=nothing, kwargs...)

Быстрое построение столбчатой диаграммы
"""
function quick_bar(values::AbstractVector; labels=nothing, kwargs...)
    if labels === nothing
        p = bar(values; kwargs...)
    else
        p = bar(labels, values; kwargs...)
    end
    display(p)
    return p
end

"""
    quick_histogram(data; kwargs...)

Быстрое построение гистограммы
"""
function quick_histogram(data::AbstractVector; kwargs...)
    p = histogram(data; kwargs...)
    display(p)
    return p
end

"""
    quick_boxplot(data; labels=nothing, kwargs...)

Быстрое построение box plot
"""
function quick_boxplot(data::AbstractVector; labels=nothing, kwargs...)
    p = boxplot(labels, data; kwargs...)
    display(p)
    return p
end

# ──────────────────────────────────────────────────────────────────────────────
# 6. СТАТИСТИЧЕСКИЕ ГРАФИКИ
# ──────────────────────────────────────────────────────────────────────────────

"""
    plot_with_confidence(x, y_mean, y_lower, y_upper; kwargs...)

График с доверительным интервалом (заливка между lower и upper)

Аргументы:
  - `x`: ось X
  - `y_mean`: среднее значение
  - `y_lower`: нижняя граница CI
  - `y_upper`: верхняя граница CI
  - `kwargs`: параметры для plot

Пример:
    x = 1:100
    y = cumsum(randn(100))
    ci = 1.96 * std(y) / sqrt(length(y))
    plot_with_confidence(x, y, y - ci, y + ci, label="Модель")
"""
function plot_with_confidence(x, y_mean, y_lower, y_upper; kwargs...)
    p = plot(x, y_mean; kwargs...)
    
    # Добавляем доверительный интервал
    plot!(p, x, y_lower; 
          linewidth=0, 
          fill=(y_upper, 0.2), 
          label="", 
          color=kwargs[:color])
    
    display(p)
    return p
end

"""
    plot_residuals(y_true, y_pred; kwargs...)

График остатков модели (residuals plot)

Аргументы:
  - `y_true`: фактические значения
  - `y_pred`: предсказанные значения
  - `kwargs`: параметры

Возвращает:
  Tuple из (scatter plot, histogram residuals)
"""
function plot_residuals(y_true::AbstractVector, y_pred::AbstractVector; kwargs...)
    residuals = y_true .- y_pred
    
    # Scatter: predicted vs residuals
    p1 = scatter(y_pred, residuals;
                 xlabel = "Предсказанные значения",
                 ylabel = "Остатки",
                 title = "Остатки модели",
                 legend = false,
                 kwargs...)
    hline!(p1, [0], color=:red, linestyle=:dash, label="")
    
    # Histogram residuals
    p2 = histogram(residuals;
                   xlabel = "Остатки",
                   ylabel = "Частота",
                   title = "Распределение остатков",
                   legend = false,
                   kwargs...)
    
    # QQ-plot
    p3 = qqplot(residuals;
                title = "QQ-plot",
                kwargs...)
    
    p = plot(p1, p2, p3, layout=(1, 3), size=(1800, 600))
    display(p)
    return p
end

"""
    qqplot(data; kwargs...)

QQ-plot для проверки нормальности распределения
"""
function qqplot(data::AbstractVector; kwargs...)
    n = length(data)
    sorted_data = sort(data)
    
    # Теоретические квантили нормального распределения
    theoretical = quantile.(Normal(), (1:n .- 0.5) ./ n)
    
    # Нормализация данных
    data_normalized = (sorted_data .- mean(sorted_data)) ./ std(sorted_data)
    
    p = scatter(theoretical, data_normalized;
                xlabel = "Теоретические квантили",
                ylabel = "Выборочные квантили",
                title = "QQ-plot",
                legend = false,
                kwargs...)
    
    # Линия y=x
    min_val = min(minimum(theoretical), minimum(data_normalized))
    max_val = max(maximum(theoretical), maximum(data_normalized))
    plot!(p, [min_val, max_val], [min_val, max_val], 
          color=:red, linestyle=:dash, label="")
    
    return p
end

"""
    plot_correlation_matrix(data; labels=nothing, kwargs...)

Heatmap корреляционной матрицы

Аргументы:
  - `data`: DataFrame или матрица (столбцы = переменные)
  - `labels`: имена переменных
  - `kwargs`: параметры
"""
function plot_correlation_matrix(data; labels=nothing, kwargs...)
    # Вычисляем корреляционную матрицу
    if typeof(data) <: AbstractMatrix
        corr_matrix = cors(data)
        if labels === nothing
            labels = ["Var $i" for i in 1:size(data, 2)]
        end
    else
        # DataFrame
        numeric_cols = select(data, [name for name in names(data) if eltype(data[!, name]) <: Real])
        corr_matrix = cors(Matrix(numeric_cols))
        labels = names(numeric_cols)
    end
    
    p = heatmap(labels, labels, corr_matrix;
                xlabel = "Переменная",
                ylabel = "Переменная",
                title = "Корреляционная матрица",
                aspect_ratio = 1,
                c = :balance,
                kwargs...)
    
    # Добавляем значения
    for i in 1:length(labels), j in 1:length(labels)
        annotate!(i, j, text(@sprintf("%.2f", corr_matrix[j, i]), 10, :center))
    end
    
    display(p)
    return p
end

# ──────────────────────────────────────────────────────────────────────────────
# 7. ПАНЕЛИ И ДАШБОАРДЫ
# ──────────────────────────────────────────────────────────────────────────────

"""
    Dashboard

Структура для управления панелями графиков
"""
Base.@kwdef struct Dashboard
    plots::Vector{Plots.Plot} = Plots.Plot[]
    titles::Vector{String} = String[]
    layout::Tuple{Int, Int} = (1, 1)
    size::Tuple{Int, Int} = (1600, 1200)
end

"""
    add_plot!(dashboard, plot; title="")

Добавить график в панель
"""
function add_plot!(dashboard::Dashboard, p::Plots.Plot; title::String="")
    push!(dashboard.plots, p)
    push!(dashboard.titles, title)
    
    # Обновляем layout
    n = length(dashboard.plots)
    cols = ceil(Int, sqrt(n))
    rows = ceil(Int, n / cols)
    dashboard = Dashboard(dashboard.plots, dashboard.titles, (rows, cols), dashboard.size)
    
    return dashboard
end

"""
    create_dashboard(; size=(1600, 1200))

Создать пустую панель
"""
function create_dashboard(; size=(1600, 1200))
    return Dashboard(size=size)
end

"""
    quick_panel(plots; titles=nothing, layout=nothing, size=(1600, 1200), kwargs...)

Быстрое создание панели из нескольких графиков

Аргументы:
  - `plots`: вектор Plot объектов
  - `titles`: заголовки для каждого графика (опционально)
  - `layout`: кортеж (rows, cols) или :auto для авто-раскладки
  - `size`: размер итогового изображения
  - `kwargs`: дополнительные параметры

Пример:
    p1 = plot(1:10, rand(10), title="График 1")
    p2 = plot(1:10, rand(10), title="График 2")
    panel = quick_panel([p1, p2], layout=(1, 2), size=(1600, 600))
"""
function quick_panel(plots::Vector{<:Plots.Plot}; 
                     titles=nothing, 
                     layout=nothing, 
                     size=(1600, 1200),
                     kwargs...)
    
    # Авто-раскладка
    if layout === nothing || layout === :auto
        n = length(plots)
        cols = ceil(Int, sqrt(n))
        rows = ceil(Int, n / cols)
        layout = (rows, cols)
    end
    
    # Добавляем заголовки если есть
    if titles !== nothing
        for (i, (p, t)) in enumerate(zip(plots, titles))
            plot!(p, title=t, titlefontsize=16)
        end
    end
    
    p = plot(plots...; layout=layout, size=size, kwargs...)
    display(p)
    return p
end

"""
    quick_panel(plots...; kwargs...)

Версия с varargs для удобства
"""
function quick_panel(plots::Plots.Plot...; kwargs...)
    return quick_panel(collect(plots); kwargs...)
end

# ──────────────────────────────────────────────────────────────────────────────
# 8. СОХРАНЕНИЕ ГРАФИКОВ
# ──────────────────────────────────────────────────────────────────────────────

"""
    save_plot(p; filename, format=:auto, theme=:nature)

Сохраняет график в файл.

Аргументы:
  - `p`: Plot объект
  - `filename`: имя файла (с расширением или без)
  - `format`: :png, :svg, :pdf, :eps, :auto (по расширению)
  - `theme`: :nature или :light

Пример:
    save_plot(p, filename="my_plot.png")
    save_plot(p, filename="my_plot", format=:svg)  # будет my_plot.svg
"""
function save_plot(p::Plots.Plot; 
                   filename::String, 
                   format::Symbol=:auto,
                   theme::Symbol=:nature)
    
    # Применяем тему если нужно
    if theme == :nature
        apply_theme(DEFAULT_THEME)
    elseif theme == :light
        apply_theme(LIGHT_THEME)
    end
    
    # Определяем формат
    if format == :auto
        if endswith(filename, ".png")
            format = :png
        elseif endswith(filename, ".svg")
            format = :svg
        elseif endswith(filename, ".pdf")
            format = :pdf
        elseif endswith(filename, ".eps")
            format = :eps
        else
            format = :png  # по умолчанию
            filename = filename * ".png"
        end
    else
        # Добавляем расширение если нет
        if !occursin('.', filename)
            filename = filename * "." * string(format)
        end
    end
    
    # Сохраняем
    Plots.savefig(p, filename)
    @info "График сохранён: $filename (format=$format)"
    
    return filename
end

"""
    save_plot(p, filename::String)

Упрощённая версия сохранения
"""
function save_plot(p::Plots.Plot, filename::String)
    return save_plot(p; filename=filename)
end

"""
    save_panel(plots, filename; layout=:auto, size=(1600, 1200), kwargs...)

Сохраняет панель графиков
"""
function save_panel(plots::Vector{<:Plots.Plot}, filename::String; 
                    layout=:auto, size=(1600, 1200), kwargs...)
    p = quick_panel(plots; layout=layout, size=size, kwargs...)
    return save_plot(p, filename=filename)
end

# ──────────────────────────────────────────────────────────────────────────────
# 9. ПРЕДУСТАНОВЛЕННЫЕ ТИПЫ ГРАФИКОВ
# ──────────────────────────────────────────────────────────────────────────────

"""
    plot_timeseries(dates, values; kwargs...)

Специализированный график временного ряда

Пример:
    dates = Date(2020,1,1):Day(1):Date(2020,12,31)
    values = cumsum(randn(366))
    plot_timeseries(dates, values, title="Временной ряд")
"""
function plot_timeseries(dates::AbstractVector{<:Date}, values::AbstractVector; kwargs...)
    p = plot(dates, values;
             xlabel = "Дата",
             ylabel = "Значение",
             xrotation = 45,
             legend = :topright,
             kwargs...)
    display(p)
    return p
end

"""
    plot_multi_timeseries(dates, data_dict; kwargs...)

Несколько временных рядов на одном графике

Аргументы:
  - `dates`: общие даты
  - `data_dict`: Dict{String, Vector} с именами серий и данными

Пример:
    data = Dict("Россия" => ru_cases, "США" => us_cases)
    plot_multi_timeseries(dates, data)
"""
function plot_multi_timeseries(dates::AbstractVector{<:Date}, 
                                data_dict::Dict{String, <:AbstractVector};
                                kwargs...)
    p = plot(xlabel="Дата", ylabel="Значение", xrotation=45, kwargs...)
    
    for (label, values) in data_dict
        plot!(p, dates, values, label=label)
    end
    
    display(p)
    return p
end

"""
    plot_comparison(x, y1, y2; labels=("Series 1", "Series 2"), kwargs...)

Сравнение двух серий данных
"""
function plot_comparison(x, y1::AbstractVector, y2::AbstractVector; 
                         labels::Tuple{String,String}=("Series 1", "Series 2"),
                         kwargs...)
    p = plot(x, y1, label=labels[1], kwargs...)
    plot!(p, x, y2, label=labels[2])
    
    # Добавляем разность
    diff = y1 .- y2
    p2 = plot(x, diff, label="Разность", fill=0, fillalpha=0.3)
    
    panel = quick_panel([p, p2], layout=(2, 1), size=(1200, 800))
    return panel
end

"""
    plot_error_bars(x, y, yerr; kwargs...)

График с error bars (погрешностями)
"""
function plot_error_bars(x::AbstractVector, y::AbstractVector, yerr::AbstractVector; kwargs...)
    p = scatter(x, y; yerror=yerr, kwargs...)
    plot!(x, y; kwargs...)
    display(p)
    return p
end

# ──────────────────────────────────────────────────────────────────────────────
# 10. ИНТЕРАКТИВНЫЕ ГРАФИКИ (PLOTLYJS)
# ──────────────────────────────────────────────────────────────────────────────

"""
    make_interactive(p)

Конвертирует график в интерактивный (PlotlyJS)
"""
function make_interactive(p::Plots.Plot)
    Plots.plotlyjs()
    p_plotly = plot(p)
    display(p_plotly)
    return p_plotly
end

"""
    save_interactive(p, filename)

Сохраняет интерактивный график как HTML
"""
function save_interactive(p::Plots.Plot, filename::String)
    Plots.plotlyjs()
    
    # Добавляем .html если нет расширения
    if !endswith(filename, ".html")
        filename = filename * ".html"
    end
    
    Plots.savefig(p, filename)
    @info "Интерактивный график сохранён: $filename"
    return filename
end

# ──────────────────────────────────────────────────────────────────────────────
# 11. ПРИМЕРЫ И ДЕМО
# ──────────────────────────────────────────────────────────────────────────────

"""
    demo_plots()

Демонстрация возможностей библиотеки
"""
function demo_plots()
    @info "Демонстрация plot_utils.jl"
    
    use_light_theme()
    
    # Пример 1: Линейный график
    @info "Пример 1: Линейный график"
    x = range(0, 4π, length=200)
    y1 = sin.(x)
    y2 = cos.(x)
    p1 = quick_plot(x, y1, title="Синус", label="sin(x)", linewidth=2)
    quick_plot!(p1, x, y2, label="cos(x)")
    save_plot(p1, filename="demo_line.png", theme=:light)
    
    # Пример 2: Scatter
    @info "Пример 2: Scatter plot"
    x_rand = randn(100)
    y_rand = 2 .* x_rand .+ randn(100)
    p2 = quick_scatter(x_rand, y_rand, 
                       title="Корреляция",
                       label="Данные",
                       markerstrokewidth=0.5)
    save_plot(p2, filename="demo_scatter.png", theme=:light)
    
    # Пример 3: Гистограмма
    @info "Пример 3: Гистограмма"
    data = randn(1000)
    p3 = quick_histogram(data, title="Распределение", label="N(0,1)")
    save_plot(p3, filename="demo_hist.png", theme=:light)
    
    # Пример 4: Временной ряд
    @info "Пример 4: Временной ряд"
    dates = Date(2020,1,1):Day(1):Date(2020,12,31)
    values = cumsum(randn(length(dates)))
    p4 = plot_timeseries(dates, values, title="Временной ряд")
    save_plot(p4, filename="demo_timeseries.png", theme=:light)
    
    # Пример 5: Панель
    @info "Пример 5: Панель графиков"
    p5 = quick_panel([p1, p2, p3, p4], layout=(2, 2), size=(1600, 1200))
    save_plot(p5, filename="demo_panel.png", theme=:light)
    
    # Пример 6: Доверительный интервал
    @info "Пример 6: Доверительный интервал"
    x_ci = 1:50
    y_ci = cumsum(randn(50))
    ci = 2 .* std(y_ci) ./ sqrt.(x_ci)
    p6 = plot_with_confidence(x_ci, y_ci, y_ci .- ci, y_ci .+ ci,
                              title="Модель с CI",
                              label="Предсказание")
    save_plot(p6, filename="demo_ci.png", theme=:light)
    
    @info "Демо завершено! Файлы сохранены в текущей директории"
    
    return nothing
end

# ──────────────────────────────────────────────────────────────────────────────
# ЭКСПОРТ
# ──────────────────────────────────────────────────────────────────────────────
#
# Доступные функции после include("plot_utils.jl"):
#
# Темы:
#   use_nature_theme(), use_light_theme()
#   apply_theme(theme)
#
# Бэкенды:
#   use_backend(:gr), use_backend(:plotlyjs)
#
# Быстрые графики:
#   quick_plot(), quick_plot!(), quick_scatter()
#   quick_bar(), quick_histogram(), quick_boxplot()
#
# Статистические:
#   plot_with_confidence(), plot_residuals()
#   qqplot(), plot_correlation_matrix()
#
# Панели:
#   create_dashboard(), add_plot!()
#   quick_panel()
#
# Сохранение:
#   save_plot(), save_panel()
#   save_interactive()
#
# Специализированные:
#   plot_timeseries(), plot_multi_timeseries()
#   plot_comparison(), plot_error_bars()
#
# Утилиты:
#   demo_plots()
#
# ──────────────────────────────────────────────────────────────────────────────

# Автоматически применяем тему при загрузке
use_nature_theme()
@info "plot_utils.jl загружен (Plots.jl + GR/PlotlyJS)"
