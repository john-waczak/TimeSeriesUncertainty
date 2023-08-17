using CSV, DataFrames
using Statistics
using TimeSeriesTools
using Unitful
using Dates, TimeZones
using CairoMakie
using ParameterHandling

include("utils/df_utils.jl")

basepath = "data/sharedair/raw"
@assert ispath(basepath)

outpath = "data/sharedair/processed"
if !ispath(outpath)
    mkpath(outpath)
end

nodes_to_use = ["Central_Hub_1", "Central_Hub_2", "Central_Hub_4"]
sensors_to_use = ["IPS7100", "BME680"]

data_paths = Dict()
for node ∈ nodes_to_use
    data_paths[node] = Dict()
    for sensor ∈ sensors_to_use
        data_paths[node][sensor] = joinpath.(basepath, node, sensor, [f for f ∈ readdir(joinpath(basepath, node, sensor)) if endswith(f, ".csv")])
    end
end


path_ips = data_paths["Central_Hub_1"]["IPS7100"][2]
path_bme = data_paths["Central_Hub_1"]["BME680"][2]

df_ips = CSV.read(path_ips, DataFrame; types=col_types_ips)
df_ips.dateTime = ZonedDateTime.(df_ips.dateTime)

df_bme = CSV.read(path_bme, DataFrame;types=col_types_bme)
df_bme.dateTime = ZonedDateTime.(df_bme.dateTime)


# use PM 1.0, 2.5, 10.0 as examples:
typeof(df_ips.pm0_1) <: AbstractVector



Zpm1 = RegularTimeSeries(
    df_ips.pm1_0,
    1.0,
    u"μg/m^3",
    u"s",
    df_ips.dateTime[1]
)

Zpm25 = RegularTimeSeries(
    df_ips.pm2_5,
    1.0,
    u"μg/m^3",
    u"s",
    df_ips.dateTime[1]
)


Zpm10 = RegularTimeSeries(
    df_ips.pm10_0,
    1.0,
    u"μg/m^3",
    u"s",
    df_ips.dateTime[1]
)

Ztemp = RegularTimeSeries(
    df_bme.temperature,
    10.0,
    u"°C",
    u"s",
    df_bme.dateTime[1]
)


f = Figure()
ax = Axis(f[1,1], xlabel="time / (hour)\n$(Date(Zpm1.start_time))", ylabel="concentration / (μgm⁻³)")
pm10=lines!(ax, times(Zpm10)./(60*60), Zpm10.z)
pm25=lines!(ax, times(Zpm25)./(60*60), Zpm25.z)
pm1=lines!(ax, times(Zpm1)./(60*60), Zpm1.z)
leg = axislegend(ax, [pm1, pm25, pm10], ["PM 1.0", "PM 2.5", "PM 10.0"])
f

figures_path = "paper/figures/single-day"
if !ispath(figures_path)
    mkpath(figures_path)
end

save(joinpath(figures_path, "IPS_single-day.png"), f)
save(joinpath(figures_path, "IPS_single-day.pdf"), f)
save(joinpath(figures_path, "IPS_single-day.eps"), f)

f = Figure()
ax = Axis(f[1,1], xlabel="time / (hour)\n$(Date(Ztemp.start_time))", ylabel="Temperature / (°C)")
temp=lines!(ax, times(Ztemp)./(60*60), Ztemp.z)
f

save(joinpath(figures_path, "BME_single-day.png"), f)
save(joinpath(figures_path, "BME_single-day.pdf"), f)
save(joinpath(figures_path, "BME_single-day.eps"), f)



function fit_my_variograms(Z, name)
    γ, h = semivariogram(Z, lag_max=15*60)

    # γ_params = get_reasonable_params(γ,h)
    # θ₀, unflatten = ParameterHandling.value_flatten(γ_params)
    # θ = unflatten(θ₀)

    idx_fit = (h ./ 60.0) .≤ 10.0


    γ_fit_spherical = fit_γ(h[idx_fit], γ[idx_fit]; method=:spherical)
    γ_fit_exponential = fit_γ(h[idx_fit], γ[idx_fit]; method=:exponential)
    γ_fit_gaussian = fit_γ(h[idx_fit], γ[idx_fit]; method=:gaussian)
    γ_fit_circular = fit_γ(h[idx_fit], γ[idx_fit]; method=:circular)
    γ_fit_cubic = fit_γ(h[idx_fit], γ[idx_fit]; method=:cubic)
    γ_fit_linear = fit_γ(h[idx_fit], γ[idx_fit]; method=:linear)
    γ_fit_pentaspherical = fit_γ(h[idx_fit], γ[idx_fit]; method=:pentaspherical)
    γ_fit_sinehole = fit_γ(h[idx_fit], γ[idx_fit]; method=:sinehole)

    println("\t...plotting")
    fig = Figure()
    ax = Axis(
        fig[1,1],
        xlabel = "Δt (minutes)",
        ylabel = "γ(Δt)",
        title = "Variogram fit for $(name)"
    )

    s1 = scatter!(
        ax,
        h[idx_fit] ./ 60.0,
        γ[idx_fit],
        color=(:gray, 0.75),
        markersize = 8,
    )

    p1 = lines!(
        h[idx_fit] ./ 60.0,
        γ_fit_spherical.(h[idx_fit]),
        linewidth=3,
    )

    p2 = lines!(
        h[idx_fit] ./ 60.0,
        γ_fit_exponential.(h[idx_fit]),
        linewidth=3,
    )

    p3 = lines!(
        h[idx_fit] ./ 60.0,
        γ_fit_gaussian.(h[idx_fit]),
        linewidth=3,
    )

    p4 = lines!(
        h[idx_fit] ./ 60.0,
        γ_fit_circular.(h[idx_fit]),
        linewidth=3,
    )

    p5 = lines!(
        h[idx_fit] ./ 60.0,
        γ_fit_cubic.(h[idx_fit]),
        linewidth=3,
    )

    p6 = lines!(
        h[idx_fit] ./ 60.0,
        γ_fit_linear.(h[idx_fit]),
        linewidth=3,
    )

    p7 = lines!(
        h[idx_fit] ./ 60.0,
        γ_fit_pentaspherical.(h[idx_fit]),
        linewidth=3,
    )

    p8 = lines!(
        h[idx_fit] ./ 60.0,
        γ_fit_sinehole.(h[idx_fit]),
        linewidth=3,
    )

    L = axislegend(
        ax,
        [s1, p1, p2, p3, p4, p5, p6, p7, p8],
        ["empirical", "spherical model", "exponential model", "gaussian model", "circular model", "cubic model", "linear model", "pentaspherical model", "sine hole model"];
        position=:rc
    )

    save(joinpath(figures_path, "γ-$(name)_single-day.png"), fig)
    save(joinpath(figures_path, "γ-$(name)_single-day.eps"), fig)
    save(joinpath(figures_path, "γ-$(name)_single-day.pdf"), fig)

end


Zs = [Zpm1, Zpm25, Zpm10, Ztemp]
varnames = ["PM 1.0", "PM 2.5", "PM 10.0", "Temperature"]

for i ∈ 1:length(Zs)
    let
        Z = Zs[i]
        varname = varnames[i]
        fit_my_variograms(Z, varname)
    end
end


