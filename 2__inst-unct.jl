using CSV, DataFrames
using Statistics
using Unitful
using Dates, TimeZones
using BenchmarkTools
using ProgressMeter

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

include("utils/df_utils.jl")


basepath = "/media/jwaczak/Data/aq-data/processed"
ips_paths = String[]
bme680_paths = String[]
bme280_paths = String[]

for (root, dirs, files) ∈ walkdir(basepath)
    for file ∈ files
        if endswith(file, ".csv")
            if occursin("IPS7100", file)
                push!(ips_paths, joinpath(root, file))
            elseif occursin("BME680", file)
                push!(bme680_paths, joinpath(root, file))
            elseif occursin("BME280", file)
                push!(bme280_paths, joinpath(root, file))
            else
                continue
            end
        end
    end
end


# create functions for adding in instrument uncertainty...




# for (key, df) ∈ pairs(gdf_ips)
#     println(key)
# end



# # group the dfs by the minutes_10 column
# gdf_ips = groupby(df_out, :datetime_quarterhour)
# Zs = gdf_ips[2].pm2_5[:]
# # Zs = df_ips.pm2_5[:]
# Δt = 1.0
# length(Zs) ./ 60
# ts
# 60*60/Δt
# length(Zs) * Δt

# γ, h = semivariogram(Zs, Δt; lag_max=5*60, lag_ratio=1.0)
# scatter(h ./ (60 ), γ)








# function fit_my_variograms(Z, name)
#     γ, h = semivariogram(Z, lag_max=15*60)

#     # γ_params = get_reasonable_params(γ,h)
#     # θ₀, unflatten = ParameterHandling.value_flatten(γ_params)
#     # θ = unflatten(θ₀)

#     idx_fit = (h ./ 60.0) .≤ 10.0


#     γ_fit_spherical = fit_γ(h[idx_fit], γ[idx_fit]; method=:spherical)
#     γ_fit_exponential = fit_γ(h[idx_fit], γ[idx_fit]; method=:exponential)
#     γ_fit_gaussian = fit_γ(h[idx_fit], γ[idx_fit]; method=:gaussian)
#     γ_fit_circular = fit_γ(h[idx_fit], γ[idx_fit]; method=:circular)
#     γ_fit_cubic = fit_γ(h[idx_fit], γ[idx_fit]; method=:cubic)
#     γ_fit_linear = fit_γ(h[idx_fit], γ[idx_fit]; method=:linear)
#     γ_fit_pentaspherical = fit_γ(h[idx_fit], γ[idx_fit]; method=:pentaspherical)
#     γ_fit_sinehole = fit_γ(h[idx_fit], γ[idx_fit]; method=:sinehole)

#     println("\t...plotting")
#     fig = Figure()
#     ax = Axis(
#         fig[1,1],
#         xlabel = "Δt (minutes)",
#         ylabel = "γ(Δt)",
#         title = "Variogram fit for $(name)"
#     )

#     s1 = scatter!(
#         ax,
#         h[idx_fit] ./ 60.0,
#         γ[idx_fit],
#         color=(:gray, 0.75),
#         markersize = 8,
#     )

#     p1 = lines!(
#         h[idx_fit] ./ 60.0,
#         γ_fit_spherical.(h[idx_fit]),
#         linewidth=3,
#     )

#     p2 = lines!(
#         h[idx_fit] ./ 60.0,
#         γ_fit_exponential.(h[idx_fit]),
#         linewidth=3,
#     )

#     p3 = lines!(
#         h[idx_fit] ./ 60.0,
#         γ_fit_gaussian.(h[idx_fit]),
#         linewidth=3,
#     )

#     p4 = lines!(
#         h[idx_fit] ./ 60.0,
#         γ_fit_circular.(h[idx_fit]),
#         linewidth=3,
#     )

#     p5 = lines!(
#         h[idx_fit] ./ 60.0,
#         γ_fit_cubic.(h[idx_fit]),
#         linewidth=3,
#     )

#     p6 = lines!(
#         h[idx_fit] ./ 60.0,
#         γ_fit_linear.(h[idx_fit]),
#         linewidth=3,
#     )

#     p7 = lines!(
#         h[idx_fit] ./ 60.0,
#         γ_fit_pentaspherical.(h[idx_fit]),
#         linewidth=3,
#     )

#     p8 = lines!(
#         h[idx_fit] ./ 60.0,
#         γ_fit_sinehole.(h[idx_fit]),
#         linewidth=3,
#     )

#     L = axislegend(
#         ax,
#         [s1, p1, p2, p3, p4, p5, p6, p7, p8],
#         ["empirical", "spherical model", "exponential model", "gaussian model", "circular model", "cubic model", "linear model", "pentaspherical model", "sine hole model"];
#         position=:rc
#     )

#     save(joinpath(figures_path, "γ-$(name)_single-day.png"), fig)
#     save(joinpath(figures_path, "γ-$(name)_single-day.eps"), fig)
#     save(joinpath(figures_path, "γ-$(name)_single-day.pdf"), fig)

# end


# Zs = [Zpm1, Zpm25, Zpm10, Ztemp]
# varnames = ["PM 1.0", "PM 2.5", "PM 10.0", "Temperature"]

# for i ∈ 1:length(Zs)
#     let
#         Z = Zs[i]
#         varname = varnames[i]
#         fit_my_variograms(Z, varname)
#     end
# end


