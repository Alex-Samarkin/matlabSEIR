using DataFrames

variants = DataFrame(
    strain = ["Wuhan", "Alpha", "Delta", "Omicron BA.1", "Omicron BA.2", 
              "Omicron BA.5", "Omicron XBB", "Omicron JN.1"],
    R0_min = [2.5, 4.0, 5.0, 8.0, 9.0, 10.0, 12.0, 15.0],
    R0_max = [3.5, 6.0, 8.0, 10.0, 12.0, 15.0, 18.0, 20.0],
    incubation = [5.2, 4.8, 4.5, 3.2, 3.0, 2.8, 2.5, 2.3],
    infectious = [10.6, 8.4, 6.75, 5.2, 5.0, 4.4, 3.5, 3.15],
    CFR = [0.02, 0.02, 0.015, 0.003, 0.0025, 0.002, 0.001, 0.001],
    dominance_start = Date.(["2020-01-01", "2020-10-01", "2021-06-01", 
                            "2021-12-01", "2022-02-01", "2022-07-01", 
                            "2022-11-01", "2023-12-01"]),
    dominance_end = Date.(["2020-06-01", "2021-03-01", "2022-01-01", 
                          "2022-02-01", "2022-04-01", "2022-10-01", 
                          "2023-03-01", "2024-03-01"])
)

variants[!, :duration] = Dates.value.(variants.dominance_end) - Dates.value.(variants.dominance_start)

CSV.write("covid_variants_seird.csv", variants)

using DataFrames
using Dates
using Plots

gr()

# variants = DataFrame(
#    strain = ["Wuhan", "Alpha", "Delta", "Omicron BA.1", "Omicron BA.2", 
#              "Omicron BA.5", "Omicron XBB", "Omicron JN.1"],
#    start_date = Date.(["2020-01-01", "2020-10-01", "2021-06-01", "2021-12-01", 
#                        "2022-02-01", "2022-07-01", "2022-11-01", "2023-12-01"]),
#    end_date = Date.(["2020-06-01", "2021-03-01", "2022-01-01", "2022-02-01", 
#                      "2022-04-01", "2022-10-01", "2023-03-01", "2024-03-01"])
# )

p = plot(
    title = "Доминирование штаммов COVID-19",
    xlabel = "Дата",
    ylabel = "Штамм",
    legend = false,
    size = (1400, 600),
    dpi = 300,
    xlims = (Dates.value(Date(2020,1,1)), Dates.value(Date(2024,4,1)))
)

for (i, row) in enumerate(eachrow(variants))
    x1 = Dates.value(row.dominance_start)
    x2 = Dates.value(row.dominance_end)
    y = i
    
    plot!(p, [x1, x2], [y, y], 
          fillrange = [y-0.3, y-0.3], 
          fillalpha = 0.7,
          linecolor = :blue,
          linewidth = 0)
    
    annotate!(x1, y, text(row.strain, 8, :left))
end
display(p)
savefig(p, "covid_strain_timeline.png")

# Выбираем показатели для радарной диаграммы
metrics = [:R0_min, :R0_max, :incubation, :infectious, :CFR]
metric_labels = ["R0 min", "R0 max", "Incubation", "Infectious", "CFR"]

# Нормировка min-max по столбцам: 0...1
function normalize_minmax(x)
    xmin, xmax = minimum(x), maximum(x)
    if xmax == xmin
        return fill(0.5, length(x))
    end
    return (x .- xmin) ./ (xmax - xmin)
end

norm = DataFrame()
norm.strain = variants.strain

for m in metrics
    norm[!, m] = normalize_minmax(variants[!, m])
end

# Подготовка данных для radar
theta = vcat(metric_labels, metric_labels[1])

using Plots
using StatsPlots
gr()
# Чтобы график был читаемым, делаем отдельный радар для каждого штамма
plots = Plots.Plot[]
palette = Plots.palette(:tab10, nrow(norm))

for i in 1:nrow(norm)
    vals = [norm[i, m] for m in metrics]
    vals = vcat(vals, vals[1])

    p = plot(
        theta, vals,
        proj = :polar,
        seriestype = :path,
        linewidth = 2.5,
        marker = :circle,
        markersize = 4,
        label = norm.strain[i],
        color = palette[i],
        ylim = (0, 1),
        yticks = 0:0.2:1.0,
        grid = true,
        legend = false,
        title = norm.strain[i],
        size = (500, 500)
    )
    push!(plots, p)
