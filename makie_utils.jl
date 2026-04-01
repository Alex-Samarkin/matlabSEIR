# ════════════════════════════════════════════════════════════════════════════════
# makie_utils.jl — Унифицированные утилиты для построения графиков (Makie.jl)
# ════════════════════════════════════════════════════════════════════════════════
#
# Назначение:
#   Высококачественные графики для научных публикаций с использованием Makie.jl
#   Поддержка CairoMakie (статичные PNG/SVG/PDF) и GLMakie (интерактивные)
#
# Преимущества Makie:
#   - Векторная графика высокого качества
#   - Быстрая отрисовка больших данных
#   - Современный API
#   - Отличная типографика
#
# Использование:
#   include("makie_utils.jl")
#   fig = quick_plot(x, y)
#   save_plot(fig, "output.png")  # или "output.svg"
#
# ════════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# 1. ИМПОРТ БИБЛИОТЕК
# ──────────────────────────────────────────────────────────────────────────────

using CairoMakie   # Статичные изображения (PNG, SVG, PDF)
# GLMakie загружается опционально при необходимости
using Statistics
using Dates
using Printf
using Colors: RGB

# ──────────────────────────────────────────────────────────────────────────────
# 2. НАСТРОЙКИ И ТЕМЫ
# ──────────────────────────────────────────────────────────────────────────────

"""
    MakieTheme

Структура с параметрами темы для Makie
"""
Base.@kwdef struct MakieTheme
    # Размеры (в пунктах, 1 pt = 1/72 inch)
    width::Float64 = 600      # ~8.3 дюйма (A4 ширина)
    height::Float64 = 450     # ~6.25 дюйма
    
    # DPI для растровых изображений
    dpi::Int = 300
    
    # Шрифты
    font::String = "Arial"
    titlefontsize::Float64 = 20
    labelfontsize::Float64 = 16
    tickfontsize::Float64 = 14
    legendfontsize::Float64 = 14
    
    # Линии
    linewidth::Float64 = 2.5
    markersize::Float64 = 8
    
    # Цвета (Wong 2011 colorblind-safe)
    palette::Vector{RGB} = [
        RGB(0.0,  114/255, 178/255),   # синий
        RGB(230/255, 159/255,   0.0),   # жёлтый
        RGB(  0.0, 158/255, 115/255),   # зелёный
        RGB(213/255,  94/255,   0.0),   # оранжевый
        RGB( 86/255, 180/255, 233/255), # голубой
        RGB(204/255, 121/255, 167/255), # лиловый
        RGB(  0.0,   0.0,   0.0),       # чёрный
    ]

    # Фон
    backgroundcolor::Makie.RGBf = Makie.RGBf(1.0, 1.0, 1.0)
    figure_padding::Float64 = 15
end

"""
    PublicationTheme

Тема для публикаций (большие размеры, шрифты)
"""
Base.@kwdef struct PublicationTheme
    width::Float64 = 900      # ~12.5 дюйма
    height::Float64 = 600     # ~8.3 дюйма
    dpi::Int = 600
    font::String = "Arial"
    titlefontsize::Float64 = 28
    labelfontsize::Float64 = 24
    tickfontsize::Float64 = 20
    legendfontsize::Float64 = 20
    linewidth::Float64 = 3.0
    markersize::Float64 = 10
    palette::Vector{RGB} = [
        RGB(0.0,  114/255, 178/255),
        RGB(230/255, 159/255,   0.0),
        RGB(  0.0, 158/255, 115/255),
        RGB(213/255,  94/255,   0.0),
        RGB( 86/255, 180/255, 233/255),
        RGB(204/255, 121/255, 167/255),
        RGB(  0.0,   0.0,   0.0),
    ]
    backgroundcolor::Makie.RGBf = Makie.RGBf(1.0, 1.0, 1.0)
    figure_padding::Float64 = 20
end

# Глобальная тема по умолчанию
const DEFAULT_MAKIE_THEME = MakieTheme()
const PUBLICATION_MAKIE_THEME = PublicationTheme()

# ──────────────────────────────────────────────────────────────────────────────
# 3. ПРИМЕНЕНИЕ ТЕМ
# ──────────────────────────────────────────────────────────────────────────────

