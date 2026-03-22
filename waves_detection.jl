using CSV
using DataFrames

cases = CSV.read("cases_with_variants.csv", DataFrame)

if :date in names(cases)
        cases[!, :date] = Date.(cases[!, :date])
end

using Plots
using Statistics
using StatsPlots
using Measures


# Начните с безопасного минимума для GR
Plots.default(
    size      = (1600, 900),    # ← не гигантский
    dpi       = 30,           # ← умеренный
    # ─── Шрифт ─────────────────────────────────────────────────────────
    # Helvetica / Arial — стандарт большинства топ-журналов
    fontfamily      = "Helvetica",   # Helvetica может быть недоступен, Arial — хороший аналог
    titlefontsize   = 18,
    guidefontsize   = 16,         # подписи осей
    tickfontsize    = 14,
    legendfontsize  = 12,
    annotationfontsize = 12,

    # ─── Линии ─────────────────────────────────────────────────────────
    linewidth           = 3.5,
    thickness_scaling   = 1.0,    # не масштабировать поверх явных значений
    markerstrokewidth   = 1.5,
    markersize          = 8,

    # ─── Оси и сетка ───────────────────────────────────────────────────
    grid            = true,
    gridalpha       = 0.2,
    gridlinewidth   = 0.8,
    gridstyle       = :solid,
    minorgrid       = true,
    framestyle      = :box,       # рамка со всех сторон — стандарт для Science/Nature
    tick_direction  = :in,        # тики внутрь

    # ─── Цвета ─────────────────────────────────────────────────────────
    # Wong 2011 — colorblind-safe, принят как стандарт в научной визуализации
    palette         = [
        RGB(0/255,  114/255, 178/255),   # синий
        RGB(230/255, 159/255,   0/255),   # жёлтый
        RGB(  0/255, 158/255, 115/255),   # зелёный
        RGB(213/255,  94/255,   0/255),   # оранжевый
        RGB( 86/255, 180/255, 233/255),   # голубой
        RGB(204/255, 121/255, 167/255),   # лиловый
        RGB(  0/255,   0/255,   0/255),   # чёрный
    ],
    background_color        = :white,
    background_color_legend = :white,
    foreground_color        = :black,

    # ─── Отступы ───────────────────────────────────────────────────────
    margin          = 8mm,
    left_margin     = 12mm,       # место для ylabel
    bottom_margin   = 10mm,       # место для xlabel
    
    # ─── Легенда ───────────────────────────────────────────────────────
    legend          = :topright,  
)


# Plots.default()
gr()

println("Cases data loaded successfully.",
    "Number of records: ", nrow(cases),
    "Columns: ", names(cases),
    "Date range: ", minimum(cases.date), " to ", maximum(cases.date)
)

p = Plots.plot(
    cases.date, cases[!, :Россия],   # ← позиционные аргументы
    label   = "Cases",
    xlabel  = "Date",
    ylabel  = "Number of Cases",
    title   = "COVID-19 Cases Over Time in Russia"
)

savefig(p, "cases_russia.png")
display(p)

using DataFrames, Dates

function rolling_mean(arr, window_size)
    a  = Float64.(arr)
    cs = cumsum(a)
    n  = length(cs)
    result = Vector{Float64}(undef, n)
    for i in 1:n
        result[i] = i <= window_size ?
            cs[i] / i :
            (cs[i] - cs[i - window_size]) / window_size
    end
    return result
end

function find_wave_minima(smoothed; 
        min_prominence = 0.15,   # минимум должен быть ниже X% от макс. пика
        min_distance   = 30)     # минимальное расстояние между минимумами (дней)
    
    n      = length(smoothed)
    global_max = maximum(smoothed)
    threshold  = global_max * min_prominence
    
    minima = Int[]
    i = 2
    while i < n
        if smoothed[i] < smoothed[i-1] && smoothed[i] < smoothed[i+1]
            # проверка prominence
            if smoothed[i] < threshold
                # проверка min_distance от предыдущего минимума
                if isempty(minima) || (i - last(minima)) >= min_distance
                    push!(minima, i)
                elseif smoothed[i] < smoothed[last(minima)]
                    # ближе чем min_distance, но глубже — заменяем
                    minima[end] = i
                end
            end
        end
        i += 1
    end
    return minima
end

function assign_waves(cases::DataFrame, country::Symbol;
        window    = 21,
        min_prominence = 0.15,
        min_distance   = 30)
    
    smoothed = rolling_mean(cases[!, country], window)
    minima   = find_wave_minima(smoothed; 
                    min_prominence, min_distance)
    
    n           = nrow(cases)
    wave_col    = zeros(Int, n)
    boundaries  = [1; minima; n]   # границы: начало, минимумы, конец
    
    for w in 1:length(boundaries)-1
        wave_col[boundaries[w]:boundaries[w+1]] .= w
    end
    
    col_name = Symbol(string(country) * "_волна")
    cases[!, col_name] = wave_col
    
    return cases, smoothed, minima
