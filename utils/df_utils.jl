# data sheets for inst uncertainty:
# ips7100: https://pierasystems.com/wp-content/uploads/2023/09/IPS-Datasheet-V1.3.7.pdf
# bme280: https://www.mouser.com/datasheet/2/783/BST-BME280-DS002-1509607.pdf
# bme680: https://www.mouser.com/datasheet/2/783/BST_BME680_DS001-1509608.pdf

using DataInterpolations

ips_types = Dict(
    "dateTime"      => String,
    "pc0_1"         => Int,
    "pc0_3"         => Int,
    "pc0_5"         => Int,
    "pc1_0"         => Int,
    "pc2_5"         => Int,
    "pc5_0"         => Int,
    "pc10_0"        => Int,
    "pm0_1"         => Float64,
    "pm0_3"         => Float64,
    "pm0_5"         => Float64,
    "pm1_0"         => Float64,
    "pm2_5"         => Float64,
    "pm5_0"         => Float64,
    "pm10_0"        => Float64,
)

bme280_types = Dict(
    "dateTime"      => String,
    "temperature"   => Float64,
    "pressure"      => Float64,
    "humidity"      => Float64,
    "altitude"      => Float64,
)

bme680_types = Dict(
    "dateTime"      => String,
    "temperature"   => Float64,
    "pressure"      => Float64,
    "humidity"      => Float64,
    "gas"      => Float64,
)




function parse_datetime(dt::String)
    # split into Date and Time
    ymd, hms = split(dt, " ")

    # split Date into year,month, day
    y,m,d = parse.(Int, split(ymd, "-"))

    # split Time into hour, minute, second
    h,min,s = split(hms, ":")
    h = parse(Int, h)
    min = parse(Int, min)

    # get seconds and milliseconds
    s = parse(Float64, s)
    s = round(s, digits=3)

    # handle edge case
    if s == 60.000
        s = 59.999
    end

    s,milli = parse.(Int, split("$(s)", "."))

    return DateTime(y,m,d,h,min,s,milli)
end

function parse_datetime!(df::DataFrame)
    df.dateTime = parse_datetime.(df.dateTime)
end





function process_ips7100(df)
    Δt = 1.0 # 1 Hz sample frequency

    t_start = round(df.dateTime[1], Second(1), RoundUp)
    ts = [t.value ./ 1000 for t ∈ df.dateTime .- t_start]
    t_end = round(ts[end], RoundDown)

    df_out = DataFrame()
    df_out.datetime = t_start .+ Second.(0.0:Δt:t_end)


    for j ∈ 2:ncol(df_ips)
        colname = names(df_ips)[j]
        Z = Float64.(df_ips[!,j])
        #itp = CubicSpline(Z, ts)
        itp = LinearInterpolation(Z, ts)

        Zout = itp(0.0:Δt:t_end)

        if occursin("pc", colname)
            Zout = round.(Int, Zout)
        end


        df_out[!, colname] = Zout
    end

    df_out.datetime_quarterhour = round.(df_out.datetime, Minute(15))

    return df_out
end