"""
    apply_makie_theme!(theme::MakieTheme)

Применяет тему к Makie глобально
"""
function apply_makie_theme!(theme::MakieTheme)
    CairoMakie.set_theme!(
        fontsize = theme.tickfontsize,
        font = theme.font,
        linewidth = theme.linewidth,
        markersize = theme.markersize,
        figure = (
            size = (theme.width, theme.height),
            backgroundcolor = theme.backgroundcolor,
        ),
        Axis = (
            xlabelsize = theme.labelfontsize,
            ylabelsize = theme.labelfontsize,
            xticklabelsize = theme.tickfontsize,
            yticklabelsize = theme.tickfontsize,
            titlesize = theme.titlefontsize,
            legendtextsize = theme.legendfontsize,
            spinewidth = 1.5,
            gridvisible = true,
            gridalpha = 0.25,
        ),
        Lines = (linewidth = theme.linewidth,),
        Scatter = (strokewidth = 1.5,),
    )
    @info "Применена тема Makie: $(theme.width)x$(theme.height) @ $(theme.dpi)dpi"
    return nothing
end

"""
    apply_makie_theme!(theme::PublicationTheme)

Применяет тему для публикаций
"""
function apply_makie_theme!(theme::PublicationTheme)
    CairoMakie.set_theme!(
        fontsize = theme.tickfontsize,
        font = theme.font,
        linewidth = theme.linewidth,
        markersize = theme.markersize,
        figure = (
            size = (theme.width, theme.height),
            backgroundcolor = theme.backgroundcolor,
        ),
        Axis = (
            xlabelsize = theme.labelfontsize,
            ylabelsize = theme.labelfontsize,
            xticklabelsize = theme.tickfontsize,
            yticklabelsize = theme.tickfontsize,
            titlesize = theme.titlefontsize,
            legendtextsize = theme.legendfontsize,
            spinewidth = 1.5,
            gridvisible = true,
            gridalpha = 0.25,
        ),
        Lines = (linewidth = theme.linewidth,),
        Scatter = (strokewidth = 1.5,),
    )
    @info "Применена тема Makie Publication: $(theme.width)x$(theme.height) @ $(theme.dpi)dpi"
    return nothing
end

"""
    use_makie_theme(theme::Symbol)

Быстрое переключение тем: :default, :publication, :light
"""
function use_makie_theme(theme::Symbol)
    if theme == :default
        apply_makie_theme!(DEFAULT_MAKIE_THEME)
    elseif theme == :publication
        apply_makie_theme!(PUBLICATION_MAKIE_THEME)
    elseif theme == :light
        # Облегчённая для отладки
        apply_makie_theme!(MakieTheme(width=400, height=300, dpi=150))
    else
        @warn "Неизвестная тема: $theme"
    end
    return nothing
end

# ──────────────────────────────────────────────────────────────────────────────
# 4. БЭКЕНДЫ
# ──────────────────────────────────────────────────────────────────────────────

"""
    use_makie_backend(backend::Symbol)

Переключает бэкенд Makie: :cairo (статичный), :gl (интерактивный)

Пример:
    use_makie_backend(:cairo)   # для PNG/SVG/PDF
    use_makie_backend(:gl)      # для интерактивного просмотра
"""
function use_makie_backend(backend::Symbol)
    if backend == :cairo
        # CairoMakie уже загружен
        @info "Бэкенд: CairoMakie (статичные изображения)"
    elseif backend == :gl
        try
            @eval using GLMakie
            GLMakie.activate!()
            @info "Бэкенд: GLMakie (интерактивный)"
        catch e
            @warn "GLMakie недоступен: $e. Используем CairoMakie. Установите: Pkg.add(\"GLMakie\")"
        end
    else
        @warn "Неизвестный бэкенд: $backend"
    end
    return nothing
end

# ──────────────────────────────────────────────────────────────────────────────
# 5. БЫСТРОЕ ПОСТРОЕНИЕ ГРАФИКОВ
# ──────────────────────────────────────────────────────────────────────────────