end

# Компоновка в сетку
plot(plots..., layout = (2, 4), size = (1600, 800), margin = 5Plots.mm)

# Если нужен один общий график в файл:
savefig("radar_variants.png")

using DataFrames
using Dates
using StatsPlots


# 2) Все штаммы на одном radar-графике
p_all = plot(
    proj = :polar,
    title = "All variants on one radar chart",
    size = (900, 900),
    legend = :outerright,
    grid = true,
    yticks = 0:0.2:1.0,
    ylim = (0, 1)
)

for i in 1:nrow(norm)
    vals = [norm[i, m] for m in metrics]
    vals = vcat(vals, vals[1])

    plot!(
        p_all,
        theta, vals,
        linewidth = 2.2,
        marker = :circle,
        markersize = 3.5,
        label = norm.strain[i],
        color = palette[i]
    )
end

savefig(p_all, "radar_all_variants.png")
display(p_all)

using CSV
using DataFrames
using Dates
using Plots

# ---------- Данные ----------
cases = CSV.read("covid_daily_new_cases_smoothed.csv", DataFrame)

cases.date = Date.(cases.date)

# Таблица штаммов и периодов доминирования
variants = DataFrame(
    strain = ["Wuhan", "Alpha", "Delta", "Omicron BA.1", "Omicron BA.2",
              "Omicron BA.5", "Omicron XBB", "Omicron JN.1"],
    dominance_start = Date.(["2020-01-01", "2020-10-01", "2021-06-01",
                             "2021-12-01", "2022-02-01", "2022-07-01",
                             "2022-11-01", "2023-12-01"]),
    dominance_end = Date.(["2020-06-01", "2021-03-01", "2022-01-01",
                           "2022-02-01", "2022-04-01", "2022-10-01",
                           "2023-03-01", "2024-03-01"])
)

countries = names(cases)[2:end]

# Цвета для штаммов
strain_colors = Dict(
    "Wuhan" => :gray30,
    "Alpha" => :blue,
    "Delta" => :red,
    "Omicron BA.1" => :orange,
    "Omicron BA.2" => :green,
    "Omicron BA.5" => :purple,
    "Omicron XBB" => :brown,
    "Omicron JN.1" => :pink
)

# ---------- Функция построения ----------
function plot_country_with_variants(df::DataFrame, country::Symbol, variants::DataFrame)
    p = plot(
        df.date,
        df[!, country],
        lw = 2,
        color = :black,
        label = "COVID cases",
        xlabel = "Date",
        ylabel = "Daily new cases (smoothed)",
        title = String(country),
        legend = :topright,
        grid = true,
        size = (1200, 350)
    )

    ymax = maximum(skipmissing(df[!, country]))
    if !isfinite(ymax) || ymax <= 0
        ymax = 1.0
    end

    # Полосы доминирования штаммов
    for i in 1:nrow(variants)
        s = variants.dominance_start[i]
        e = variants.dominance_end[i]
        strain = variants.strain[i]
        c = get(strain_colors, strain, :steelblue)
        vspan!(p, [s, e], alpha = 0.12, color = c, label = strain == "Wuhan" ? "Variant period" : "")
    end

    return p
end

# ---------- Построение по всем странам ----------
plots_list = Plots.Plot[]
for c in countries
    push!(plots_list, plot_country_with_variants(cases, Symbol(c), variants))
end

for c in countries
    display(plot_country_with_variants(cases, Symbol(c), variants))
end


p_all = plot(plots_list..., layout = (length(countries), 1), size = (1200, 350 * length(countries)))
savefig(p_all, "covid_cases_with_variant_periods.png")
display(p_all)

function mean_variant_row(df, idxs)
    r0min = mean(df.R0_min[idxs])
    r0max = mean(df.R0_max[idxs])
    inc   = mean(df.incubation[idxs])
    inf   = mean(df.infectious[idxs])
    cfr   = mean(df.CFR[idxs])
    return r0min, r0max, (r0min + r0max) / 2, inc, inf, cfr
end

