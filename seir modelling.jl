using CSV
using DataFrames
using Dates
using Plots
using Statistics

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
gr();  # Используем бэкенд GR для лучшей производительности при сохранении графиков


cases = CSV.read("cases_with_waves.csv", DataFrame)

if :date in names(cases)
        cases[!, :date] = Date.(cases[!, :date])
end

println("Cases data loaded successfully.",
    "Number of records: ", nrow(cases),
    "Columns: ", names(cases),
    "Date range: ", minimum(cases.date), " to ", maximum(cases.date)
)

first(cases, 5) |> println

# ── Словарь: номер → (страна, колонка_волн) ──────────────────────────
country_dict = Dict(
    i => (country, Symbol(string(country) * "_волна"))
    for (i, country) in enumerate(countries)
)

# Просмотр словаря
for (i, (c, wc)) in sort(collect(country_dict))
    n_waves = maximum(cases[!, wc])
    println("$i => $c (колонка волн: $wc, волн найдено: $n_waves)")
end

# ── Отбор данных по номеру страны и номеру волны ─────────────────────
function select_wave(cases::DataFrame, 
                     country_dict, 
                     country_idx::Int, 
                     wave_num::Int) :: DataFrame

    @assert haskey(country_dict, country_idx) "Страна $country_idx не найдена в словаре"

    country, wave_col = country_dict[country_idx]

    @assert wave_col in propertynames(cases) "Колонка $wave_col не найдена — сначала запустите assign_waves()"

    max_wave = maximum(cases[!, wave_col])
    @assert 1 <= wave_num <= max_wave "Волна $wave_num не существует для $(string(country)) (всего волн: $max_wave)"

    # маска строк
    mask = cases[!, wave_col] .== wave_num

    # колонки: дата + страна + колонка волн + характеристики штамма
    strain_cols = [:strain, :variant_rule, :R0_min, :R0_max, 
                   :R0, :incubation, :infectious, :CFR]
    
    selected_cols = [:date, country, wave_col, strain_cols...]

    return cases[mask, selected_cols]
end

function plot_wave_detail(df::DataFrame, country::Symbol, wave_num::Int)

    dates  = df.date
    vals   = Float64.(df[!, country])
    r0     = Float64.(df.R0)
    ymax   = maximum(vals) * 1.15
    r0max  = maximum(r0)   * 1.15
    r0min  = minimum(r0)   * 0.85

    # ── цвета штаммов ─────────────────────────────────────────────────
    unique_strains = unique(df.strain)
    base_colors_fill = [
        RGBA(0/255,  114/255, 178/255, 0.20),
        RGBA(230/255, 159/255,  0/255, 0.20),
        RGBA(  0/255, 158/255, 115/255, 0.20),
        RGBA(213/255,  94/255,   0/255, 0.20),
        RGBA( 86/255, 180/255, 233/255, 0.20),
        RGBA(204/255, 121/255, 167/255, 0.20),
    ]
    base_colors_line = [
        RGB(0/255,  114/255, 178/255),
        RGB(230/255, 159/255,  0/255),
        RGB(  0/255, 158/255, 115/255),
        RGB(213/255,  94/255,   0/255),
        RGB( 86/255, 180/255, 233/255),
        RGB(204/255, 121/255, 167/255),
    ]
    strain_palette = Dict(
        s => base_colors_fill[mod1(i, 6)]
        for (i, s) in enumerate(unique_strains)
    )
    strain_line = Dict(
        s => base_colors_line[mod1(i, 6)]
        for (i, s) in enumerate(unique_strains)
    )

    # ── сегменты штаммов ──────────────────────────────────────────────
    strain_segments = Tuple{Int,Int,String}[]
    cur_strain = df.strain[1]
    seg_start  = 1
    for i in 2:nrow(df)
        if df.strain[i] != cur_strain
            push!(strain_segments, (seg_start, i-1, cur_strain))
            cur_strain = df.strain[i]
            seg_start  = i
        end
    end
    push!(strain_segments, (seg_start, nrow(df), cur_strain))

    # ── базовый график ────────────────────────────────────────────────
    p = Plots.plot(dates, vals;
        label         = "Заболевших на 1М",
        color         = RGB(0.8, 0.1, 0.1),
        linewidth     = 2.5,
        size          = (1300, 650),
        dpi           = 150,
        xlabel        = "Дата",
        ylabel        = "Заболевших на 1М",
        title         = "COVID-19: $(string(country)), волна $wave_num",
        xrotation     = 45,
        legend        = :topleft,
        grid          = true,
        gridalpha     = 0.3,
        ylims         = (0, ymax),
        bottom_margin = 10Plots.mm,
        left_margin   = 10Plots.mm,
        right_margin  = 20Plots.mm,
    )

    # ── зоны штаммов ──────────────────────────────────────────────────
    labeled_strains = Set{String}()
    for (i1, i2, s) in strain_segments
        c      = strain_palette[s]
        lc     = strain_line[s]
        lbl    = s in labeled_strains ? false : s
        push!(labeled_strains, s)

        xs = [dates[i1], dates[i2]]
        Plots.plot!(p, xs, [ymax/2, ymax/2];
            ribbon    = ymax/2,
            fillcolor = c,
            fillalpha = 0.20,
            linewidth = 0,
            linealpha = 0,
            label     = lbl,
        )

        mid = dates[div(i1 + i2, 2)]
        Plots.annotate!(p, mid, ymax * 0.97,
            Plots.text(s, 8, :center, lc))
    end

    # ── R0 — правая ось ───────────────────────────────────────────────
    p2 = Plots.twinx(p)
    Plots.plot!(p2, dates, r0;
        label     = "R0",
        color     = RGB(0.1, 0.4, 0.8),
        linewidth = 2.0,
        linestyle = :dash,
        ylabel    = "R0",
        ylims     = (r0min, r0max),
        legend    = :topright,
        grid      = false,
    )

    return p
end

# Пример: Россия, волна 2
df = select_wave(cases, country_dict, 1, 2)
first(df, 10) |> println
p  = plot_wave_detail(df, :Россия, 2)
savefig(p, "wave_detail_russia_2.png")