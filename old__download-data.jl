# include("utils/df_utils.jl")
# date2datetime("2022-08-09 15:21:01.786747")

using Distributed, ClusterManagers

if "SLURM_JOBID" ∈ keys(ENV)
    @info "Working on a slurm cluster"
    addprocs_slurm(parse(Int, ENV["SLURM_NTASKS"])-1, exeflags="--project=$(Base.active_project())")
else
    @info "Working locally"
    addprocs(Threads.nthreads(), exeflags="--project=$(Base.active_project())")
end


# using Dagger


# add relevant packages
@everywhere begin
    using Pkg
    println("Activating Environment")
    println(Pkg.status())
    Pkg.activate(".")
    println("Instantiating")
    Pkg.instantiate()
    println("Precompiling")
    Pkg.precompile()

    println("Importing Packages")
    using Distributed
    using CSV, DataFrames
    using ProgressMeter

    println("Finished Importing...")
end


outpath = "data/sharedair/raw"

println("Data output path: ", outpath)
if !ispath(outpath)
    println("Creating output directory")
    mkpath(outpath)
end

@everywhere outpath = "data/sharedair/raw"


@everywhere begin
    # load in functionality for AWSS3
    include("utils/osn_anonymous.jl")
    include("utils/df_utils.jl")

    endpoint = "https://ncsa.osn.xsede.org"
    bucket = "s3://ees230012-bucket01"

    # configure AWS.jl to use our OSN configuration
    AWS.global_aws_config(AnonymousOSN(endpoint))

end




nodes_to_use = ["Central_Hub_1", "Central_Hub_2", "Central_Hub_4"]
years_to_use = ["2022", "2023"]
months = [lpad(i, 2, "0") for i ∈ 1:12]
days = [lpad(i, 2, "0") for i ∈ 1:31]
sensors_to_use = ["IPS7100", "BME680"]

@everywhere sensors_to_use = ["IPS7100", "BME680"]

for node ∈ nodes_to_use
  for sensor ∈ sensors_to_use
      if !ispath(joinpath(outpath, node, sensor))
          mkpath(joinpath(outpath, node, sensor))
      end
  end
end



@everywhere begin
    function get_paths(p, sensors_to_use)
        df_paths = []

        if isdir(p)
            for f ∈ readdir(p)
                if any(occursin.(sensors_to_use, f))
                    idx = findfirst(occursin.(sensors_to_use, f))
                    push!(df_paths, (joinpath(p, f), sensors_to_use[idx]))
                end
            end
        end

        return df_paths
    end


    function process_paths(ptuples, outpath)
        for ptuple ∈ ptuples
            path, sensor = ptuple

            splitpath = split(convert(String, path), "/")
            node = splitpath[7]
            fname = splitpath[end]


            try
                # download the file to our desired output directory
                # csv = Dagger.@spawn CSV.File(path)
                # Dagger.@spawn CSV.write(joinpath(outpath, node, sensor, fname), csv)
                df = CSV.File(path, silencewarnings=true) |> DataFrame
                dropmissing!(df)

                # add a column with dateTime in UTC zone
                #df.dateTime = date2datetime.(df.dateTime)
                add_datetime_to_df!(df)
                df.date = Date.(df.dateTime)
                df.date_and_hour = Dates.format.(df.dateTime, dateformat"yyyy-mm-ddTHH")


                CSV.write(joinpath(outpath, node, sensor, fname), df)
            catch e
                println(fname, " failed!")
                println(e)
            end
        end
    end
end

flist = [(node, year, month, day) for node ∈ nodes_to_use for year ∈ years_to_use for month ∈ months for day ∈ days]

@showprogress pmap(flist) do (node, year, month, day)
    p = S3Path(joinpath(bucket, "AirQualityNetwork/data/raw", node, year, month, day*"/"))

    # ptuples = Dagger.@spawn get_paths(p, sensors_to_use)
    # Dagger.@spawn process_paths(ptuples, outpath)
    ptuples = get_paths(p, sensors_to_use)
    process_paths(ptuples, outpath)
end