end

countries = [:Россия, :США, :Великобритания, :Германия, :Индия, Symbol("Южная Корея"), :Бразилия]

smoothed_all = Dict{Symbol, Vector{Float64}}()
minima_all   = Dict{Symbol, Vector{Int}}()

for c in countries
    global cases
    cases, sm, mn = assign_waves(cases, c; 
                        window         = 23,
                        min_prominence = 0.18                        ,
                        min_distance   = 31)
    smoothed_all[c] = sm
    minima_all[c]   = mn
    println("$c: волн найдено = ", maximum(cases[!, Symbol(string(c)*"_волна")]))
end

first(cases, 25) |> println

using Plots
# Plots.default()  # сброс агрессивных настроек
gr()

function plot_waves_gr(cases::DataFrame, country::Symbol,
                       smoothed_all, minima_all)

    smoothed = smoothed_all[country]
    minima   = minima_all[country]
    raw      = Float64.(cases[!, country])
    dates    = cases.date
    wave_col = cases[!, Symbol(string(country) * "_волна")]
    n_waves  = maximum(wave_col)

    wave_colors = [
        RGBA(0/255,  114/255, 178/255, 0.15),
        RGBA(230/255, 159/255,  0/255, 0.15),
        RGBA(  0/255, 158/255, 115/255, 0.15),
        RGBA(213/255,  94/255,   0/255, 0.15),
        RGBA( 86/255, 180/255, 233/255, 0.15),
        RGBA(204/255, 121/255, 167/255, 0.15),
        RGBA(150/255, 150/255, 150/255, 0.15),
    ]
    line_colors = [
        RGB(0/255,  114/255, 178/255),
        RGB(230/255, 159/255,  0/255),
        RGB(  0/255, 158/255, 115/255),
        RGB(213/255,  94/255,   0/255),
        RGB( 86/255, 180/255, 233/255),
        RGB(204/255, 121/255, 167/255),
        RGB(100/255, 100/255, 100/255),
    ]

    boundaries = [1; minima; length(dates)]
    ymax = maximum(raw) * 1.1

    # ── базовый график ────────────────────────────────────────────────
    p = Plots.plot(dates, raw;
        label         = "Исходные данные",
        color         = RGBA(0.5, 0.5, 0.5, 0.4),
        linewidth     = 1.0,
        size          = (1200, 600),
        dpi           = 150,
        xlabel        = "Дата",
        ylabel        = "Случаев на 1М",
        title         = "COVID-19: $(string(country)) — волны",
        xrotation     = 45,
        legend        = :topright,
        grid          = true,
        gridalpha     = 0.3,
        bottom_margin = 10Plots.mm,
        left_margin   = 8Plots.mm,
    )

    # ── зоны волн через fill! между двумя горизонталями ───────────────
    for w in 1:n_waves
        i1 = boundaries[w]
        i2 = boundaries[w+1]
        c  = wave_colors[mod1(w, length(wave_colors))]

        # заполняем зону прямоугольником через plot с ribbon
        xs = [dates[i1], dates[i2]]
        Plots.plot!(p, xs, [ymax/2, ymax/2];
            ribbon    = ymax/2,       # вверх и вниз от центра = весь диапазон
            fillcolor = c,
            fillalpha = 0.15,
            linewidth = 0,
            linealpha = 0,
            label     = false,
        )
    end

    # ── сглаженная кривая ─────────────────────────────────────────────
    Plots.plot!(p, dates, smoothed;
        label     = "Сглаженная (21 день)",
        color     = RGB(0.8, 0.1, 0.1),
        linewidth = 2.5,
    )

    # ── вертикальные линии границ ─────────────────────────────────────
    for m in minima
        vline!(p, [dates[m]];
            color     = RGBA(0, 0, 0, 0.3),
            linewidth = 1.0,
            linestyle = :dash,
            label     = false,
        )
    end

    # ── точки минимумов ───────────────────────────────────────────────
    if !isempty(minima)
        Plots.scatter!(p, dates[minima], smoothed[minima];
            color       = :black,
            markersize  = 6,
            markershape = :dtriangle,
            label       = "Границы волн",
        )
    end

    # ── номера волн ───────────────────────────────────────────────────
    for w in 1:n_waves
        i1  = boundaries[w]
        i2  = boundaries[w+1]
        mid = dates[div(i1 + i2, 2)]
        val = maximum(smoothed[i1:i2]) * 0.85
        Plots.annotate!(p, mid, val,
            Plots.text("Волна $w", 9, :center,
                line_colors[mod1(w, length(line_colors))])
        )
    end

    return p
end
# ── Строим для всех стран ─────────────────────────────────────────────
for c in countries
    p = plot_waves_gr(cases, c, smoothed_all, minima_all)
    savefig(p, "waves_$(string(c)).png")
    println("$(string(c)) сохранён")
    display(p)
end