# ╔═══════════════════════════════════════════════════════════════════════════════
# ║  COVID-19 Data Visualization — с отображением графиков на экране
# ╚═══════════════════════════════════════════════════════════════════════════════

# ───────────────────────────────────────────────────────────────────────────────
# 1. Подключение пакетов и настройка бэкенда
# ───────────────────────────────────────────────────────────────────────────────
using CSV
using DataFrames
using Dates
using Downloads
using Plots
using Statistics

# 🔧 Автоопределение среды и выбор бэкенда
function setup_plot_backend()
    if isinteractive()
        # Интерактивная среда (REPL, VS Code, Jupyter)
        if Sys.islinux() && !haskey(ENV, "DISPLAY")
            @info "Linux без GUI: используем бэкенд 'inspect' (только сохранение)"
            gr()
        else
            @info "Интерактивная среда: используем бэкенд 'gr' с отображением"
            gr()  # или plotlyjs() для интерактивности
        end
    else
        # Скриптовый режим
        @info "Скриптовый режим: используем 'gr' + явный display()"
        gr()
    end
end

setup_plot_backend()

# ───────────────────────────────────────────────────────────────────────────────
# 2. Функция загрузки данных (без изменений)
# ───────────────────────────────────────────────────────────────────────────────
function load_covid_daily(;
    url::String = "https://srhdpeuwpubsa.blob.core.windows.net/whdh/COVID/WHO-COVID-19-global-daily-data.csv",
    outfile::String = "covid_all_daily.csv",
    force_download::Bool = false
)
    if isfile(outfile) && !force_download
        @info "Загрузка из локального файла: $outfile"
        return CSV.read(outfile, DataFrame)
    end

    @info "Скачивание данных..."
    tmp = Downloads.download(url)
    covid_all = CSV.read(tmp, DataFrame)

    if :Date_reported in names(covid_all)
        rename!(covid_all, :Date_reported => :date)
    end
    if :date in names(covid_all)
        covid_all[!, :date] = Date.(covid_all[!, :date])
    end

    required_cols = [:date, :Country_code, :Country, :WHO_region,
                     :New_cases, :Cumulative_cases, :New_deaths, :Cumulative_deaths]
    available_cols = filter(c -> c in names(covid_all), required_cols)
    
    covid_all_daily = covid_all[:, available_cols]
    CSV.write(outfile, covid_all_daily)
    return covid_all_daily
end

# ───────────────────────────────────────────────────────────────────────────────
# 3. Заполнение сетки дат
# ───────────────────────────────────────────────────────────────────────────────
function fill_daily_grid(d::DataFrame; 
                         date_col::Symbol = :date, 
                         value_col::Symbol = :Cumulative_cases)
    mind = minimum(d[!, date_col])
    maxd = maximum(d[!, date_col])
    full = DataFrame(date_col => collect(mind:Day(1):maxd))
    out = leftjoin(full, d[:, [date_col, value_col]], on = date_col)
    return out
end

# ───────────────────────────────────────────────────────────────────────────────
# 4. Линейная интерполяция
# ───────────────────────────────────────────────────────────────────────────────
function interp_missing_linear(v::AbstractVector{Union{Missing, T}}) where T<:Real
    n = length(v)
    res = Vector{Float64}(undef, n)
    known_idx = findall(!ismissing, v)
    
    if isempty(known_idx)
        @warn "Пустой вектор — возвращаем нули"
        return zeros(Float64, n)
    end
    
    for i in known_idx
        res[i] = Float64(v[i])
    end
    
    for i in 1:n
        if ismissing(v[i])
            left = findlast(j -> j < i && !ismissing(v[j]), 1:i-1)
            right = findfirst(j -> j > i && !ismissing(v[j]), i+1:n)
            
            if isnothing(left) && !isnothing(right)
                res[i] = Float64(v[right])
            elseif !isnothing(left) && isnothing(right)
                res[i] = Float64(v[left])
            elseif !isnothing(left) && !isnothing(right)
                xl, xr = left, right
                yl, yr = Float64(v[xl]), Float64(v[xr])
                res[i] = yl + (yr - yl) * (i - xl) / (xr - xl)
            else
                res[i] = 0.0
            end
        end
    end
    return res
end