"""
    quick_plot(x, y; kwargs...)

Быстрое построение линейного графика с Makie

Аргументы:
  - `x`, `y`: данные
  - `kwargs`: параметры для lines!

Возвращает:
  Figure + Axis

Пример:
    x = range(0, 10, length=100)
    y = sin.(x)
    fig, ax = quick_plot(x, y, title="Синус")
"""
function quick_plot(x, y; kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1])
    
    lines!(ax, x, y; kwargs...)
    
    display(fig)
    return fig, ax
end

"""
    quick_plot!(ax, x, y; kwargs...)

Добавить линию на существующую ось
"""
function quick_plot!(ax::Axis, x, y; kwargs...)
    lines!(ax, x, y; kwargs...)
    return ax
end

"""
    quick_scatter(x, y; kwargs...)

Быстрое построение точечного графика
"""
function quick_scatter(x, y; kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1])
    
    scatter!(ax, x, y; kwargs...)
    
    display(fig)
    return fig, ax
end

"""
    quick_bar(values; labels=nothing, kwargs...)

Столбчатая диаграмма
"""
function quick_bar(values::AbstractVector; labels=nothing, kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1])
    
    if labels === nothing
        barplot!(ax, values; kwargs...)
    else
        barplot!(ax, labels, values; kwargs...)
    end
    
    display(fig)
    return fig, ax
end

"""
    quick_histogram(data; kwargs...)

Гистограмма
"""
function quick_histogram(data::AbstractVector; kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1])

    hist!(ax, data; kwargs...)

    display(fig)
    return fig, ax
end

"""
    quick_boxplot(data; labels=nothing, kwargs...)

Box plot
"""
function quick_boxplot(data::AbstractVector; labels=nothing, kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1])
    
    if labels === nothing
        boxplot!(ax, data; kwargs...)
    else
        boxplot!(ax, labels, data; kwargs...)
    end
    
    display(fig)
    return fig, ax
end

# ──────────────────────────────────────────────────────────────────────────────
# 6. СТАТИСТИЧЕСКИЕ ГРАФИКИ
# ──────────────────────────────────────────────────────────────────────────────

"""
    plot_with_band(x, y_mean, y_lower, y_upper; kwargs...)

График с закрашенной областью (доверительный интервал)

Пример:
    x = 1:100
    y = cumsum(randn(100))
    ci = 1.96 * std(y) / sqrt(length(y))
    fig, ax = plot_with_band(x, y, y - ci, y + ci)
"""
function plot_with_band(x, y_mean, y_lower, y_upper; kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1])
    
    # Линия среднего
    lines!(ax, x, y_mean; kwargs...)
    
    # Закрашенная область
    band!(ax, x, y_lower, y_upper; 
          color = (:lightblue, 0.3),
          label = nothing)
    
    display(fig)
    return fig, ax
end

"""
    plot_residuals_makie(y_true, y_pred; kwargs...)

График остатков модели (3 панели)
"""
function plot_residuals_makie(y_true::AbstractVector, y_pred::AbstractVector; kwargs...)
    residuals = y_true .- y_pred
    
    fig = Figure(size = (1200, 400))
    
    # Панель 1: residuals vs predicted
    ax1 = Axis(fig[1, 1], 
               title = "Остатки vs Предсказания",
               xlabel = "Предсказанные значения",
               ylabel = "Остатки")
    scatter!(ax1, y_pred, residuals)
    hlines!(ax1, [0], color = :red, linestyle = :dash)
    
    # Панель 2: гистограмма остатков
    ax2 = Axis(fig[1, 2],
               title = "Распределение остатков",
               xlabel = "Остатки",
               ylabel = "Частота")
    hist!(ax2, residuals)
    
    # Панель 3: QQ-plot
    ax3 = Axis(fig[1, 3],
               title = "QQ-plot",
               xlabel = "Теоретические квантили",
               ylabel = "Выборочные квантили")

    n = length(residuals)
    sorted_res = sort(residuals)
    normalized_res = (sorted_res .- mean(sorted_res)) ./ std(sorted_res)
    theoretical = [quantile(Normal(), (i - 0.5) / n) for i in 1:n]

    scatter!(ax3, theoretical, normalized_res)
    
    # Добавляем линию y=x
    min_val = min(minimum(theoretical), minimum(normalized_res))
    max_val = max(maximum(theoretical), maximum(normalized_res))
    lines!(ax3, [min_val, max_val], [min_val, max_val], 
           color = :red, linestyle = :dash)

    display(fig)
    return fig
