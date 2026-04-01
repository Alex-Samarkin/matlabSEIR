# ════════════════════════════════════════════════════════════════════════════════
# utils.jl — Общие утилиты для проекта SEIR/SEIRD моделирования COVID-19
# ════════════════════════════════════════════════════════════════════════════════
#
# Назначение:
#   Этот модуль содержит переиспользуемые функции, константы и настройки,
#   которые используются в нескольких скриптах проекта:
#     • load_data.jl          — загрузка и предобработка данных
#     • waves_detection.jl    — обнаружение волн и визуализация
#     • waves_and_stamms.jl   — параметры штаммов, timeline, radar
#     • seir modelling.jl     — детальный анализ отдельных волн
#     • seird_pipeline.jl     — классическая + дробная SEIRD
#
# Использование:
#   include("utils.jl")  # в начале вашего скрипта
#
# Автор: Alexander Samarkin
# Дата: 2026-03-30
# ════════════════════════════════════════════════════════════════════════════════

# ──────────────────────────────────────────────────────────────────────────────
# 1. ИМПОРТ БИБЛИОТЕК (PACKAGES)
# ──────────────────────────────────────────────────────────────────────────────
#
# Эти пакеты должны быть установлены в вашей Julia-среде.
# Если пакетов нет, выполните в REPL:
#
#   using Pkg
#   Pkg.add(["CSV", "DataFrames", "Dates", "Downloads", "Plots",
#            "Statistics", "StatsPlots", "Measures", "Interpolations"])
#

using CSV           # Чтение и запись CSV-файлов
using DataFrames    # Работа с табличными данными (аналог pandas/R data.frame)
using Dates         # Работа с датами и временными интервалами
using Downloads     # Загрузка файлов из интернета (WHO данные)
using Interpolations# Интерполяция пропущенных значений (линейная, сплайны)
using Plots         # Построение графиков (бэкенд GR по умолчанию)
using Statistics    # Статистические функции (mean, std, cor и т.д.)
using StatsPlots    # Расширенные возможности для Plots.jl (groupedbar и др.)
using Measures      # Единицы измерения для отступов (mm, cm, inch)

# ──────────────────────────────────────────────────────────────────────────────
# 2. НАСТРОЙКИ ВИЗУАЛИЗАЦИИ (PLOT THEMES)
# ──────────────────────────────────────────────────────────────────────────────
#
# Настройки соответствуют стандартам научных журналов Nature/Science:
#   • Размер: single-column = 89mm @ 600dpi = 2102px
#   • Шрифт: Arial/Helvetica (colorblind-safe)
#   • Цвета: Wong 2011 palette (доступно для дальтоников)
#   • Рамка: box style с inward ticks
#

