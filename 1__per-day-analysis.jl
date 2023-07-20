using Distributed, ClusterManagers
using DTables
using CSV, DataFrames

using Statistics, OnlineStats


include("utils/osn_anonymous.jl")
include("utils/df_utils.jl")

if "SLURM_JOBID" ∈ keys(ENV)
    @info "Working on a slurm cluster"
    addprocs_slurm(parse(Int, ENV["SLURM_NTASKS"])-1, exeflags="--project=$(Base.active_project())")
else
    @info "Working locally"
    addprocs(Threads.nthreads(), exeflags="--project=$(Base.active_project())")
end


basepath = "data/sharedair/raw"
@assert ispath(basepath)

# filepath is: basepath/node/sensor/*.csv

nodes_to_use = ["Central_Hub_1", "Central_Hub_2", "Central_Hub_4"]
sensors_to_use = ["IPS7100", "BME680"]


# construct a DTable for each hub for each sensor over all observations.
file_lists = Dict()
for node ∈ nodes_to_use
    file_lists[node] = Dict()
    for sensor ∈ sensors_to_use
        file_lists[node][sensor] = [f for f ∈ joinpath.(basepath, readdir(joinpath(basepath, node, sensor))) if endswith(f, ".csv")]
    end
end


DTable_dict = Dict()
for node ∈ nodes_to_use
    DTable_dict[node] = Dict()
    for sensor ∈ sensors_to_use
        DTable_dict[node][sensor] = DTable(x->CSV.File(x), file_lists[node][sensor])
    end
end


DTable_dict["Central_Hub_1"]["IPS7100"]


# create column for year-month-day-hour and then group by it
# for each hour, compute variogram(s), pdf, etc... and save output to new table.


N = 1000
df = DataFrame(a=rand(1:4, N), b=rand('a':'d', N))

dt = DTable(df, 100)  # partition into 100 row chunks

println("N chunks: ", size(dt.chunks))

collect(dt.chunks[1])
fetch(dt)
tabletype(dt)


# some simple operations
fetch(map(row->(;c=repr(row.a)*row.b), dt))
fetch(reduce(*, dt))
fetch(reduce(+, map(row->(;a=row.a), dt)))
fetch(filter(row->row.b == 'd', dt))  # keep only rows where colum b has value d

# GroupBy syntax
gdt = groupby(dt, :b)
gdt['c']
fetch(gdt['c'])

# loop over keys in grouped dataframe
for (key, t) ∈ gdt
    @show key first(fetch(t))
end


# CSVs
@everywhere using CSV  # need to load packages everywhere

df |> CSV.write("test.csv")
df2 = CSV.File("test.csv") |> DataFrame

# load directly to DTable
dt2 = CSV.File("test.csv") |> DTable

# verify they're the same
DataFrame(dt2) == df2

# writing directly from the DTable
dt2 |> CSV.write("test2.csv")
DataFrame(CSV.File("test2.csv")) == DataFrame(dt2)

# loading multiple CSVs
df |> CSV.write("test3.csv")
dt3 = DTable(x->CSV.File(x), ["test.csv", "test2.csv", "test3.csv"])
DataFrame(dt3) == vcat(df2, df2, df2)

tabletype!(dt3)




test_path = joinpath(basepath, nodes_to_use[1], sensors_to_use[1])
test_path = joinpath(test_path, readdir(test_path)[1])

df = CSV.File(test_path) |> DataFrame
names(df)
df.dt = date2datetime.(df.dateTime)
df.date = Date.(df.dt)


df.date_and_hour = Dates.format.(df.dt, dateformat"yyyy-mm-yyTHH")

DateTime(year(df.dt[1]), month(df.dt[1]), day(df.dt[1]), hour(df.dt[1]))