end

"""
    qqplot_makie(data; kwargs...)

QQ-plot для проверки нормальности
"""
function qqplot_makie(data::AbstractVector; kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1],
              title = "QQ-plot",
              xlabel = "Теоретические квантили",
              ylabel = "Выборочные квантили")

    n = length(data)
    sorted_data = sort(data)
    normalized = (sorted_data .- mean(sorted_data)) ./ std(sorted_data)
    # Используем (i - 0.5) / n для квантилей
    theoretical = [quantile(Normal(), (i - 0.5) / n) for i in 1:n]

    scatter!(ax, theoretical, normalized; kwargs...)
    
    # Добавляем линию y=x вручную
    min_val = min(minimum(theoretical), minimum(normalized))
    max_val = max(maximum(theoretical), maximum(normalized))
    lines!(ax, [min_val, max_val], [min_val, max_val], 
           color = :red, linestyle = :dash)

    display(fig)
    return fig, ax
end

"""
    plot_correlation_matrix_makie(data; labels=nothing, kwargs...)

Heatmap корреляционной матрицы
"""
function plot_correlation_matrix_makie(data; labels=nothing, kwargs...)
    # Вычисляем корреляционную матрицу
    if typeof(data) <: AbstractMatrix
        corr_matrix = cor(data)
        if labels === nothing
            labels = ["Var $i" for i in 1:size(data, 2)]
        end
    else
        # DataFrame
        numeric_cols = [col for col in eachcol(data) if eltype(col) <: Real]
        corr_matrix = cor(hcat(numeric_cols...))
        labels = [name for (name, col) in zip(names(data), eachcol(data)) if eltype(col) <: Real]
    end
    
    n = length(labels)
    
    fig = Figure()
    ax = Axis(fig[1, 1],
              title = "Корреляционная матрица",
              xticklabelrotation = 45)
    
    # Heatmap
    heatmap!(ax, 1:n, 1:n, corr_matrix; colormap = :balance)
    
    # Подписи
    for i in 1:n, j in 1:n
        text!(ax, i, j, 
              text = @sprintf("%.2f", corr_matrix[j, i]),
              align = (:center, :center),
              fontsize = 10)
    end
    
    # Оси
    ax.xticks = (1:n, labels)
    ax.yticks = (1:n, labels)
    
    display(fig)
    return fig, ax
end

# ──────────────────────────────────────────────────────────────────────────────
# 7. ПАНЕЛИ И ДАШБОАРДЫ (FIGURE COMPOSITION)
# ──────────────────────────────────────────────────────────────────────────────

"""
    create_figure(; rows=1, cols=1, size=(800, 600), kwargs...)

Создаёт фигуру с сеткой осей

Аргументы:
  - `rows`, `cols`: размеры сетки
  - `size`: общий размер (width, height)
  - `kwargs`: параметры Figure

Пример:
    fig, axes = create_figure(rows=2, cols=2, size=(1000, 800))
    lines!(axes[1, 1], x1, y1)
    scatter!(axes[1, 2], x2, y2)
"""
function create_figure(; rows::Int=1, cols::Int=1, 
                       size::Tuple{Int,Int}=(800, 600),
                       kwargs...)
    fig = Figure(size=size; kwargs...)
    axes = [Axis(fig[i, j]) for i in 1:rows, j in 1:cols]
    
    return fig, axes
end

