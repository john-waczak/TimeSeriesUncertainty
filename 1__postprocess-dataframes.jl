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


ips_failures = []
bme680_failures = []
bme280_failures = []

@info "Processing IPS7100 Data Files"
p = Progress(length(ips_paths))
Threads.@threads for i∈ 1:length(ips_paths)
    fpath = ips_paths[i]
    try
        df = CSV.read(fpath, DataFrame; types=ips_types, silencewarnings=true)
        select!(df, ips_columns)
        parse_datetime!(df)
        dropmissing!(df)
        df_out = process_ips7100(df)

        add_ips_uncertainty!(df_out)

        outpath = replace(fpath, "raw" => "processed")

        outdir, _ = splitdir(outpath)
        if !ispath(outdir)
            mkpath(outdir)
        end

        CSV.write(outpath, df_out)
    catch e
        println("$(fpath) failed!")
        println(e)
        push!(ips_failures, fpath)
    end
    next!(p)
end
finish!(p)


@info "Processing BME680 Data Files"
p = Progress(length(bme680_paths))
Threads.@threads for i ∈ 1:length(bme680_paths)
    fpath = bme680_paths[i]
    try
        df = CSV.read(fpath, DataFrame; types=bme680_types, silencewarnings=true)
        select!(df, bme680_columns)
        parse_datetime!(df)
        dropmissing!(df)
        df_out = process_bme680(df)

        add_bme680_uncertinaty!(df_out)

        outpath = replace(fpath, "raw" => "processed")

        outdir, _ = splitdir(outpath)
        if !ispath(outdir)
            mkpath(outdir)
        end


        CSV.write(outpath, df_out)
    catch e
        println("$(fpath) failed!")
        println(e)
        push!(bme680_failures, fpath)
    end
    next!(p)
end
finish!(p)



@info "Processing BME280 Data Files"
p = Progress(length(bme280_paths))
Threads.@threads for i ∈ 1:length(bme280_paths)
    fpath = bme280_paths[i]
    try
        df = CSV.read(fpath, DataFrame; types=bme280_types, silencewarnings=true)
        select!(df, bme280_columns)
        parse_datetime!(df)
        dropmissing!(df)
        df_out = process_bme280(df)

        add_bme280_uncertainty!(df_out)

        outpath = replace(fpath, "raw" => "processed")

        outdir, _ = splitdir(outpath)
        if !ispath(outdir)
            mkpath(outdir)
        end

        CSV.write(outpath, df_out)
    catch e
        println("$(fpath) failed!")
        println(e)
        push!(bme280_failures, fpath)
    end
    next!(p)
end
finish!(p)


println("N ips failures: ", length(ips_failures))
println("N bme680 failures: ", length(bme680_failures))
println("N bme280 failures: ", length(bme280_failures))