"""
    apply_nature_theme!()

Применяет настройки визуализации в стиле Nature/Science journals.
Изменяет глобальные настройки Plots.default!().

Параметры стиля:
  - size: 2102×1600 px (single-column 89mm @ 600dpi)
  - font: Arial, titlefontsize=28, guidefontsize=24, tickfontsize=20
  - linewidth: 2.5, markerstrokewidth: 1.5
  - grid: точечный, alpha=0.25
  - framestyle: :box (рамка со всех сторон)
  - tick_direction: :in (тики внутрь)
  - palette: Wong 2011 colorblind-safe

Пример:
    apply_nature_theme!()
    plot(x, y, label="Data")
"""
function apply_nature_theme!()
    Plots.default(
        # ─── Размер и разрешение ───────────────────────────────────────────
        # Nature/Science: одна колонка = 89mm, две = 183mm
        # 89mm @ 600dpi = 2102px
        size        = (2102, 1600),   # single-column, ~4:3
        dpi         = 600,            # минимум для line art (Nature требует 300+, Cell — 600)

        # ─── Шрифт ─────────────────────────────────────────────────────────
        # Helvetica / Arial — стандарт большинства топ-журналов
        fontfamily      = "Arial",   # Helvetica может быть недоступен, Arial — хороший аналог
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
    return nothing
end


"""
    apply_light_theme()

Облегчённая тема для быстрой отладки (меньше размер, ниже dpi).
Используйте во время разработки для ускорения отрисовки.

Параметры:
  - size: 1600×900 px
  - dpi: 150
  - font: Helvetica, уменьшенные размеры шрифтов
"""
function apply_light_theme()
    Plots.default(
        size      = (1600, 900),
        dpi       = 150,
        fontfamily      = "Helvetica",
        titlefontsize   = 18,
        guidefontsize   = 16,
        tickfontsize    = 14,
        legendfontsize  = 12,
        annotationfontsize = 12,
        linewidth       = 2.5,
        markerstrokewidth = 1.5,
        markersize      = 8,
        grid            = true,
        gridalpha       = 0.2,
        gridlinewidth   = 0.8,
        gridstyle       = :solid,
        minorgrid       = true,
        framestyle      = :box,
        tick_direction  = :in,
        palette         = [
            RGB(0/255,  114/255, 178/255),
            RGB(230/255, 159/255,   0/255),
            RGB(  0/255, 158/255, 115/255),
            RGB(213/255,  94/255,   0/255),
            RGB( 86/255, 180/255, 233/255),
            RGB(204/255, 121/255, 167/255),
            RGB(  0/255,   0/255,   0/255),
        ],
        background_color        = :white,
        background_color_legend = :white,
        foreground_color        = :black,
        margin          = 8mm,
        left_margin     = 12mm,
        bottom_margin   = 10mm,
        legend          = :topright,
    )
    return nothing
end


# ──────────────────────────────────────────────────────────────────────────────
# 3. СПРАВОЧНИКИ СТРАН И ШТАММОВ
# ──────────────────────────────────────────────────────────────────────────────

"""
    COUNTRIES_WHO :: Dict{String, String}

Словарь соответствия названий стран из WHO-файла (английский) 
и русских названий для визуализации.

Используется в:
  - load_data.jl (фильтрация стран)
  - waves_detection.jl (построение графиков)
"""
const COUNTRIES_WHO = Dict(
    "United States of America" => "США",
    "Russian Federation" => "Россия",
    "India" => "Индия",
    "Brazil" => "Бразилия",
    "United Kingdom of Great Britain and Northern Ireland" => "Великобритания",
    "Germany" => "Германия",
    "Republic of Korea" => "Южная Корея"
)


"""
    COUNTRIES_SYMBOLS :: Vector{Symbol}

Список стран в виде Symbol для использования в DataFrame колонках.
Порядок соответствует COUNTRIES_WHO.
"""
const COUNTRIES_SYMBOLS = [
    :Россия, :Великобритания, :США, :Германия, :Индия, Symbol("Южная Корея"), :Бразилия
]


"""
    VARIANT_PARAMS :: DataFrame

Биологические параметры штаммов SARS-CoV-2:
  - strain: название варианта
  - R0_min, R0_max: диапазон базового репродуктивного числа
  - incubation: инкубационный период (дни)
  - infectious: период заразности (дни)
  - CFR: case fatality rate (доля смертей)
  - dominance_start, dominance_end: период доминирования

Источники данных:
  - Wuhan: ранние исследования 2020
  - Alpha: B.1.1.7, UK 2020
  - Delta: B.1.617.2, India 2021
  - Omicron: BA.1, BA.2, BA.5, XBB, JN.1 (2021-2024)
"""
const VARIANT_PARAMS = DataFrame(
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

# Вычисляем длительность доминирования для каждого штамма
VARIANT_PARAMS[!, :duration] = Dates.value.(VARIANT_PARAMS.dominance_end) .- 
                               Dates.value.(VARIANT_PARAMS.dominance_start)


# ──────────────────────────────────────────────────────────────────────────────
# 4. ФУНКЦИИ ПРЕДОБРАБОТКИ ДАННЫХ
# ──────────────────────────────────────────────────────────────────────────────

"""
    load_covid_daily(; 
        url::String = "https://srhdpeuwpubsa.blob.core.windows.net/whdh/COVID/WHO-COVID-19-global-daily-data.csv",
        outfile::String = "covid_all_daily.csv",
        force_download::Bool = false
    ) -> DataFrame

Загружает ежедневные данные COVID-19 из WHO.

Аргументы:
  - `url`: URL для загрузки CSV (WHO official source)
  - `outfile`: локальный путь для сохранения кэша
  - `force_download`: если true, загружает заново даже при наличии кэша

Возвращает:
  DataFrame с колонками:
    - date: Date_reported преобразованный в Date
    - Country_code: ISO код страны
    - Country: полное название страны
    - WHO_region: регион ВОЗ
    - New_cases: новые случаи за день
    - Cumulative_cases: накопительный итог
    - New_deaths: новые смерти
    - Cumulative_deaths: накопительный итог смертей

Пример:
    df = load_covid_daily()
    df = load_covid_daily(force_download=true)  # обновить кэш
"""
function load_covid_daily(;
    url::String = "https://srhdpeuwpubsa.blob.core.windows.net/whdh/COVID/WHO-COVID-19-global-daily-data.csv",
    outfile::String = "covid_all_daily.csv",
    force_download::Bool = false
)
    # Проверяем наличие кэша
    if isfile(outfile) && !force_download
        covid_all = CSV.read(outfile, DataFrame)
        @info "Данные загружены из кэша: $outfile" nrow(covid_all)
        return covid_all
    end

    # Скачиваем свежий файл
    @info "Загрузка данных из WHO..." url
    tmp = Downloads.download(url)
    covid_all = CSV.read(tmp, DataFrame)

    # Переименовываем колонку даты если нужно
    if :Date_reported in names(covid_all)
        rename!(covid_all, :Date_reported => :date)
    end

    # Преобразуем строки дат в Date
    if :date in names(covid_all)
        covid_all[!, :date] = Date.(covid_all[!, :date])
    end

    # Отбираем только нужные колонки
    covid_all_daily = covid_all[:, [
        :date, :Country_code, :Country, :WHO_region,
        :New_cases, :Cumulative_cases, :New_deaths, :Cumulative_deaths
    ]]

    # Сохраняем в кэш
    CSV.write(outfile, covid_all_daily)
    @info "Данные сохранены: $outfile" nrow(covid_all_daily)

    return covid_all_daily
end


"""
    fill_daily_grid(df::DataFrame; date_col::Symbol=:date, 
                    value_col::Symbol=:Cumulative_cases) -> DataFrame

Создаёт полную сетку дат без пропусков для временного ряда.

Аргументы:
  - `df`: DataFrame с колонками date и значениями
  - `date_col`: имя колонки с датами (по умолчанию :date)
  - `value_col`: имя колонки со значениями (по умолчанию :Cumulative_cases)

Возвращает:
  DataFrame с непрерывным диапазоном дат от минимума до максимума.
  Пропущенные значения остаются missing для последующей интерполяции.

Алгоритм:
  1. Находит минимальную и максимальную дату
  2. Создаёт сетку всех дней в диапазоне
  3. Left join с исходными данными

Пример:
    grid = fill_daily_grid(usa_data)
    println("Пропусков: ", sum(ismissing.(grid.Cumulative_cases)))
"""
function fill_daily_grid(df::DataFrame; 
                         date_col::Symbol=:date, 
                         value_col::Symbol=:Cumulative_cases)
    # Диапазон всех дат
    all_dates = minimum(df[!, date_col]):Day(1):maximum(df[!, date_col])
    
    # Создаём сетку
    grid = DataFrame(date = all_dates)
    rename!(grid, date_col => :date)
    
    # Left join с данными
    grid = leftjoin(grid, df[:, [date_col, value_col]], on = :date)
    
    return grid
end


"""
    interp_missing_linear(y::AbstractVector) -> Vector{Float64}

Линейная интерполяция пропущенных значений в массиве.

Аргументы:
  - `y`: вектор с возможными missing/NaN значениями

Возвращает:
  Вектор Float64 той же длины, где пропуски заполнены линейной интерполяцией.
  Граничные значения экстраполируются по ближайшим точкам.

Алгоритм:
  1. Находит индексы не-missing значений
  2. Строит LinearInterpolation по известным точкам
  3. Применяет интерполяцию ко всем индексам

Пример:
    y = [1.0, missing, 3.0, missing, 5.0]
    y_filled = interp_missing_linear(y)
    # результат: [1.0, 2.0, 3.0, 4.0, 5.0]
"""
function interp_missing_linear(y::AbstractVector)
    x = 1:length(y)
    mask = .!ismissing.(y) .&& .!isnan.(y)
    
    # Если все значения missing, возвращаем нули
    if !any(mask)
        return zeros(length(y))
    end
    
    # Строим интерполянт
    itp = LinearInterpolation(x[mask], y[mask], extrapolation_bc = Line())
    
    return itp.(x)
end


"""
    rolling_mean(arr::AbstractVector, window_size::Int) -> Vector{Float64}

Вычисляет скользящее среднее с адаптивным окном в начале ряда.

Аргументы:
  - `arr`: входной массив (может быть SimpleRatio, Int, Float)
  - `window_size`: размер окна (например, 7 для недельного сглаживания)

Возвращает:
  Вектор Float64 той же длины, где каждый элемент — среднее значение
  за предыдущие window_size точек.

Особенности:
  - В начале ряда (i ≤ window_size) используется доступное количество точек
  - Эффективно для сглаживания ежедневных колебаний COVID-данных

Алгоритм:
  Использует кумулятивную сумму для O(n) сложности вместо O(n*window).

Пример:
    daily_cases = [0, 5, 10, 15, 20, 25, 30]
    smoothed = rolling_mean(daily_cases, 7)
    # smoothed[7] = mean([0,5,10,15,20,25,30]) = 15.0
"""
function rolling_mean(arr::AbstractVector, window_size::Int)
    # Преобразуем к Float64 для арифметики
    a  = Float64.(arr)
    
    # Кумулятивная сумма
    cs = cumsum(a)
    n  = length(cs)
    result = Vector{Float64}(undef, n)
    
    # Вычисляем скользящее среднее
    for i in 1:n
        if i <= window_size
            # В начале ряда — среднее по всем доступным точкам
            result[i] = cs[i] / i
        else
            # Полное окно
            result[i] = (cs[i] - cs[i - window_size]) / window_size
        end
    end
    
    return result
end


"""
    compute_daily_new(cumulative::AbstractVector) -> Vector{Float64}

Вычисляет ежедневный прирост из накопительных данных.

Аргументы:
  - `cumulative`: вектор накопительных значений (после интерполяции)

Возвращает:
  Вектор дневного прироста. Первый элемент = 0.0.
  Отрицательные значения (артефакты интерполяции) обрезаются до 0.

Пример:
    cum = [0, 10, 25, 45, 70]
    daily = compute_daily_new(cum)
    # результат: [0.0, 10.0, 15.0, 20.0, 25.0]
"""
function compute_daily_new(cumulative::AbstractVector)
    daily = [0.0; diff(cumulative)]
    return max.(daily, 0.0)  # защита от отрицательных значений
end


# ──────────────────────────────────────────────────────────────────────────────
# 5. ФУНКЦИИ ОБНАРУЖЕНИЯ ВОЛН
# ──────────────────────────────────────────────────────────────────────────────

"""
    find_wave_minima(smoothed::AbstractVector;
                     min_prominence::Float64=0.15,
                     min_distance::Int=30) -> Vector{Int}

Находит локальные минимумы для определения границ волн.

Аргументы:
  - `smoothed`: сглаженный временной ряд (например, 21-day rolling mean)
  - `min_prominence`: минимальная значимость минимума (доля от глобального максимума)
  - `min_distance`: минимальное расстояние между минимумами (в днях)

Возвращает:
  Вектор индексов локальных минимумов, удовлетворяющих критериям.

Алгоритм:
  1. Находит все локальные минимумы (y[i] < y[i-1] и y[i] < y[i+1])
  2. Фильтрует по prominence: минимум должен быть ниже threshold% от пика
  3. Фильтрует по min_distance: если минимумы ближе, выбираем глубочайший

Параметры по умолчанию (для COVID-19):
  - min_prominence = 0.18 (18% от пика)
  - min_distance = 31 день (месяц между волнами)

Пример:
    smoothed = rolling_mean(cases, 21)
    minima = find_wave_minima(smoothed, min_prominence=0.18, min_distance=31)
    println("Границы волн: ", dates[minima])
"""
function find_wave_minima(smoothed::AbstractVector;
                          min_prominence::Float64=0.15,
                          min_distance::Int=30)
    n = length(smoothed)
    global_max = maximum(smoothed)
    threshold = global_max * min_prominence

    minima = Int[]
    i = 2
    
    while i < n
        # Проверяем локальный минимум
        if smoothed[i] < smoothed[i-1] && smoothed[i] < smoothed[i+1]
            
            # Проверяем prominence (значимость)
            if smoothed[i] < threshold
                
                # Проверяем минимальное расстояние
                if isempty(minima)
                    push!(minima, i)
                elseif (i - last(minima)) >= min_distance
                    # Достаточно далеко — добавляем
                    push!(minima, i)
                elseif smoothed[i] < smoothed[last(minima)]
                    # Ближе чем min_distance, но глубже — заменяем
                    minima[end] = i
                end
            end
        end
        i += 1
    end
    
    return minima
end


"""
    assign_waves(cases::DataFrame, country::Symbol;
                 window::Int=21,
                 min_prominence::Float64=0.15,
                 min_distance::Int=30) -> (DataFrame, Vector{Float64}, Vector{Int})

Присваивает номера волн данным по стране.

Аргументы:
  - `cases`: DataFrame с колонками дат и случаев по странам
  - `country`: Symbol страны (например, :Россия)
  - `window`: окно сглаживания (дней)
  - `min_prominence`, `min_distance`: параметры детекции минимумов

Возвращает:
  Кортеж из:
    1. cases с добавленной колонкой "{country}_волна"
    2. smoothed: сглаженный ряд (21-day rolling mean)
    3. minima: индексы границ волн

Алгоритм:
  1. Сглаживает данные (rolling_mean с окном window)
  2. Находит локальные минимумы (find_wave_minima)
  3. Присваивает номера волн: от 1 до границы, от границы до границы, ...

Пример:
    cases, smoothed, minima = assign_waves(cases, :Россия; 
                                           window=23, 
                                           min_prominence=0.18,
                                           min_distance=31)
    println("Волн найдено: ", maximum(cases.Россия_волна))
"""
function assign_waves(cases::DataFrame, country::Symbol;
                      window::Int=21,
                      min_prominence::Float64=0.15,
                      min_distance::Int=30)
    
    # Сглаживание
    smoothed = rolling_mean(cases[!, country], window)
    
    # Поиск минимумов
    minima = find_wave_minima(smoothed; 
                              min_prominence=min_prominence, 
                              min_distance=min_distance)

    # Инициализация колонки волн
    n = nrow(cases)
    wave_col = zeros(Int, n)
    
    # Границы: начало, минимумы, конец
    boundaries = [1; minima; n]

    # Присваиваем номера волн
    for w in 1:length(boundaries)-1
        wave_col[boundaries[w]:boundaries[w+1]] .= w
    end

    # Добавляем колонку в DataFrame
    col_name = Symbol(string(country) * "_волна")
    cases[!, col_name] = wave_col

    return cases, smoothed, minima
end


# ──────────────────────────────────────────────────────────────────────────────
# 6. ФУНКЦИИ ВЫБОРКИ ДАННЫХ ПО ВОЛНАМ
# ──────────────────────────────────────────────────────────────────────────────

"""
    build_country_dict(cases::DataFrame, 
                       countries::Vector{Symbol}) -> Dict{Int, Tuple{Symbol, Symbol}}

Строит словарь для доступа к волнам по индексу.

Аргументы:
  - `cases`: DataFrame с данными (должны быть колонки {country}_волна)
  - `countries`: список стран Symbol

Возвращает:
  Dict где:
    - ключ: индекс страны (1-based)
    - значение: кортеж (country_symbol, wave_column_symbol)

Пример:
    country_dict = build_country_dict(cases, COUNTRIES_SYMBOLS)
    # country_dict[1] => (:Россия, :Россия_волна)
"""
function build_country_dict(cases::DataFrame, countries::Vector{Symbol})
    return Dict(
        i => (country, Symbol(string(country) * "_волна"))
        for (i, country) in enumerate(countries)
    )
end


"""
    select_wave(cases::DataFrame, country_dict::Dict,
                country_idx::Int, wave_num::Int) -> DataFrame

Отбирает данные конкретной волны для страны.

Аргументы:
  - `cases`: DataFrame с волнами и параметрами штаммов
  - `country_dict`: словарь от build_country_dict()
  - `country_idx`: индекс страны (1-based, см. country_dict)
  - `wave_num`: номер волны

Возвращает:
  DataFrame с колонками:
    - date
    - {country}: случаи по дням
    - {country}_волна: номер волны
    - strain, variant_rule: информация о штамме
    - R0_min, R0_max, R0: репродуктивное число
    - incubation, infectious, CFR: биопараметры

Пример:
    # Россия (индекс 1), волна 2
    df = select_wave(cases, country_dict, 1, 2)
    
    # Индия (индекс 5), волна 3
    df = select_wave(cases, country_dict, 5, 3)
"""
function select_wave(cases::DataFrame,
                     country_dict::Dict,
                     country_idx::Int,
                     wave_num::Int)::DataFrame

    # Проверка наличия страны в словаре
    @assert haskey(country_dict, country_idx) "Страна $country_idx не найдена в словаре"

    country, wave_col = country_dict[country_idx]

    # Проверка наличия колонки волн
    @assert wave_col in propertynames(cases) "Колонка $wave_col не найдена — сначала запустите assign_waves()"

    # Проверка существования волны
    max_wave = maximum(cases[!, wave_col])
    @assert 1 <= wave_num <= max_wave "Волна $wave_num не существует для $(string(country)) (всего волн: $max_wave)"

    # Маска строк нужной волны
    mask = cases[!, wave_col] .== wave_num

    # Колонки для выбора
    strain_cols = [:strain, :variant_rule, :R0_min, :R0_max,
                   :R0, :incubation, :infectious, :CFR]

    selected_cols = [:date, country, wave_col, strain_cols...]

    return cases[mask, selected_cols]
end


# ──────────────────────────────────────────────────────────────────────────────
# 7. ФУНКЦИИ ВИЗУАЛИЗАЦИИ ВОЛН
# ──────────────────────────────────────────────────────────────────────────────

"""
    plot_wave_detail(df::DataFrame, country::Symbol, wave_num::Int) -> Plot

Строит детальный график волны с периодами доминирования штаммов.

Аргументы:
  - `df`: DataFrame от select_wave() с данными волны
  - `country`: Symbol страны (:Россия, :США, ...)
  - `wave_num`: номер волны для заголовка

Возвращает:
  Plot с:
    - основная кривая: ежедневные случаи
    - фоновые зоны: периоды доминирования штаммов
    - правая ось: R0(t) пунктиром

Особенности:
  - Цвета штаммов согласованы с VARIANT_PARAMS
  - Две оси Y: слева случаи, справа R0
  - Аннотации с названиями штаммов

Пример:
    df = select_wave(cases, country_dict, 1, 2)
    p = plot_wave_detail(df, :Россия, 2)
    savefig(p, "wave_detail_russia_2.png")
"""
function plot_wave_detail(df::DataFrame, country::Symbol, wave_num::Int)
    
    # Извлекаем данные
    dates = df.date
    vals = Float64.(df[!, country])
    r0 = Float64.(df.R0)
    
    # Диапазоны осей
    ymax = maximum(vals) * 1.15
    r0max = maximum(r0) * 1.15
    r0min = minimum(r0) * 0.85

    # Цвета для штаммов
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
    
    # Словари цветов по штаммам
    strain_palette = Dict(
        s => base_colors_fill[mod1(i, 6)]
        for (i, s) in enumerate(unique_strains)
    )
    strain_line = Dict(
        s => base_colors_line[mod1(i, 6)]
        for (i, s) in enumerate(unique_strains)
    )

    # Находим сегменты штаммов (последовательные периоды)
    strain_segments = Tuple{Int,Int,String}[]
    cur_strain = df.strain[1]
    seg_start = 1
    
    for i in 2:nrow(df)
        if df.strain[i] != cur_strain
            push!(strain_segments, (seg_start, i-1, cur_strain))
            cur_strain = df.strain[i]
            seg_start = i
        end
    end
    push!(strain_segments, (seg_start, nrow(df), cur_strain))

    # Базовый график случаев
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

    # Зоны штаммов
    labeled_strains = Set{String}()
    for (i1, i2, s) in strain_segments
        c = strain_palette[s]
        lc = strain_line[s]
        lbl = s in labeled_strains ? false : s
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

        # Аннотация с названием штамма
        mid = dates[div(i1 + i2, 2)]
        Plots.annotate!(p, mid, ymax * 0.97,
            Plots.text(s, 8, :center, lc))
    end

    # Вторая ось для R0
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


"""
    plot_waves_gr(cases::DataFrame, country::Symbol,
                  smoothed_all::Dict{Symbol, Vector{Float64}},
                  minima_all::Dict{Symbol, Vector{Int}}) -> Plot

Строит график волн с зонами и сглаженной кривой.

Аргументы:
  - `cases`: DataFrame с колонкой случаев и волн
  - `country`: Symbol страны
  - `smoothed_all`: словарь сглаженных рядов (от assign_waves)
  - `minima_all`: словарь минимумов (от assign_waves)

Возвращает:
  Plot с:
    - исходные данные (серый фон)
    - зоны волн (цветной фон)
    - сглаженная кривая (красная линия)
    - вертикальные линии границ
    - точки минимумов
    - номера волн

Пример:
    p = plot_waves_gr(cases, :Россия, smoothed_all, minima_all)
    savefig(p, "waves_Россия.png")
"""
function plot_waves_gr(cases::DataFrame, country::Symbol,
                       smoothed_all::Dict{Symbol, Vector{Float64}},
                       minima_all::Dict{Symbol, Vector{Int}})
    
    smoothed = smoothed_all[country]
    minima = minima_all[country]
    raw = Float64.(cases[!, country])
    dates = cases.date
    wave_col = cases[!, Symbol(string(country) * "_волна")]
    n_waves = maximum(wave_col)

    # Цвета волн
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

    # Базовый график
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

    # Зоны волн
    for w in 1:n_waves
        i1 = boundaries[w]
        i2 = boundaries[w+1]
        c = wave_colors[mod1(w, length(wave_colors))]

        xs = [dates[i1], dates[i2]]
        Plots.plot!(p, xs, [ymax/2, ymax/2];
            ribbon    = ymax/2,
            fillcolor = c,
            fillalpha = 0.15,
            linewidth = 0,
            linealpha = 0,
            label     = false,
        )
    end

    # Сглаженная кривая
    Plots.plot!(p, dates, smoothed;
        label     = "Сглаженная (21 день)",
        color     = RGB(0.8, 0.1, 0.1),
        linewidth = 2.5,
    )

    # Вертикальные линии границ
    for m in minima
        vline!(p, [dates[m]];
            color     = RGBA(0, 0, 0, 0.3),
            linewidth = 1.0,
            linestyle = :dash,
            label     = false,
        )
    end

    # Точки минимумов
    if !isempty(minima)
        Plots.scatter!(p, dates[minima], smoothed[minima];
            color       = :black,
            markersize  = 6,
            markershape = :dtriangle,
            label       = "Границы волн",
        )
    end

    # Номера волн
    for w in 1:n_waves
        i1 = boundaries[w]
        i2 = boundaries[w+1]
        mid = dates[div(i1 + i2, 2)]
        val = maximum(smoothed[i1:i2]) * 0.85
        Plots.annotate!(p, mid, val,
            Plots.text("Волна $w", 9, :center,
                line_colors[mod1(w, length(line_colors))])
        )
    end

    return p
end


# ──────────────────────────────────────────────────────────────────────────────
# 8. ФУНКЦИИ ДЛЯ РАБОТЫ СО ШТАММАМИ
# ──────────────────────────────────────────────────────────────────────────────

"""
    get_variant_for_date(d::Date, variants::DataFrame) -> NamedTuple

Определяет активный штамм (или комбинацию) на заданную дату.

Аргументы:
  - `d`: дата для определения штамма
  - `variants`: DataFrame VARIANT_PARAMS или совместимый

Возвращает NamedTuple с полями:
  - strain: название штамма (или комбинация "A+B")
  - variant_rule: правило ("single:", "overlap:", "interpolate:")
  - R0_min, R0_max, R0: репродуктивное число (среднее для комбинаций)
  - incubation, infectious, CFR: биопараметры

Логика:
  1. Если дата внутри периода доминирования → single:Strain
  2. Если дата пересекает несколько периодов → overlap:Strain1+Strain2
  3. Если дата между периодами → interpolate:Prev+Next
  4. Если дата до первого периода → extend_left:First
  5. Если дата после последнего → last_only:Last

Пример:
    v = get_variant_for_date(Date("2021-07-15"), VARIANT_PARAMS)
    # v.strain => "Delta"
    # v.R0 => 6.5 (среднее из [5.0, 8.0])
"""
function get_variant_for_date(d::Date, variants::DataFrame)
    # Находим активные штаммы на дату
    active = findall(i -> variants.dominance_start[i] <= d <= variants.dominance_end[i], 
                     1:nrow(variants))

    if length(active) == 1
        # Один активный штамм
        i = active[1]
        r0min = variants.R0_min[i]
        r0max = variants.R0_max[i]
        r0 = (r0min + r0max) / 2
        inc = variants.incubation[i]
        inf = variants.infectious[i]
        cfr = variants.CFR[i]
        
        return (
            strain = String(variants.strain[i]),
            variant_rule = "single:" * String(variants.strain[i]),
            R0_min = r0min, R0_max = r0max, R0 = r0,
            incubation = inc, infectious = inf, CFR = cfr
        )
        
    elseif length(active) > 1
        # Перекрытие периодов доминирования
        names = String.(variants.strain[active])
        r0min = mean(variants.R0_min[active])
        r0max = mean(variants.R0_max[active])
        r0 = (r0min + r0max) / 2
        inc = mean(variants.incubation[active])
        inf = mean(variants.infectious[active])
        cfr = mean(variants.CFR[active])
        
        return (
            strain = join(names, "+"),
            variant_rule = "overlap:" * join(names, "+"),
            R0_min = r0min, R0_max = r0max, R0 = r0,
            incubation = inc, infectious = inf, CFR = cfr
        )
    end

    # Дата вне всех периодов — ищем ближайших соседей
    left = findall(i -> variants.dominance_end[i] < d, 1:nrow(variants))
    right = findall(i -> variants.dominance_start[i] > d, 1:nrow(variants))

    if !isempty(left) && !isempty(right)
        # Между периодами — интерполяция
        li = maximum(left)
        ri = minimum(right)
        names = [String(variants.strain[li]), String(variants.strain[ri])]
        r0min = mean([variants.R0_min[li], variants.R0_min[ri]])
        r0max = mean([variants.R0_max[li], variants.R0_max[ri]])
        r0 = (r0min + r0max) / 2
        inc = mean([variants.incubation[li], variants.incubation[ri]])
        inf = mean([variants.infectious[li], variants.infectious[ri]])
        cfr = mean([variants.CFR[li], variants.CFR[ri]])
        
        return (
            strain = join(names, "+"),
            variant_rule = "interpolate:" * join(names, "+"),
            R0_min = r0min, R0_max = r0max, R0 = r0,
            incubation = inc, infectious = inf, CFR = cfr
        )
        
    elseif !isempty(left)
        # После последнего периода — экстраполяция влево
        li = maximum(left)
        s = String(variants.strain[li]) * "+?"
        r0min = variants.R0_min[li]
        r0max = variants.R0_max[li]
        r0 = (r0min + r0max) / 2
        inc = variants.incubation[li]
        inf = variants.infectious[li]
        cfr = variants.CFR[li]
        
        return (
            strain = s,
            variant_rule = "extend_left:" * s,
            R0_min = r0min, R0_max = r0max, R0 = r0,
            incubation = inc, infectious = inf, CFR = cfr
        )
        
    else
        # До первого периода — экстраполяция вправо
        ri = minimum(right)
        s = String(variants.strain[ri])
        r0min = variants.R0_min[ri]
        r0max = variants.R0_max[ri]
        r0 = (r0min + r0max) / 2
        inc = variants.incubation[ri]
        inf = variants.infectious[ri]
        cfr = variants.CFR[ri]
        
        return (
            strain = s,
            variant_rule = "right_only:" * s,
            R0_min = r0min, R0_max = r0max, R0 = r0,
            incubation = inc, infectious = inf, CFR = cfr
        )
    end
end


"""
    annotate_variants!(cases::DataFrame, variants::DataFrame) -> DataFrame

Добавляет в DataFrame колонки с параметрами штаммов для каждой даты.

Аргументы:
  - `cases`: DataFrame с колонкой :date
  - `variants`: DataFrame VARIANT_PARAMS

Возвращает:
  cases с добавленными колонками:
    - strain, variant_rule
    - R0_min, R0_max, R0
    - incubation, infectious, CFR

Пример:
    cases = annotate_variants!(cases, VARIANT_PARAMS)
    CSV.write("cases_with_variants.csv", cases)
"""
function annotate_variants!(cases::DataFrame, variants::DataFrame)
    # Инициализируем колонки
    cases.strain = Vector{String}(undef, nrow(cases))
    cases.variant_rule = Vector{String}(undef, nrow(cases))
    cases.R0_min = Vector{Float64}(undef, nrow(cases))
    cases.R0_max = Vector{Float64}(undef, nrow(cases))
    cases.R0 = Vector{Float64}(undef, nrow(cases))
    cases.incubation = Vector{Float64}(undef, nrow(cases))
    cases.infectious = Vector{Float64}(undef, nrow(cases))
    cases.CFR = Vector{Float64}(undef, nrow(cases))

    # Заполняем для каждой даты
    for i in 1:nrow(cases)
        r = get_variant_for_date(cases.date[i], variants)
        cases.strain[i] = r.strain
        cases.variant_rule[i] = r.variant_rule
        cases.R0_min[i] = r.R0_min
        cases.R0_max[i] = r.R0_max
        cases.R0[i] = r.R0
        cases.incubation[i] = r.incubation
        cases.infectious[i] = r.infectious
        cases.CFR[i] = r.CFR
    end

    return cases
end


# ──────────────────────────────────────────────────────────────────────────────
# 9. ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ
# ──────────────────────────────────────────────────────────────────────────────

"""
    save_plot_with_theme(p::Plot, filename::String; 
                         theme::Symbol=:nature)

Сохраняет график с применением темы.

Аргументы:
  - `p`: Plot объект
  - `filename`: путь для сохранения (PNG, PDF, SVG)
  - `theme`: :nature (по умолчанию) или :light

Пример:
    p = plot(x, y, label="Data")
    save_plot_with_theme(p, "output.png", theme=:nature)
"""
function save_plot_with_theme(p::Plots.Plot, filename::String; 
                              theme::Symbol=:nature)
    if theme == :nature
        apply_nature_theme!()
    elseif theme == :light
        apply_light_theme()
    end
    
    Plots.savefig(p, filename)
    @info "График сохранён: $filename"
    
    return nothing
end


"""
    print_summary(df::DataFrame; n::Int=5)

Выводит краткую сводку DataFrame.

Аргументы:
  - `df`: DataFrame для анализа
  - `n`: количество строк для показа (первые и последние)

Пример:
    print_summary(cases)
"""
function print_summary(df::DataFrame; n::Int=5)
    println("╔══════════════════════════════════════════════════╗")
    println("│  Сводка данных                                   │")
    println("╠══════════════════════════════════════════════════╣")
    println("│  Строк: $(lpad(nrow(df), 5))")
    println("│  Колонки: $(ncol(df))")
    println("│  Имена: $(join(names(df), ", "))")
    
    if :date in names(df)
        println("│  Период: $(minimum(df.date)) — $(maximum(df.date))")
    end
    
    println("╚══════════════════════════════════════════════════╝")
    
    println("\nПервые $n строк:")
    display(first(df, n))
    
    println("\nПоследние $n строк:")
    display(last(df, n))
    
    return nothing
end


# ──────────────────────────────────────────────────────────────────────────────
# ЭКСПОРТ (для использования в других модулях)
# ──────────────────────────────────────────────────────────────────────────────
#
# Следующие символы доступны после include("utils.jl"):
#
# Константы:
#   COUNTRIES_WHO, COUNTRIES_SYMBOLS, VARIANT_PARAMS
#
# Настройки тем:
#   apply_nature_theme!, apply_light_theme
#
# Загрузка данных:
#   load_covid_daily, fill_daily_grid, interp_missing_linear,
#   rolling_mean, compute_daily_new
#
# Обнаружение волн:
#   find_wave_minima, assign_waves
#
# Выборка данных:
#   build_country_dict, select_wave
#
# Визуализация:
#   plot_wave_detail, plot_waves_gr, save_plot_with_theme
#
# Штаммы:
#   get_variant_for_date, annotate_variants!
#
# Утилиты:
#   print_summary
#
# ──────────────────────────────────────────────────────────────────────────────

# ──────────────────────────────────────────────────────────────────────────────
# 10. ОТЧЁТ ОБ ИСПОЛЬЗОВАНИИ ФУНКЦИЙ (USAGE REPORT)
# ──────────────────────────────────────────────────────────────────────────────
#
# Этот раздел содержит информацию о том, где и как используются функции
# из utils.jl в других файлах проекта.
#
# Для генерации HTML-отчёта выполните:
#   julia --project -e 'include("utils.jl"); generate_usage_report()'
#
# Отчёт будет сохранён в: utils_usage_report.html

"""
    USAGE_REGISTRY :: Dict{String, Vector{NamedTuple}}

Реестр использования функций проекта.
Заполняется автоматически при анализе файлов.

Формат:
  "function_name" => [
    (file="load_data.jl", line=38, context="covid_all_daily = load_covid_daily()"),
    ...
  ]
"""
const USAGE_REGISTRY = Dict(
    "load_covid_daily" => [
        (file="load_data.jl", line=38, context="covid_all_daily = load_covid_daily()"),
        (file="load_data.jl", line=109, context="covid_all_daily = load_covid_daily()"),
        (file="load_data2.jl", line=161, context="covid_all_daily = load_covid_daily()"),
        (file="utils.jl", line=289, context="Пример в docstring"),
    ],
    
    "fill_daily_grid" => [
        (file="load_data.jl", line=170, context="grid = fill_daily_grid(usa)"),
        (file="load_data.jl", line=224, context="grid = fill_daily_grid(country_df)"),
        (file="load_data2.jl", line=198, context="grid = fill_daily_grid(d)"),
        (file="utils.jl", line=354, context="Пример в docstring"),
    ],
    
    "interp_missing_linear" => [
        (file="load_data.jl", line=184, context="y_interp = interp_missing_linear(grid.Cumulative_cases)"),
        (file="load_data.jl", line=225, context="y_interp = interp_missing_linear(grid.Cumulative_cases)"),
        (file="load_data2.jl", line=199, context="y_cum = interp_missing_linear(grid.Cumulative_cases)"),
        (file="utils.jl", line=393, context="Пример в docstring"),
    ],
    
    "rolling_mean" => [
        (file="load_data.jl", line=194, context="y_interp2 = rolling_mean(y_interp, 7)"),
        (file="load_data.jl", line=207, context="y_interp2 = rolling_mean(y_interp, 7)"),
        (file="load_data.jl", line=212, context="daily_smooth = rolling_mean(daily, 7)"),
        (file="load_data.jl", line=226, context="y_interp_smooth = rolling_mean(y_interp, 7)"),
        (file="load_data.jl", line=228, context="daily_smooth = rolling_mean(daily, 7)"),
        (file="load_data2.jl", line=204, context="daily_smooth = rolling_mean(daily, 7)"),
        (file="waves_detection.jl", line=91, context="Определение локальной функции"),
        (file="waves_detection.jl", line=137, context="smoothed = rolling_mean(cases[!, country], window)"),
        (file="utils.jl", line=434, context="Пример в docstring"),
        (file="utils.jl", line=591, context="smoothed = rolling_mean(cases[!, country], window)"),
    ],
    
    "find_wave_minima" => [
        (file="waves_detection.jl", line=104, context="Определение функции"),
        (file="waves_detection.jl", line=138, context="minima = find_wave_minima(smoothed; ...)"),
        (file="utils.jl", line=514, context="Пример в docstring"),
        (file="utils.jl", line=594, context="minima = find_wave_minima(smoothed; ...)"),
    ],
    
    "assign_waves" => [
        (file="waves_detection.jl", line=132, context="Определение функции"),
        (file="waves_detection.jl", line=162, context="cases, sm, mn = assign_waves(cases, c; ...)"),
        (file="waves_detection.jl", line=319, context="assert ... запустите assign_waves()"),
        (file="seir modelling.jl", line=97, context="assert ... запустите assign_waves()"),
        (file="utils.jl", line=579, context="Пример в docstring"),
        (file="utils.jl", line=585, context="Определение функции"),
    ],
    
    "select_wave" => [
        (file="waves_detection.jl", line=310, context="Определение функции"),
        (file="waves_detection.jl", line=347, context="df = select_wave(cases, country_dict, 1, 2)"),
        (file="waves_detection.jl", line=351, context="df = select_wave(cases, country_dict, 5, 3)"),
        (file="waves_detection.jl", line=463, context="df = select_wave(cases, country_dict, 1, 2)"),
        (file="waves_detection.jl", line=469, context="df = select_wave(cases, country_dict, 5, 3)"),
        (file="seir modelling.jl", line=88, context="Определение функции"),
        (file="seir modelling.jl", line=223, context="df = select_wave(cases, country_dict, 1, 2)"),
        (file="utils.jl", line=672, context="Пример в docstring"),
        (file="utils.jl", line=677, context="Определение функции"),
    ],
    
    "plot_wave_detail" => [
        (file="waves_detection.jl", line=354, context="Определение функции"),
        (file="waves_detection.jl", line=465, context="p = plot_wave_detail(df, :Россия, 2)"),
        (file="waves_detection.jl", line=471, context="p = plot_wave_detail(df, :Индия, 3)"),
        (file="seir modelling.jl", line=114, context="Определение функции"),
        (file="seir modelling.jl", line=225, context="p = plot_wave_detail(df, :Россия, 2)"),
        (file="utils.jl", line=734, context="Пример в docstring"),
        (file="utils.jl", line=737, context="Определение функции"),
    ],
    
    "plot_waves_gr" => [
        (file="waves_detection.jl", line=177, context="Определение функции"),
        (file="waves_detection.jl", line=288, context="p = plot_waves_gr(cases, c, smoothed_all, minima_all)"),
        (file="utils.jl", line=876, context="Пример в docstring"),
        (file="utils.jl", line=879, context="Определение функции"),
    ],
    
    "get_variant_for_date" => [
        (file="waves_and_stamms.jl", line=141, context="Определение функции values_for_date"),
        (file="utils.jl", line=1018, context="Пример в docstring"),
        (file="utils.jl", line=1022, context="Определение функции"),
        (file="utils.jl", line=1156, context="r = get_variant_for_date(cases.date[i], variants)"),
    ],
    
    "annotate_variants!" => [
        (file="waves_and_stamms.jl", line=178, context="Заполнение колонок в цикле"),
        (file="utils.jl", line=1140, context="Пример в docstring"),
        (file="utils.jl", line=1143, context="Определение функции"),
    ],
)


"""
    print_usage_report()

Выводит текстовый отчёт об использовании функций в проекте.

Формат вывода:
  ┌────────────────────────────────────────────────────────────┐
  │  ОТЧЁТ ОБ ИСПОЛЬЗОВАНИИ ФУНКЦИЙ utils.jl                   │
  ├────────────────────────────────────────────────────────────┤
  │  Функция: load_covid_daily                                 │
  │  ───────────────────────────────────────────────────────── │
  │    • load_data.jl:38                                       │
  │      covid_all_daily = load_covid_daily()                  │
  │    • load_data.jl:109                                      │
  │      covid_all_daily = load_covid_daily()                  │
  │    • load_data2.jl:161                                     │
  │      covid_all_daily = load_covid_daily()                  │
  │  ...                                                       │
  └────────────────────────────────────────────────────────────┘
"""
function print_usage_report()
    println("\n" * "═"^70)
    println("  ОТЧЁТ ОБ ИСПОЛЬЗОВАНИИ ФУНКЦИЙ utils.jl")
    println("═"^70)
    
    for (func, usages) in sort(collect(USAGE_REGISTRY))
        println("\n  Функция: $func")
        println("  " * "─"^50)
        
        for u in usages
            println("    • $(u.file):$(u.line)")
            println("      $(u.context)")
        end
    end
    
    println("\n" * "═"^70)
    println("  ИТОГО: $(length(USAGE_REGISTRY)) функций")
    total_usages = sum(length(usages) for usages in values(USAGE_REGISTRY))
    println("  Всего использований: $total_usages")
    println("═"^70 * "\n")
    
    return nothing
end


"""
    generate_usage_report(; outfile::String="utils_usage_report.html")

Генерирует HTML-отчёт об использовании функций проекта.

Аргументы:
  - `outfile`: путь для сохранения HTML-файла

Формат отчёта:
  - Таблица с функциями и местами использования
  - Цветовая кодировка по типам файлов
  - Статистика: количество функций, вызовов, файлов
  - Графики: популярность функций, распределение по файлам

Пример:
    generate_usage_report()  # сохранит в utils_usage_report.html
    generate_usage_report(outfile="report.html")
"""
function generate_usage_report(; outfile::String="utils_usage_report.html")
    
    # Собираем статистику
    all_files = Set{String}()
    for usages in values(USAGE_REGISTRY)
        for u in usages
            push!(all_files, u.file)
        end
    end
    
    func_stats = [(func=length(usages), calls=length(usages)) for (f, usages) in USAGE_REGISTRY]
    
    html = """
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Отчёт об использовании utils.jl</title>
    <style>
        :root {
            --primary: #0072B5;
            --secondary: #E69F02;
            --success: #009E73;
            --danger: #D55E00;
            --info: #56B4E9;
            --purple: #CC79A7;
            --dark: #000000;
            --light: #f8f9fa;
            --border: #dee2e6;
        }
        
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, 
                         "Helvetica Neue", Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            background: var(--light);
            padding: 2rem;
        }
        
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        
        header {
            background: linear-gradient(135deg, var(--primary), #005a8f);
            color: white;
            padding: 2rem;
            border-radius: 8px;
            margin-bottom: 2rem;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        
        header h1 {
            font-size: 2rem;
            margin-bottom: 0.5rem;
        }
        
        header p {
            opacity: 0.9;
            font-size: 1rem;
        }
        
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 1rem;
            margin-bottom: 2rem;
        }
        
        .stat-card {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            text-align: center;
            border-left: 4px solid var(--primary);
        }
        
        .stat-card h3 {
            font-size: 2.5rem;
            color: var(--primary);
            margin-bottom: 0.5rem;
        }
        
        .stat-card p {
            color: #666;
            font-size: 0.9rem;
            text-transform: uppercase;
            letter-spacing: 1px;
        }
        
        .stat-card:nth-child(2) { border-left-color: var(--secondary); }
        .stat-card:nth-child(2) h3 { color: var(--secondary); }
        
        .stat-card:nth-child(3) { border-left-color: var(--success); }
        .stat-card:nth-child(3) h3 { color: var(--success); }
        
        section {
            background: white;
            padding: 1.5rem;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            margin-bottom: 2rem;
        }
        
        section h2 {
            color: var(--primary);
            margin-bottom: 1rem;
            padding-bottom: 0.5rem;
            border-bottom: 2px solid var(--border);
        }
        
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 1rem;
        }
        
        th, td {
            padding: 0.75rem;
            text-align: left;
            border-bottom: 1px solid var(--border);
        }
        
        th {
            background: var(--light);
            font-weight: 600;
            color: #555;
            text-transform: uppercase;
            font-size: 0.85rem;
            letter-spacing: 0.5px;
        }
        
        tr:hover {
            background: #f8f9fa;
        }
        
        .func-name {
            font-family: "Consolas", "Monaco", monospace;
            background: var(--light);
            padding: 0.25rem 0.5rem;
            border-radius: 4px;
            color: var(--primary);
            font-weight: 600;
        }
        
        .file-badge {
            display: inline-block;
            padding: 0.25rem 0.75rem;
            border-radius: 20px;
            font-size: 0.8rem;
            font-weight: 500;
            margin-right: 0.25rem;
            margin-bottom: 0.25rem;
        }
        
        .file-load_data { background: #e3f2fd; color: #1565c0; }
        .file-load_data2 { background: #fff3e0; color: #ef6c00; }
        .file-waves_detection { background: #f3e5f5; color: #7b1fa2; }
        .file-waves_and_stamms { background: #e8f5e9; color: #2e7d32; }
        .file-seir_modelling { background: #fce4ec; color: #c2185b; }
        .file-seird_pipeline { background: #e0f7fa; color: #00838f; }
        .file-utils { background: #f5f5f5; color: #616161; }
        
        .usage-context {
            font-family: "Consolas", "Monaco", monospace;
            font-size: 0.85rem;
            background: #263238;
            color: #aed581;
            padding: 0.5rem;
            border-radius: 4px;
            margin-top: 0.25rem;
            overflow-x: auto;
        }
        
        .line-num {
            color: #999;
            font-size: 0.8rem;
        }
        
        .chart-container {
            margin-top: 1rem;
            padding: 1rem;
            background: var(--light);
            border-radius: 4px;
        }
        
        .bar-chart {
            display: flex;
            flex-direction: column;
            gap: 0.5rem;
        }
        
        .bar-row {
            display: flex;
            align-items: center;
            gap: 1rem;
        }
        
        .bar-label {
            min-width: 150px;
            font-family: monospace;
            font-size: 0.9rem;
            color: #555;
        }
        
        .bar-track {
            flex: 1;
            height: 24px;
            background: #e0e0e0;
            border-radius: 4px;
            overflow: hidden;
        }
        
        .bar-fill {
            height: 100%;
            background: linear-gradient(90deg, var(--primary), var(--info));
            border-radius: 4px;
            transition: width 0.3s ease;
        }
        
        .bar-value {
            min-width: 40px;
            text-align: right;
            font-weight: 600;
            color: #333;
        }
        
        footer {
            text-align: center;
            padding: 2rem;
            color: #666;
            font-size: 0.9rem;
        }
        
        @media print {
            body { background: white; padding: 0; }
            header { background: #0072B5; }
            section { box-shadow: none; border: 1px solid #ddd; }
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📊 Отчёт об использовании utils.jl</h1>
            <p>Анализ вызовов функций в проекте SEIR/SEIRD моделирования COVID-19</p>
        </header>
        
        <div class="stats-grid">
            <div class="stat-card">
                <h3>$(length(USAGE_REGISTRY))</h3>
                <p>Функций в реестре</p>
            </div>
            <div class="stat-card">
                <h3>$(sum(length(usages) for usages in values(USAGE_REGISTRY)))</h3>
                <p>Всего вызовов</p>
            </div>
            <div class="stat-card">
                <h3>$(length(all_files))</h3>
                <p>Файлов проекта</p>
            </div>
        </div>
        
        <section>
            <h2>📈 Популярность функций</h2>
            <div class="chart-container">
                <div class="bar-chart">
"""
    
    # Сортируем функции по количеству использований
    sorted_funcs = sort(collect(USAGE_REGISTRY), by=x->length(x[2]), rev=true)
    max_calls = maximum(length(usages) for usages in values(USAGE_REGISTRY))
    
    for (func, usages) in sorted_funcs
        pct = length(usages) / max_calls * 100
        html *= """
                    <div class="bar-row">
                        <span class="bar-label">$func</span>
                        <div class="bar-track">
                            <div class="bar-fill" style="width: $(pct)%"></div>
                        </div>
                        <span class="bar-value">$(length(usages))</span>
                    </div>
        """
    end
    
    html *= """
                </div>
            </div>
        </section>
        
        <section>
            <h2>📁 Файлы проекта</h2>
            <table>
                <thead>
                    <tr>
                        <th>Файл</th>
                        <th>Описание</th>
                        <th>Использует функций</th>
                    </tr>
                </thead>
                <tbody>
"""
    
    file_descriptions = Dict(
        "load_data.jl" => "Загрузка WHO данных, предобработка",
        "load_data2.jl" => "Альтернативный загрузчик данных",
        "waves_detection.jl" => "Обнаружение волн, визуализация",
        "waves_and_stamms.jl" => "Параметры штаммов, timeline",
        "seir modelling.jl" => "Анализ отдельных волн",
        "seird_pipeline.jl" => "Классическая + дробная SEIRD",
        "utils.jl" => "Общие утилиты (этот файл)",
    )
    
    for file in sort(collect(all_files))
        # Считаем сколько уникальных функций используется в файле
        funcs_in_file = Set{String}()
        for (func, usages) in USAGE_REGISTRY
            for u in usages
                if u.file == file
                    push!(funcs_in_file, func)
                end
            end
        end
        
        desc = get(file_descriptions, file, "—")
        file_class = replace(file, ".jl" => "", " " => "_")
        
        html *= """
                    <tr>
                        <td><span class="file-badge file-$file_class">$file</span></td>
                        <td>$desc</td>
                        <td>$(length(funcs_in_file))</td>
                    </tr>
        """
    end
    
    html *= """
                </tbody>
            </table>
        </section>
        
        <section>
            <h2>🔧 Детальный разбор функций</h2>
            <table>
                <thead>
                    <tr>
                        <th>Функция</th>
                        <th>Места использования</th>
                    </tr>
                </thead>
                <tbody>
"""
    
    for (func, usages) in sorted_funcs
        html *= """
                    <tr>
                        <td><span class="func-name">$func</span></td>
                        <td>
"""
        for u in usages
            file_class = replace(u.file, ".jl" => "", " " => "_")
            html *= """
                            <div style="margin-bottom: 0.75rem;">
                                <span class="file-badge file-$file_class">$(u.file)</span>
                                <span class="line-num">строка $(u.line)</span>
                                <div class="usage-context">$(u.context)</div>
                            </div>
"""
        end
        html *= """
                        </td>
                    </tr>
"""
    end
    
    html *= """
                </tbody>
            </table>
        </section>
        
        <footer>
            <p>Сгенерировано: $(Dates.now()) | Проект: matlabSEIR | utils.jl</p>
        </footer>
    </div>
</body>
</html>
"""
    
    # Сохраняем HTML
    write(outfile, html)
    @info "HTML-отчёт сохранён: $outfile"
    
    return outfile
end


# ──────────────────────────────────────────────────────────────────────────────
# АВТОМАТИЧЕСКИЙ ВЫВОД ПРИ ЗАГРУЗКЕ
# ──────────────────────────────────────────────────────────────────────────────

@info "utils.jl загружен: $(length(USAGE_REGISTRY)) функций в реестре"
@info "Для вывода отчёта: print_usage_report()"
@info "Для HTML-отчёта: generate_usage_report()"

# Сигнал успешной загрузки
@info "utils.jl загружен: $(length(methods(rolling_mean))) функций доступно"