"""
    quick_panel_makie(plots_data; layout=:auto, size=(1200, 800), kwargs...)

Быстрое создание панели графиков

Аргументы:
  - `plots_data`: Vector of tuples (plot_function, data, kwargs)
    или Dict с именами панелей
  - `layout`: (rows, cols) или :auto
  - `size`: размер фигуры

Пример:
    # С функциями
    plots_data = [
        (quick_plot, (x1, y1), (title="График 1",)),
        (quick_scatter, (x2, y2), (title="График 2",)),
    ]
    fig = quick_panel_makie(plots_data, layout=(1, 2))
    
    # С готовыми осями
    fig, axes = create_figure(rows=2, cols=2)
    lines!(axes[1, 1], x, y1)
    scatter!(axes[1, 2], x, y2)
"""
function quick_panel_makie(plots_data::Vector; 
                           layout=:auto,
                           size::Tuple{Int,Int}=(1200, 800),
                           kwargs...)
    
    n = length(plots_data)
    
    # Авто-раскладка
    if layout === :auto || layout === nothing
        cols = ceil(Int, sqrt(n))
        rows = ceil(Int, n / cols)
    else
        rows, cols = layout
    end
    
    fig = Figure(size=size)
    
    for (i, item) in enumerate(plots_data)
        row = ceil(Int, i / cols)
        col = ((i - 1) % cols) + 1
        
        ax = Axis(fig[row, col])
        
        # Распаковываем данные
        if length(item) == 3
            plot_func, data, plot_kwargs = item
            plot_func(ax, data...; plot_kwargs...)
        elseif length(item) == 2
            plot_func, data = item
            plot_func(ax, data...)
        end
    end
    
    display(fig)
    return fig
end

"""
    add_colorbar!(fig, plot_object; position=:right, label="")

Добавляет цветовую шкалу к figure
"""
function add_colorbar!(fig::Figure, plot_object; position::Symbol=:right, label::String="")
    if position == :right
        Colorbar(fig[1, 2], plot_object, label=label)
    elseif position == :bottom
        Colorbar(fig[2, 1], plot_object, label=label, vertical=false)
    end
    return nothing
end

"""
    add_legend!(ax; position=:rt, kwargs...)

Добавляет легенду к оси
"""
function add_legend!(ax::Axis; position::Symbol=:rt, kwargs...)
    # position: :rt (right top), :rb, :lt, :lb, :ct, :cb
    Legend(ax, position; kwargs...)
    return ax
end

# ──────────────────────────────────────────────────────────────────────────────
# 8. СОХРАНЕНИЕ ГРАФИКОВ
# ──────────────────────────────────────────────────────────────────────────────

"""
    save_plot(fig; filename, format=:auto, kwargs...)

Сохраняет фигуру Makie в файл.

Аргументы:
  - `fig`: Figure объект
  - `filename`: имя файла
  - `format`: :png, :svg, :pdf, :eps, :auto
  - `kwargs`: параметры сохранения (dpi, px_per_unit, и т.д.)

Пример:
    save_plot(fig, filename="my_plot.png")
    save_plot(fig, filename="my_plot.svg")  # векторный!
    save_plot(fig, filename="my_plot.pdf", dpi=600)
"""
function save_plot(fig::Figure; filename::String, format::Symbol=:auto, kwargs...)
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
            format = :png
            filename = filename * ".png"
        end
    end
    
    # Параметры по умолчанию
    save_kwargs = merge(
        (dpi = 300,),
        kwargs
    )
    
    # Сохраняем
    save(filename, fig; save_kwargs...)
    @info "График сохранён: $filename (format=$format)"
    
    return filename
end

"""
    save_plot(fig, filename::String)

Упрощённая версия
"""
function save_plot(fig::Figure, filename::String)
    return save_plot(fig; filename=filename)
end

"""
    save_plot_series(figs, filenames)

Сохраняет серию фигур
"""
function save_plot_series(figs::Vector{<:Figure}, filenames::Vector{String})
    for (fig, fname) in zip(figs, filenames)
        save_plot(fig, filename=fname)
    end
    @info "Сохранено $(length(figs)) графиков"
    return nothing
end

# ──────────────────────────────────────────────────────────────────────────────
# 9. СПЕЦИАЛИЗИРОВАННЫЕ ГРАФИКИ
# ──────────────────────────────────────────────────────────────────────────────

"""
    plot_timeseries_makie(dates, values; kwargs...)

Временной ряд с датами
"""
function plot_timeseries_makie(dates::AbstractVector{<:Date}, 
                                values::AbstractVector; 
                                kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1],
              xlabel = "Дата",
              ylabel = "Значение",
              xticklabelrotation = 45)
    
    lines!(ax, dates, values; kwargs...)
    
    display(fig)
    return fig, ax
