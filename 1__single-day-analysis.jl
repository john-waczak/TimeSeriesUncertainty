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


parse_datetime!(df_ips)
parse_datetime!(df_bme280)
parse_datetime!(df_bme680)


# let's now find out the correct sample rate for each sensor and round the DateTimes accordingly
Δt_ips = mean([(df_ips.dateTime[i+1] - df_ips.dateTime[i]).value for i ∈ 1:(nrow(df_ips)-1)])./1000
Δt_bme280 = mean([(df_bme280.dateTime[i+1] - df_bme280.dateTime[i]).value for i ∈ 1:(nrow(df_bme280)-1)])./1000
Δt_bme680 = mean([(df_bme680.dateTime[i+1] - df_bme680.dateTime[i]).value for i ∈ 1:(nrow(df_bme680)-1)])./1000

println("mean IPS7100 Δt: ", Δt_ips, " (s)")
println("mean BME280 Δt: ", Δt_bme280, " (s)")
println("mean BME680 Δt: ", Δt_bme680, " (s)")

# so, 1 Hz for IPS7100 and 0.1 Hz for BME680, BME280
df_ips.dateTime = round.(df_ips.dateTime, Second(1))
df_bme280.dateTime = round.(df_bme280.dateTime, Second(10))
df_bme680.dateTime = round.(df_bme680.dateTime, Second(10))

# let's construct some histograms of differences

hist([v.value for v ∈ df_ips.dateTime[2:end] .- df_ips.dateTime[1:end-1]]./1000)
hist([v.value for v ∈ df_bme280.dateTime[2:end] .- df_bme280.dateTime[1:end-1]]./1000)
hist([v.value for v ∈ df_bme680.dateTime[2:end] .- df_bme680.dateTime[1:end-1]]./1000)

# so clearly we don't have "nice" data. Our variogram probably shouldn't assume uniform spacing

# let's add a column for each 10 minute window. We can compute the variogram, representativeness, etc for each window
df_ips.minutes_10 = [(round(df_ips.dateTime[i] - df_ips.dateTime[1], Minute(90))).value for i ∈ 1:nrow(df_ips)]
df_bme280.minutes_10 = [(round(df_bme280.dateTime[i] - df_bme280.dateTime[1], Minute(90))).value for i ∈ 1:nrow(df_bme280)]
df_bme680.minutes_10 = [(round(df_bme680.dateTime[i] - df_bme680.dateTime[1], Minute(90))).value for i ∈ 1:nrow(df_bme680)]

# add another column for seconds since start
df_ips.s_since_start = [(df_ips.dateTime[i] - df_ips.dateTime[1]).value / 1000 for i ∈ 1:nrow(df_ips)]
df_bme280.s_since_start = [(df_bme280.dateTime[i] - df_bme280.dateTime[1]).value / 1000 for i ∈ 1:nrow(df_bme280)]
df_bme680.s_since_start = [(df_bme680.dateTime[i] - df_bme680.dateTime[1]).value / 1000 for i ∈ 1:nrow(df_bme680)]


# group the dfs by the minutes_10 column
gdf_ips = groupby(df_ips, :minutes_10)




Zs = gdf_ips[1].pm2_5
ts = gdf_ips[1].s_since_start


function iuppert(k::Int,n::Int)
    i = n - 1 - floor(Int,sqrt(-8*k + 4*n*(n-1) + 1)/2 - 0.5)
    j = k + i + ( (n-i+1)*(n-i) - n*(n-1) )÷2
    return i, j
end

function make_pairs(N)
    ij_pairs = zeros(Int, Int(N*(N-1)/2), 2)

    Threads.@threads for k ∈ 1:Int(N*(N-1)/2)
        @inbounds ij_pairs[k, 1] = N - 1 - floor(Int,sqrt(-8*k + 4*N*(N-1) + 1)/2 - 0.5)
        @inbounds ij_pairs[k, 2] = k + ij_pairs[k,1] + ( (N-ij_pairs[k,1]+1)*(N-ij_pairs[k,1]) - N*(N-1) )÷2
    end
    return ij_pairs
end

# @benchmark ij_pairs = make_pairs(N)

Nmin = 20

N = length(ts)
ij_pairs = make_pairs(N)

# compute time lags

Δts = abs.(ts[ij_pairs[:,1]] .- ts[ij_pairs[:,2]])
lag_vals = unique(Δts)

lag_vals

ks = findall(Δts .== 1.0)




# add the values from our bins
hs = Float64[]
γs = Float64[]
for Δt ∈ lag_vals
    if Δt > 0
        ks = findall(Δts .== Δt)
        if length(ks) > Nmin
            push!(γs, mean((Zs[ij_pairs[ks, 1]] .- Zs[ij_pairs[ks,2]]).^2)/2)
            push!(hs, Δt)
        end
    end
end


scatter(hs./60, γs)



# round time lag to nearest Δt?
unique(Δts)

# sort keeping all lags with minimum number of points
N_per_bin = 30







for (key, df) ∈ pairs(gdf_ips)
    println(key)
end


function semivariogram(ts; lag_ratio=0.5, lag_max=100.0)
end



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