function values_for_date(d::Date, v::DataFrame)
    active = findall(i -> v.dominance_start[i] <= d <= v.dominance_end[i], 1:nrow(v))

    if length(active) == 1
        i = active[1]
        r0min, r0max, r0, inc, inf, cfr = mean_variant_row(v, [i])
        return (
            strain = String(v.strain[i]),
            variant_rule = "single:" * String(v.strain[i]),
            R0_min = r0min, R0_max = r0max, R0 = r0,
            incubation = inc, infectious = inf, CFR = cfr
        )
    elseif length(active) > 1
        names = String.(v.strain[active])
        r0min, r0max, r0, inc, inf, cfr = mean_variant_row(v, active)
        return (
            strain = join(names, "+"),
            variant_rule = "overlap:" * join(names, "+"),
            R0_min = r0min, R0_max = r0max, R0 = r0,
            incubation = inc, infectious = inf, CFR = cfr
        )
    end

    left = findall(i -> v.dominance_end[i] < d, 1:nrow(v))
    right = findall(i -> v.dominance_start[i] > d, 1:nrow(v))

    if !isempty(left) && !isempty(right)
        li = maximum(left)
        ri = minimum(right)
        names = [String(v.strain[li]), String(v.strain[ri])]
        r0min, r0max, r0, inc, inf, cfr = mean_variant_row(v, [li, ri])
        return (
            strain = join(names, "+"),
            variant_rule = "interpolate:" * join(names, "+"),
            R0_min = r0min, R0_max = r0max, R0 = r0,
            incubation = inc, infectious = inf, CFR = cfr
        )
    elseif !isempty(left)
        li = maximum(left)
        s = String(v.strain[li]) * "+?"
        r0min, r0max, r0, inc, inf, cfr = mean_variant_row(v, [li])
        return (
            strain = s,
            variant_rule = "extend_left:" * s,
            R0_min = r0min, R0_max = r0max, R0 = r0,
            incubation = inc, infectious = inf, CFR = cfr
        )
    else
        ri = minimum(right)
        s = String(v.strain[ri])
        r0min, r0max, r0, inc, inf, cfr = mean_variant_row(v, [ri])
        return (
            strain = s,
            variant_rule = "right_only:" * s,
            R0_min = r0min, R0_max = r0max, R0 = r0,
            incubation = inc, infectious = inf, CFR = cfr
        )
    end
end

variants = DataFrame(
    strain = ["Wuhan", "Alpha", "Delta", "Omicron BA.1", "Omicron BA.2",
              "Omicron BA.5", "Omicron XBB", "Omicron JN.1"],
    R0_min = [2.5, 4.0, 5.0, 8.0, 9.0, 10.0, 12.0, 15.0],
    R0_max = [3.5, 6.0, 8.0, 10.0, 12.0, 15.0, 18.0, 20.0],
    incubation = [5.2, 4.8, 4.5, 3.2, 3.0, 2.8, 2.5, 2.3],
    infectious = [10.6, 8.4, 6.75, 5.2, 5.0, 4.4, 3.5, 3.15],
    CFR = [0.02, 0.02, 0.015, 0.003, 0.0025, 0.002, 0.001, 0.001],
    dominance_start = Date.(["2020-01-01", "2020-10-01", "2021-06-01",
                             "2021-12-01", "2022-02-01", "2022-07-01",
                             "2022-11-01", "2023-12-01"]),
    dominance_end = Date.(["2020-06-01", "2021-03-01", "2022-01-01",
                           "2022-02-01", "2022-04-01", "2022-10-01",
                           "2023-03-01", "2024-03-01"])
)

cases.strain = Vector{String}(undef, nrow(cases))
cases.variant_rule = Vector{String}(undef, nrow(cases))
cases.R0_min = Vector{Float64}(undef, nrow(cases))
cases.R0_max = Vector{Float64}(undef, nrow(cases))
cases.R0 = Vector{Float64}(undef, nrow(cases))
cases.incubation = Vector{Float64}(undef, nrow(cases))
cases.infectious = Vector{Float64}(undef, nrow(cases))
cases.CFR = Vector{Float64}(undef, nrow(cases))

for i in 1:nrow(cases)
    r = values_for_date(cases.date[i], variants)
    cases.strain[i] = r.strain
    cases.variant_rule[i] = r.variant_rule
    cases.R0_min[i] = r.R0_min
    cases.R0_max[i] = r.R0_max
    cases.R0[i] = r.R0
    cases.incubation[i] = r.incubation
    cases.infectious[i] = r.infectious
    cases.CFR[i] = r.CFR
end

CSV.write("cases_with_variants.csv", cases)