end

"""
    plot_multi_timeseries_makie(dates, data_dict; kwargs...)

Несколько временных рядов
"""
function plot_multi_timeseries_makie(dates::AbstractVector{<:Date},
                                      data_dict::Dict{String, <:AbstractVector};
                                      kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1],
              xlabel = "Дата",
              ylabel = "Значение",
              xticklabelrotation = 45)

    for (label, values) in data_dict
        lines!(ax, dates, values, label=label)
    end

    # Legend requires complex setup in newer Makie - skip for now
    # Legend(fig, ax, :rt)

    display(fig)
    return fig, ax
end

"""
    plot_comparison_makie(x, y1, y2; labels=("Series 1", "Series 2"), kwargs...)

Сравнение двух серий (2 панели: данные + разность)
"""
function plot_comparison_makie(x, y1::AbstractVector, y2::AbstractVector;
                                labels::Tuple{String,String}=("Series 1", "Series 2"),
                                kwargs...)
    fig = Figure(size=(800, 600))

    # Верхняя панель: данные
    ax1 = Axis(fig[1, 1],
               ylabel = "Значение",
               title = "Сравнение")
    lines!(ax1, x, y1, label=labels[1])
    lines!(ax1, x, y2, label=labels[2])
    # Legend - отключено из-за изменений в API Makie
    # Legend(ax1, :rt)

    # Нижняя панель: разность
    diff = y1 .- y2
    ax2 = Axis(fig[2, 1],
               xlabel = "X",
               ylabel = "Разность")
    lines!(ax2, x, diff, color=:green)
    hlines!(ax2, [0], color=:red, linestyle=:dash)

    # Связываем оси по X
    linkxaxes!(ax1, ax2)

    display(fig)
    return fig
end

"""
    plot_error_bars_makie(x, y, yerr; kwargs...)

График с error bars
"""
function plot_error_bars_makie(x::AbstractVector, 
                                y::AbstractVector, 
                                yerr::AbstractVector;
                                kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1])
    
    scatter!(ax, x, y; kwargs...)
    errorbars!(ax, x, y, yerr; direction=:y, whiskerwidth=10)
    
    display(fig)
    return fig, ax
end

"""
    plot_contour(x, y, z; kwargs...)

Контурный график (contour plot)
"""
function plot_contour(x::AbstractVector, y::AbstractVector, z::AbstractMatrix; kwargs...)
    fig = Figure()
    ax = Axis(fig[1, 1])
    
    contourf!(ax, x, y, z; colormap=:viridis)
    contour!(ax, x, y, z; color=:white, linewidth=1)
    
    display(fig)
    return fig, ax
end

"""
    plot_surface(x, y, z; kwargs...)

3D поверхность (требует GLMakie)
"""
function plot_surface(x::AbstractVector, y::AbstractVector, z::AbstractMatrix; kwargs...)
    use_makie_backend(:gl)
    
    fig = Figure()
    ax = LScene(fig[1, 1])
    
    surface!(ax, x, y, z; kwargs...)
    
    display(fig)
    return fig, ax
end

# ──────────────────────────────────────────────────────────────────────────────
# 10. АНИМАЦИИ
# ──────────────────────────────────────────────────────────────────────────────

"""
    create_animation(record_func; frames=30, filename="animation.mp4", fps=15)

Создаёт анимацию

Аргументы:
  - `record_func`: функция (frame) -> figure
  - `frames`: количество кадров
  - `filename`: имя выходного файла
  - `fps`: кадров в секунду

Пример:
    fig, ax = quick_plot(1:10, zeros(10))
    line = lines!(ax, 1:10, zeros(10))
    
    function animate(frame)
        line[1] = sin.(1:10 .+ frame/10)
        return fig
    end
    
    create_animation(animate, frames=60, filename="wave.mp4")
"""
function create_animation(record_func; frames::Int=30, 
                          filename::String="animation.mp4",
                          fps::Int=15)
    
    use_makie_backend(:gl)

    record(filename, 1:frames) do frame
        record_func(frame)
    end

    @info "Анимация сохранена: $filename ($frames кадров @ $(fps) fps)"
    return filename
end