# ───────────────────────────────────────────────────────────────────────────────
# 5. Сглаживание скользящим средним
# ───────────────────────────────────────────────────────────────────────────────
function rolling_mean(v::AbstractVector, window::Int)
    n = length(v)
    result = Vector{Float64}(undef, n)
    for i in 1:n
        start_idx = max(1, i - window + 1)
        result[i] = mean(v[start_idx:i])
    end
    return result
end

# ───────────────────────────────────────────────────────────────────────────────
# 6. 🔥 Функция отображения графика (кросс-платформенная)
# ───────────────────────────────────────────────────────────────────────────────
function show_plot(p; title::String = "График", sleep_time::Real = 2.0)
    try
        # Явное отображение — работает в VS Code, Jupyter, REPL
        display(p)
        
        # Для REPL и скриптового режима: даём время на отрисовку
        if !isinteractive()
            @info "Отображение: $title (ждем $sleep_time сек)..."
            sleep(sleep_time)
        end
        
        # Для GR-бэкенда: попытка открыть окно (работает в некоторых средах)
        if Plots.backend() == Plots.GRBackend()
            gui()  # Не блокирует выполнение, но показывает окно
        end
        
    catch e
        @warn "Не удалось отобразить график '$title': $e"
    end
end

# ───────────────────────────────────────────────────────────────────────────────
# 7. Основная функция
# ───────────────────────────────────────────────────────────────────────────────
function main()
    @info "Загрузка данных..."
    covid_all_daily = load_covid_daily()
    @info "Записей: $(nrow(covid_all_daily)), даты: $(minimum(covid_all_daily.date)) — $(maximum(covid_all_daily.date))"
    
    countries = Dict(
        "United States of America" => "США",
        "Russian Federation" => "Россия",
        "India" => "Индия",
        "Brazil" => "Бразилия",
        "United Kingdom of Great Britain and Northern Ireland" => "Великобритания",
        "Germany" => "Германия",
        "Republic of Korea" => "Южная Корея"
    )
    
    df = filter(row -> haskey(countries, row.Country), covid_all_daily)
    sort!(df, [:Country, :date])
    df[!, :Cumulative_cases] = allowmissing(df[!, :Cumulative_cases])
    
    # Настройка графиков
    p_cumulative = plot(
        title = "COVID-19: накопленные случаи",
        xlabel = "Дата", ylabel = "Накопленные случаи",
        legend = :topleft, grid = true, size = (1600, 900), dpi = 300,
        linewidth = 2.5, foreground_color_legend = nothing
    )
    
    p_daily = plot(
        title = "COVID-19: дневной прирост (7-дневное сглаживание)",
        xlabel = "Дата", ylabel = "Новые случаи",
        legend = :topleft, grid = true, size = (1600, 900), dpi = 300,
        linewidth = 2, foreground_color_legend = nothing
    )
    
    for (en, ru) in countries
        @info "Обработка: $ru"
        d = filter(row -> row.Country == en, df) |> d -> sort(d, :date)
        nrow(d) == 0 && continue
        
        grid = fill_daily_grid(d)
        y_cum = interp_missing_linear(grid.Cumulative_cases)
        
        plot!(p_cumulative, grid.date, y_cum, label = ru, linewidth = 2.5)
        
        daily = max.([0.0; diff(y_cum)], 0.0)
        daily_smooth = rolling_mean(daily, 7)
        plot!(p_daily, grid.date, daily_smooth, label = ru, linewidth = 2)
    end
    
    # 💾 Сохранение
    savefig(p_cumulative, "covid_cumulative.png")
    savefig(p_daily, "covid_daily.png")
    @info "Графики сохранены: covid_cumulative.png, covid_daily.png"
    
    # 👁️ Отображение на экране
    @info "Отображение графиков..."
    show_plot(p_cumulative; title = "Накопленные случаи", sleep_time = 3.0)
    show_plot(p_daily; title = "Дневной прирост", sleep_time = 3.0)
    
    # 🛑 Блокировка в скриптовом режиме, чтобы окна не закрылись сразу
    if !isinteractive()
        @info "Скриптовый режим: ждём 10 секунд перед завершением..."
        sleep(10)
    end
    
    return p_cumulative, p_daily
end

# ───────────────────────────────────────────────────────────────────────────────
# 8. Запуск
# ───────────────────────────────────────────────────────────────────────────────
if abspath(PROGRAM_FILE) == @__FILE__
    @time main()
end