using CSV
using DataFrames
using Dates
using Downloads
using Interpolations;

function load_covid_daily(;
    url::String = "https://srhdpeuwpubsa.blob.core.windows.net/whdh/COVID/WHO-COVID-19-global-daily-data.csv",
    outfile::String = "covid_all_daily.csv",
    force_download::Bool = false
)
    if isfile(outfile) && !force_download
        covid_all = CSV.read(outfile, DataFrame)
        return covid_all
    end

    tmp = Downloads.download(url)
    covid_all = CSV.read(tmp, DataFrame)

    if :Date_reported in names(covid_all)
        rename!(covid_all, :Date_reported => :date)
    end

    if :date in names(covid_all)
        covid_all[!, :date] = Date.(covid_all[!, :date])
    end

    covid_all_daily = covid_all[:, [
        :date, :Country_code, :Country, :WHO_region,
        :New_cases, :Cumulative_cases, :New_deaths, :Cumulative_deaths
    ]]

    CSV.write(outfile, covid_all_daily)
    return covid_all_daily
end

println("Loading COVID-19 daily data...")
covid_all_daily = load_covid_daily()
println("COVID-19 daily data loaded successfully.")
println("Number of records: ", nrow(covid_all_daily))
println("Columns: ", names(covid_all_daily))
println("Date range: ", minimum(covid_all_daily.date), " to ", maximum(covid_all_daily.date))
println("Sample data:")
first(covid_all_daily, 5) |> println

using Plots
using Statistics
using Measures

default(
    # ─── Размер и разрешение ───────────────────────────────────────────
    # Nature/Science: одна колонка = 89mm, две = 183mm
    # 89mm @ 600dpi = 2102px
    size        = (2102, 1600),   # single-column, ~4:3
    dpi         = 600,            # минимум для line art (Nature требует 300+, Cell — 600)
    
    # ─── Шрифт ─────────────────────────────────────────────────────────
    # Helvetica / Arial — стандарт большинства топ-журналов
    fontfamily      = "Helvetica",
    titlefontsize   = 28,
    guidefontsize   = 24,         # подписи осей
    tickfontsize    = 20,
    legendfontsize  = 20,
    annotationfontsize = 20,

    # ─── Линии ─────────────────────────────────────────────────────────
    linewidth           = 2.5,
    thickness_scaling   = 1.0,    # не масштабировать поверх явных значений
    markerstrokewidth   = 1.5,
    markersize          = 8,

    # ─── Оси и сетка ───────────────────────────────────────────────────
    grid            = true,
    gridalpha       = 0.25,
    gridlinewidth   = 1.0,
    gridstyle       = :dot,
    minorgrid       = false,
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
    legendlinewidth = 2.5,
)

gr();  # Используем бэкенд GR для лучшей производительности при сохранении графиков

# Если нужно, загрузите данные заранее и получите covid_all_daily
covid_all_daily = load_covid_daily()

# Список стран в названиях из WHO-файла
countries = Dict(
    "United States of America" => "США",
    "Russian Federation" => "Россия",
    "India" => "Индия",
    "Brazil" => "Бразилия",
    "United Kingdom of Great Britain and Northern Ireland" => "Великобритания",
    "Germany" => "Германия",
    "Republic of Korea" => "Южная Корея"
)

# Оставляем только нужные страны
df = filter(row -> haskey(countries, row.Country), covid_all_daily)

# Приводим пропуски к нулям и упорядочиваем
df.New_cases = coalesce.(df.New_cases, 0)

# Группировка по датам и странам
wide = unstack(df[:, [:date, :Country, :New_cases]], :date, :Country, :New_cases)

# Сортировка по дате
sort!(wide, :date)

labels = permutedims(collect(values(countries)))

p = plot(
    wide.date,
    [wide[!, k] for k in keys(countries)],
    label = labels,
    linewidth = 2.5,
    legend = :top,
    grid = true,
    xlabel = "Дата",
    ylabel = "Новые случаи",
    title = "COVID-19: новые случаи по дням (2020–2026)",
    size = (1600, 900),
    dpi = 300
)