# ──────────────────────────────────────────────────────────────────────────────
# 11. ДЕМО
# ──────────────────────────────────────────────────────────────────────────────

"""
    demo_makie_plots()

Демонстрация возможностей makie_utils.jl
"""
function demo_makie_plots()
    @info "Демонстрация makie_utils.jl"
    
    use_makie_theme(:light)
    
    # Пример 1: Линейный график
    @info "Пример 1: Линейный график"
    x = range(0, 4π, length=200)
    y1 = sin.(x)
    y2 = cos.(x)
    fig1, ax1 = quick_plot(x, y1, label="sin(x)")
    lines!(ax1, x, y2, label="cos(x)")
    Legend(ax1, :rt)
    save_plot(fig1, filename="makie_demo_line.png")
    
    # Пример 2: Scatter
    @info "Пример 2: Scatter"
    x_rand = randn(100)
    y_rand = 2 .* x_rand .+ randn(100)
    fig2, ax2 = quick_scatter(x_rand, y_rand, label="Данные")
    save_plot(fig2, filename="makie_demo_scatter.png")
    
    # Пример 3: Гистограмма
    @info "Пример 3: Гистограмма"
    data = randn(1000)
    fig3, ax3 = quick_histogram(data)
    save_plot(fig3, filename="makie_demo_hist.png")
    
    # Пример 4: Временной ряд
    @info "Пример 4: Временной ряд"
    dates = Date(2020,1,1):Day(1):Date(2020,12,31)
    values = cumsum(randn(length(dates)))
    fig4, ax4 = plot_timeseries_makie(dates, values)
    save_plot(fig4, filename="makie_demo_timeseries.png")
    
    # Пример 5: Панель
    @info "Пример 5: Панель"
    fig5, axes5 = create_figure(rows=2, cols=2, size=(1000, 800))
    lines!(axes5[1, 1], x, y1)
    scatter!(axes5[1, 2], x_rand, y_rand)
    hist!(axes5[2, 1], data)
    lines!(axes5[2, 2], dates, values)
    save_plot(fig5, filename="makie_demo_panel.png")
    
    # Пример 6: Доверительный интервал
    @info "Пример 6: Доверительный интервал"
    x_ci = 1:50
    y_ci = cumsum(randn(50))
    ci = 2 .* std(y_ci) ./ sqrt.(x_ci)
    fig6, ax6 = plot_with_band(x_ci, y_ci, y_ci .- ci, y_ci .+ ci)
    save_plot(fig6, filename="makie_demo_band.png")
    
    # Пример 7: SVG (векторный!)
    @info "Пример 7: Векторный SVG"
    save_plot(fig1, filename="makie_demo_line.svg")
    
    @info "Демо завершено! Файлы сохранены в текущей директории"
    
    return nothing
end

# ──────────────────────────────────────────────────────────────────────────────
# ЭКСПОРТ
# ──────────────────────────────────────────────────────────────────────────────
#
# Доступные функции после include("makie_utils.jl"):
#
# Темы:
#   use_makie_theme(:default), use_makie_theme(:publication)
#   set_theme!(theme)
#
# Бэкенды:
#   use_makie_backend(:cairo), use_makie_backend(:gl)
#
# Быстрые графики:
#   quick_plot(), quick_plot!(), quick_scatter()
#   quick_bar(), quick_histogram(), quick_boxplot()
#
# Статистические:
#   plot_with_band(), plot_residuals_makie()
#   qqplot_makie(), plot_correlation_matrix_makie()
#
# Панели:
#   create_figure(), quick_panel_makie()
#   add_colorbar!(), add_legend!()
#
# Сохранение:
#   save_plot(), save_plot_series()
#
# Специализированные:
#   plot_timeseries_makie(), plot_multi_timeseries_makie()
#   plot_comparison_makie(), plot_error_bars_makie()
#   plot_contour(), plot_surface()
#
# Анимации:
#   create_animation()
#
# Утилиты:
#   demo_makie_plots()
#
# ──────────────────────────────────────────────────────────────────────────────

# Применяем тему при загрузке
use_makie_theme(:default)
@info "makie_utils.jl загружен (CairoMakie + GLMakie)"
