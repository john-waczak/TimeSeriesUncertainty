using CSV, DataFrames
using Statistics
using Unitful
using Dates, TimeZones
using BenchmarkTools

using CairoMakie
using MintsMakieRecipes
set_theme!(mints_theme)
update_theme!(
    figure_padding=30,
    Axis=(
        xticklabelsize=20,
        yticklabelsize=20,
        xlabelsize=22,
        ylabelsize=22,
        titlesize=25,
    ),
    Colorbar=(
        ticklabelsize=20,
        labelsize=22
    )
)


using Pkg
Pkg.add(url="https://github.com/john-waczak/TimeSeriesTools.jl.git")
using TimeSeriesTools
using ParameterHandling


include("utils/df_utils.jl")
include("utils/variograms.jl")


basepath = "/media/jwaczak/Data/aq-data/raw"
outpath = "/media/jwaczak/Data/aq-data/processed"
if !ispath(outpath)
    mkpath(outpath)
end




datapath_ips = joinpath(basepath, "IPS7100", "Central_Hub_1")
datapath_bme680= joinpath(basepath, "BME680", "Central_Hub_1")
datapath_bme280= joinpath(basepath, "BME280", "Central_Hub_1")

@assert ispath(datapath_ips)
@assert ispath(datapath_bme680)
@assert ispath(datapath_bme280)





# let's fetch files foe each type
year = "2022"
month = "06"
day = "20"


ips_paths = joinpath.(datapath_ips, year, month, day, readdir(joinpath(datapath_ips, year, month, day)))
bme280_paths = joinpath.(datapath_bme280, year, month, day, readdir(joinpath(datapath_bme280, year, month, day)))
bme680_paths = joinpath.(datapath_bme680, year, month, day, readdir(joinpath(datapath_bme680, year, month, day)))

@assert all(ispath.(ips_paths))
@assert all(ispath.(bme280_paths))
@assert all(ispath.(bme680_paths))

df_ips = CSV.read(ips_paths[1], DataFrame; types=ips_types)
df_bme280 = CSV.read(bme280_paths[1], DataFrame; types=bme280_types)
df_bme680 = CSV.read(bme680_paths[1], DataFrame; types=bme680_types)


# 1 Hz for IPS7100 and 0.1 Hz for BME680, BME280
# df_ips.dateTime = round.(df_ips.dateTime, Second(1))
# df_bme280.dateTime = round.(df_bme280.dateTime, Second(10))
# df_bme680.dateTime = round.(df_bme680.dateTime, Second(10))



df_out = process_ips7100(df_ips)




for (key, df) ∈ pairs(gdf_ips)
    println(key)
end



# group the dfs by the minutes_10 column
gdf_ips = groupby(df_out, :datetime_quarterhour)
Zs = gdf_ips[2].pm2_5[:]
# Zs = df_ips.pm2_5[:]
Δt = 1.0
length(Zs) ./ 60
ts
60*60/Δt
length(Zs) * Δt

γ, h = semivariogram(Zs, Δt; lag_max=5*60, lag_ratio=1.0)
scatter(h ./ (60 ), γ)








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