savefig(p, "covid_cases_by_country raw.png")

countries = Dict(
    "United States of America" => "США",
    "Russian Federation" => "Россия",
    "India" => "Индия",
    "Brazil" => "Бразилия",
    "United Kingdom of Great Britain and Northern Ireland" => "Великобритания",
    "Germany" => "Германия",
    "Republic of Korea" => "Южная Корея"
)

usa = filter(row -> row.Country == "United States of America", df)
usa = sort(usa, :date)

println("USA data:")
first(usa, 25) |> println

# Функция для заполнения пропусков нулями и создания полной сетки дат
function fill_daily_grid(df)
    all_dates = minimum(df.date):Day(1):maximum(df.date)
    grid = DataFrame(date = all_dates)
    grid = leftjoin(grid, df[:, [:date, :Cumulative_cases]], on = :date)
    return grid
end

grid = fill_daily_grid(usa)
println("Filled grid for USA:")
first(grid, 25) |> println

display(plot(grid.date, grid.Cumulative_cases, label = "USA", linewidth = 2.5, title = "USA Cumulative Cases (raw)"))

# Линейная интерполяция для заполнения пропусков
function interp_missing_linear(y)
    x = 1:length(y)
    mask = .!ismissing.(y)
    itp = LinearInterpolation(x[mask], y[mask], extrapolation_bc = Line())
    return itp.(x)
end
y_interp = interp_missing_linear(grid.Cumulative_cases)
display(plot(grid.date, y_interp, label = "USA (interpolated)", linewidth = 2.5, title = "USA Cumulative Cases (interpolated)"))

# Функция для скользящего среднего
function rolling_mean(arr, window_size)
    a  = Float64.(arr)          # убиваем SimpleRatio до любой арифметики
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

y_interp2 = rolling_mean(y_interp, 7)
display(plot(grid.date, y_interp2, label = "USA (7-day rolling mean)", linewidth = 2.5, title = "USA Cumulative Cases (7-day rolling mean)"))

# теперь нужно найди разность между соседними днями, чтобы получить ежедневный прирост
daily = max.([0.0; diff(y_interp)], 0.0)
daily_smooth = rolling_mean(daily, 7)
display(plot(grid.date, daily_smooth, label = "USA (daily new cases, 7-day rolling mean)", linewidth = 2.5, title = "USA Daily New Cases (7-day rolling mean)"))

# а тперь: посторить такие графики по всем странам (включая и США) и сохранить их в папку "plots", а данные аккумулировать в новом датасете, 
# который будет содержать столбцы: date, country, daily_new_cases_smoothed и еще одном, где каждая страна будет располагаться в отдельном столбце (для удобства построения графиков)

# Создаем новый DataFrame для аккумулирования данных по всем странам в одну колонку
results = DataFrame(date = grid.date)

for (country_eng, country_rus) in countries
    country_df = filter(row -> row.Country == country_eng, df)
    country_df = sort(country_df, :date)
    grid = fill_daily_grid(country_df)
    y_interp = interp_missing_linear(grid.Cumulative_cases)
    y_interp_smooth = rolling_mean(y_interp, 7)
    daily = max.([0.0; diff(y_interp)], 0.0)
    daily_smooth = rolling_mean(daily, 7)

    # Сохранение графика для каждой страны
    p_country = plot(
        grid.date,
        daily_smooth,
        label = "$country_rus (daily new cases, 7-day rolling mean)",
        linewidth = 2.5,
        title = "$country_rus: Daily New Cases (7-day rolling mean)",
        xlabel = "Дата",
        ylabel = "Новые случаи",
        grid = true,
        size = (1600, 900),
        dpi = 300
    )
    display(p_country)
    savefig(p_country, "covid_daily_new_cases_$country_rus.png")
    # add to results DataFrame new column with smoothed daily new cases
    results[!, country_rus] = daily_smooth
end

println("All country plots saved successfully.")
println("Results DataFrame:")
first(results, 25) |> println

# save results DataFrame to csv
println("Saving results to CSV...")
CSV.write("covid_daily_smoothed.csv", results)
println("Results saved to covid_daily_smoothed.csv")
